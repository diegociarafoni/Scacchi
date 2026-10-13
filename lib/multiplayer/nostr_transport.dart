import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import 'game_invite.dart';
import 'message_codec.dart' show maxSealedLength;
import 'nostr_event.dart';
import 'transport.dart';

/// Relay pubblici usati per la partita a distanza. Basta che uno risponda;
/// vedono solo byte cifrati e una chiave casuale per partita.
final defaultRelays = <Uri>[
  Uri.parse('wss://relay.damus.io'), // l10n-ok
  Uri.parse('wss://nos.lol'),
  Uri.parse('wss://relay.primal.net'),
  Uri.parse('wss://offchain.pub'),
];

/// Collegamento a un relay: testi JSON in entrambe le direzioni.
abstract interface class RelaySocket {
  Stream<String> get messages;
  void send(String text);
  Future<void> close();
}

typedef RelayConnector = Future<RelaySocket> Function(Uri url);

/// WebSocket di sistema; la chiusura da parte del relay termina il flusso.
Future<RelaySocket> connectWebSocket(Uri url) async {
  final pending = WebSocket.connect(url.toString());
  // ignore: close_sinks
  final WebSocket socket;
  try {
    socket = await pending.timeout(const Duration(seconds: 10));
  } on TimeoutException {
    // Il collegamento che arriva dopo il tempo non deve restare aperto.
    unawaited(pending.then((late) => late.close(), onError: (Object _) {}));
    rethrow;
  }
  socket.pingInterval = const Duration(seconds: 25);
  return _IoRelaySocket(socket);
}

class _IoRelaySocket implements RelaySocket {
  _IoRelaySocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<String> get messages =>
      _socket.where((m) => m is String).cast<String>();

  @override
  void send(String text) => _socket.add(text);

  @override
  Future<void> close() => _socket.close();
}

/// Oltre questa lunghezza un messaggio del relay non si analizza.
const _maxRelayMessage = 8192;

class _Relay {
  _Relay(this.url, this.backoff);

  final Uri url;
  Duration backoff;
  RelaySocket? socket;
  // ignore: cancel_subscriptions
  StreamSubscription<String>? sub;
  Timer? retry;
}

class _Pending {
  _Pending(this.waiting);

  int waiting;
  final done = Completer<bool>();
}

/// Canale a distanza su relay Nostr. Ogni lato scrive in pochi eventi
/// sostituibili (uno per slot, a rotazione), quindi il relay conserva solo
/// gli ultimi messaggi, mai lo storico: chi arriva dopo li trova alla
/// sottoscrizione. Il contenuto è il messaggio sigillato in base64.
///
/// Si collega a tutti i relay insieme e ne basta uno; un relay caduto si
/// ricontatta da solo con attese crescenti, e al ritorno si ripubblicano gli
/// eventi in corso, perché un relay può aver perso tutto. L'autenticità non
/// dipende dal relay: le mosse sono firmate e cifrate dai giocatori.
class NostrTransport implements MessageTransport, ConnectionAware {
  NostrTransport._(
    this._keys,
    Side side,
    this._connector,
    this._ackTimeout,
    this._minBackoff,
    this._maxBackoff,
    this._now,
    Iterable<Uri> relays,
  ) : _peerSlots = _keys.slots(side.opposite).toSet(),
      _mySlots = _keys.slots(side) {
    for (final url in relays) {
      _relays.add(_Relay(url, _minBackoff));
    }
    // Un giro del ciclo degli eventi prima di collegarsi: chi riceve il canale
    // fa in tempo a mettersi in ascolto di `connected`.
    unawaited(
      Future<void>(() {}).then((_) {
        for (final relay in _relays) {
          unawaited(_connect(relay));
        }
      }),
    );
  }

  /// Apre il canale per la partita [gameId]. I relay devono essere `wss`:
  /// un canale in chiaro esporrebbe il traffico a chi sta in mezzo.
  static Future<NostrTransport> open({
    required String gameId,
    required List<int> secret,
    required Side side,
    Iterable<Uri>? relays,
    RelayConnector connector = connectWebSocket,
    Duration ackTimeout = const Duration(seconds: 8),
    Duration minBackoff = const Duration(seconds: 2),
    Duration maxBackoff = const Duration(seconds: 60),
    DateTime Function() now = DateTime.now,
  }) async {
    final list = (relays ?? defaultRelays).toList();
    if (list.isEmpty || list.any((u) => u.scheme != 'wss' || u.host.isEmpty)) {
      throw ArgumentError.value(relays, 'relays', 'servono relay wss');
    }
    return NostrTransport._(
      await RelayKeys.derive(gameId, secret),
      side,
      connector,
      ackTimeout,
      minBackoff,
      maxBackoff,
      now,
      list,
    );
  }

  final RelayKeys _keys;
  final RelayConnector _connector;
  final Duration _ackTimeout;
  final Duration _minBackoff;
  final Duration _maxBackoff;
  final DateTime Function() _now;
  final Set<String> _peerSlots;
  final List<String> _mySlots;

  final _relays = <_Relay>[];
  final _ring = List<NostrEvent?>.filled(relaySlots, null);
  int _next = 0;
  int _lastAt = 0;
  final _pending = <String, _Pending>{};
  final _seen = <String>{};
  final _incoming = StreamController<Uint8List>.broadcast();
  final _connected = StreamController<void>.broadcast();
  bool _closed = false;

  @override
  String get name => 'internet';

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  Stream<void> get connected => _connected.stream;

  /// Relay con un collegamento aperto in questo momento.
  int get connectedRelays => _relays.where((r) => r.socket != null).length;

  Future<void> _connect(_Relay relay) async {
    if (_closed) return;
    final RelaySocket socket;
    try {
      socket = await _connector(relay.url);
    } on Object {
      _scheduleRetry(relay);
      return;
    }
    if (_closed) {
      unawaited(socket.close());
      return;
    }
    final wasDown = connectedRelays == 0;
    relay.socket = socket;
    relay.backoff = _minBackoff;
    relay.sub = socket.messages.listen(
      (text) => _onMessage(relay, text),
      onDone: () => _lost(relay),
      onError: (Object _) => _lost(relay),
      cancelOnError: true,
    );
    try {
      socket.send(
        jsonEncode([
          'REQ',
          _subId,
          {
            'kinds': [nostrGameKind],
            'authors': [_keys.publicKey],
            '#d': _peerSlots.toList(),
          },
        ]),
      );
      // Un relay può aver perso gli eventi o l'invio può essere partito mentre
      // era giù: si ripubblica quel che c'è.
      for (final e in _ring.whereType<NostrEvent>()) {
        socket.send(jsonEncode(['EVENT', e.toJson()]));
      }
    } on Object {
      // Chiuso subito dopo l'apertura: si riprova come per ogni caduta.
      _lost(relay);
      return;
    }
    if (wasDown && !_connected.isClosed) _connected.add(null);
  }

  static const _subId = 'rokko';

  void _lost(_Relay relay) {
    final socket = relay.socket;
    if (socket == null) return;
    relay.socket = null;
    unawaited(relay.sub?.cancel());
    relay.sub = null;
    unawaited(socket.close().catchError((Object _) {}));
    _scheduleRetry(relay);
  }

  void _scheduleRetry(_Relay relay) {
    if (_closed || relay.retry != null) return;
    final wait = relay.backoff;
    final doubled = wait * 2;
    relay.backoff = doubled > _maxBackoff ? _maxBackoff : doubled;
    relay.retry = Timer(wait, () {
      relay.retry = null;
      unawaited(_connect(relay));
    });
  }

  void _onMessage(_Relay relay, String text) {
    if (text.length > _maxRelayMessage) return;
    final Object? msg;
    try {
      msg = jsonDecode(text);
    } on FormatException {
      return;
    }
    if (msg is! List || msg.isEmpty) return;
    switch (msg[0]) {
      // Il relay rifiuta la sottoscrizione (accesso riservato, limiti): da
      // qui non arriverebbe nulla, anche se accetta le pubblicazioni.
      case 'CLOSED' when msg.length >= 2 && msg[1] == _subId:
        _lost(relay);
      case 'EVENT' when msg.length >= 3 && msg[1] == _subId:
        _onEvent(NostrEvent.fromJson(msg[2]));
      case 'OK' when msg.length >= 3 && msg[1] is String:
        final pending = _pending[msg[1]];
        if (pending == null) break;
        final reason = msg.length > 3 ? '${msg[3]}' : '';
        // Un doppione vuol dire che il relay ha già l'evento.
        if (msg[2] == true || reason.startsWith('duplicate:')) {
          if (!pending.done.isCompleted) pending.done.complete(true);
        } else if (--pending.waiting <= 0 && !pending.done.isCompleted) {
          pending.done.complete(false);
        }
    }
  }

  void _onEvent(NostrEvent? e) {
    if (e == null || _closed || _incoming.isClosed) return;
    if (e.kind != nostrGameKind || e.pubkey != _keys.publicKey) return;
    if (!_peerSlots.contains(e.tag('d'))) return;
    if (_seen.contains(e.id) || !e.isValid) return;
    final Uint8List data;
    try {
      data = base64.decode(e.content);
    } on FormatException {
      return;
    }
    if (data.isEmpty || data.length > maxSealedLength) return;
    _seen.add(e.id);
    if (_seen.length > 512) _seen.remove(_seen.first);
    _incoming.add(data);
  }

  NostrEvent _eventFor(Uint8List data) {
    final content = base64.encode(data);
    for (final e in _ring) {
      if (e != null && e.content == content) return e;
    }
    // L'ordine dei sostituibili lo decide created_at: sempre crescente.
    final seconds = _now().millisecondsSinceEpoch ~/ 1000;
    _lastAt = seconds > _lastAt ? seconds : _lastAt + 1;
    final event = _keys.sign(
      slot: _mySlots[_next],
      content: content,
      createdAt: _lastAt,
    );
    _ring[_next] = event;
    _next = (_next + 1) % relaySlots;
    return event;
  }

  @override
  Future<void> send(Uint8List data) async {
    if (_closed || data.isEmpty || data.length > maxSealedLength) {
      throw TransportUnavailable(name);
    }
    // L'evento resta in memoria anche se ora nessun relay risponde: parte
    // appena uno si collega.
    final event = _eventFor(data);
    final up = _relays.where((r) => r.socket != null).toList();
    if (up.isEmpty) throw TransportUnavailable(name);
    final pending = _pending.putIfAbsent(event.id, () => _Pending(up.length));
    final frame = jsonEncode(['EVENT', event.toJson()]);
    for (final r in up) {
      try {
        r.socket!.send(frame);
      } on Object {
        _lost(r);
        pending.waiting--;
      }
    }
    if (pending.waiting <= 0 && !pending.done.isCompleted) {
      pending.done.complete(false);
    }
    final ok = await pending.done.future.timeout(
      _ackTimeout,
      onTimeout: () => false,
    );
    if (identical(_pending[event.id], pending)) _pending.remove(event.id);
    if (!ok) throw TransportUnavailable(name);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final r in _relays) {
      r.retry?.cancel();
      await r.sub?.cancel();
      try {
        await r.socket?.close();
      } on Object catch (e) {
        if (kDebugMode) {
          debugPrint('Chiusura del relay ${r.url}: $e'); // l10n-ok
        }
      }
      r.socket = null;
    }
    for (final p in _pending.values) {
      if (!p.done.isCompleted) p.done.complete(false);
    }
    await _incoming.close();
    await _connected.close();
  }
}

/// Canale a distanza per il registro dei canali: solo se l'invito lo prevede
/// (`r=1`), così una partita in rete locale non contatta alcun relay.
Future<MessageTransport?> openNostrChannel(
  GameInvite invite, {
  required bool isHost,
}) async => invite.remote
    ? NostrTransport.open(
        gameId: invite.gameId,
        secret: invite.secret,
        side: isHost ? invite.hostSide : invite.hostSide.opposite,
      )
    : null;
