import 'dart:async';
import 'dart:convert';

import 'package:scacchi/multiplayer/nostr_event.dart';
import 'package:scacchi/multiplayer/nostr_transport.dart';

/// Relay Nostr in memoria con il minimo di NIP-01: eventi sostituibili per
/// (autore, tipo, tag d), sottoscrizioni con filtri, OK ed EOSE.
class FakeRelay {
  final stored = <String, NostrEvent>{};
  final _sockets = <_FakeSocket>[];

  /// Se falso il relay non risponde alle connessioni.
  bool up = true;

  /// Se falso rifiuta ogni evento con `OK false`.
  bool accepting = true;

  /// Se falso accetta gli eventi ma non risponde con `OK`.
  bool acknowledging = true;

  /// Se vero risponde `CLOSED` a ogni sottoscrizione, come un relay riservato.
  bool refusingSubscriptions = false;

  /// Se vero ogni invio su un collegamento già aperto lancia, come un
  /// WebSocket chiuso un attimo dopo l'apertura.
  bool breakingSends = false;

  int connections = 0;
  final received = <NostrEvent>[];

  Future<RelaySocket> connect(Uri url) async {
    if (!up) throw StateError('relay spento');
    connections++;
    final socket = _FakeSocket(this);
    _sockets.add(socket);
    return socket;
  }

  /// Chiude tutti i collegamenti, come un relay che si riavvia.
  Future<void> drop() async {
    for (final s in List.of(_sockets)) {
      await s.close();
    }
  }

  void _store(NostrEvent e) {
    final d = e.tag('d');
    final key = '${e.pubkey}:${e.kind}:$d';
    final old = stored[key];
    if (old != null &&
        (old.createdAt > e.createdAt ||
            (old.createdAt == e.createdAt && old.id.compareTo(e.id) < 0))) {
      return;
    }
    stored[key] = e;
  }
}

class _FakeSocket implements RelaySocket {
  _FakeSocket(this._relay);

  final FakeRelay _relay;
  final _out = StreamController<String>();
  final _subs = <String, Map<String, Object?>>{};
  bool _closed = false;

  @override
  Stream<String> get messages => _out.stream;

  void _reply(Object? value) {
    if (!_closed) _out.add(jsonEncode(value));
  }

  bool _matches(Map<String, Object?> filter, NostrEvent e) {
    final kinds = filter['kinds'] as List?;
    final authors = filter['authors'] as List?;
    final ds = filter['#d'] as List?;
    return (kinds == null || kinds.contains(e.kind)) &&
        (authors == null || authors.contains(e.pubkey)) &&
        (ds == null || ds.contains(e.tag('d')));
  }

  @override
  void send(String text) {
    if (_relay.breakingSends) throw StateError('collegamento chiuso');
    final msg = jsonDecode(text) as List;
    switch (msg[0]) {
      case 'EVENT':
        final e = NostrEvent.fromJson(msg[1]);
        if (e == null || !e.isValid) {
          _reply(['OK', (msg[1] as Map)['id'], false, 'invalid: firma']);
          return;
        }
        _relay.received.add(e);
        if (!_relay.accepting) {
          if (_relay.acknowledging) _reply(['OK', e.id, false, 'blocked: no']);
          return;
        }
        final known = _relay.stored.values.any((s) => s.id == e.id);
        _relay._store(e);
        if (_relay.acknowledging) {
          _reply(['OK', e.id, true, known ? 'duplicate: già noto' : '']);
        }
        if (!known) {
          for (final s in List.of(_relay._sockets)) {
            for (final entry in s._subs.entries) {
              if (s._matches(entry.value, e)) {
                s._reply(['EVENT', entry.key, e.toJson()]);
              }
            }
          }
        }
      case 'REQ':
        final id = msg[1] as String;
        if (_relay.refusingSubscriptions) {
          _reply(['CLOSED', id, 'auth-required: accesso riservato']);
          return;
        }
        final filter = Map<String, Object?>.from(msg[2] as Map);
        _subs[id] = filter;
        for (final e in _relay.stored.values) {
          if (_matches(filter, e)) _reply(['EVENT', id, e.toJson()]);
        }
        _reply(['EOSE', id]);
      case 'CLOSE':
        _subs.remove(msg[1]);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _relay._sockets.remove(this);
    // Senza ascoltatori la chiusura di un controller non termina mai.
    unawaited(_out.close());
  }
}
