import 'dart:async';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';

import 'game_invite.dart';
import 'game_message.dart';
import 'game_sync.dart';
import 'message_codec.dart';
import 'player_identity.dart';
import 'transport.dart';

/// Partita a due su uno o più canali: unisce registro, sigillo e canali.
/// Cambiare canale non cambia la partita, che continua su quello che c'è.
class MultiplayerSession {
  MultiplayerSession._(this.invite, this.identity, this.transport, this.sync)
    : _codec = MessageCodec(gameId: invite.gameId, secret: invite.secret) {
    // Un messaggio alla volta: decifrature concluse fuori ordine
    // produrrebbero buchi fittizi nel registro.
    _sub = transport.incoming.listen(
      (data) => _queue = _queue.then((_) => _onData(data)),
    );
    _connSub = transport.connected.listen(
      (_) => _queue = _queue.then((_) => _onConnected()),
    );
  }

  /// Chi ha creato l'invito; l'avversario si fissa al suo primo ingresso.
  factory MultiplayerSession.host(
    GameInvite invite,
    PlayerIdentity identity,
    MultiTransport transport, {
    Iterable<String> moves = const [],
    Uint8List? peerKey,
  }) => MultiplayerSession._(
    invite,
    identity,
    transport,
    GameSync(
      mySide: invite.hostSide,
      myKey: identity.publicKey,
      peerKey: peerKey,
      moves: moves,
    ),
  );

  /// Chi ha ricevuto l'invito; conosce già la chiave dell'ospite.
  factory MultiplayerSession.join(
    GameInvite invite,
    PlayerIdentity identity,
    MultiTransport transport, {
    Iterable<String> moves = const [],
  }) => MultiplayerSession._(
    invite,
    identity,
    transport,
    GameSync(
      mySide: invite.hostSide.opposite,
      myKey: identity.publicKey,
      peerKey: invite.hostKey,
      moves: moves,
    ),
  );

  final GameInvite invite;
  final PlayerIdentity identity;
  final MultiTransport transport;
  final GameSync sync;
  final MessageCodec _codec;
  late final StreamSubscription<Uint8List> _sub;
  late final StreamSubscription<void> _connSub;
  Future<void> _queue = Future.value();

  // Messaggi sigillati di ogni semimossa, rimandati identici nel recupero:
  // così ognuno arriva con la firma del suo autore.
  final _sealed = <int, Uint8List>{};

  final _events = StreamController<SyncResult>.broadcast();

  /// Esiti dei messaggi ricevuti, per aggiornare l'interfaccia.
  Stream<SyncResult> get events => _events.stream;

  /// L'ultima mossa non è partita su nessun canale.
  bool get pendingDelivery => _pending;
  bool _pending = false;

  /// L'invitato si presenta all'ospite; `false` se nessun canale è
  /// disponibile. Facoltativo: anche la prima mossa lo presenta.
  Future<bool> announce() => _send(const JoinMessage());

  /// Gioca [uci]; se nessun canale è disponibile la mossa resta in attesa
  /// e parte con [resendLast].
  Future<void> play(String uci) async {
    final message = sync.playLocal(uci);
    _pending = !await _sendSealed(await _seal(message));
  }

  /// Ripete l'ultima mossa: da chiamare quando un canale torna disponibile.
  Future<void> resendLast() async {
    final last = sync.myLastMove;
    if (last == null) return;
    _pending = !await _sendSealed(_sealed[last.seq] ?? await _seal(last));
  }

  Future<Uint8List> _seal(MoveMessage move) async =>
      _sealed[move.seq] = await _codec.seal(move, identity);

  Future<bool> _send(GameMessage message) async =>
      _sendSealed(await _codec.seal(message, identity));

  Future<bool> _sendSealed(Uint8List data) async {
    try {
      await transport.send(data);
      return true;
    } on TransportUnavailable {
      return false;
    }
  }

  Future<void> _onData(Uint8List data) async {
    final opened = await _codec.open(data);
    if (opened == null || _events.isClosed) return;
    final result = sync.receive(opened.message, opened.author);
    if (result case MoveAccepted(:final move)) _sealed[move.seq] = data;
    switch (result) {
      case Gap(:final fromSeq):
        await _send(SyncRequest(fromSeq: fromSeq));
      case ResendRequested(:final fromSeq):
        for (final m in sync.movesFrom(fromSeq)) {
          final mine = (m.seq.isOdd ? Side.white : Side.black) == sync.mySide;
          final data = _sealed[m.seq] ?? (mine ? await _seal(m) : null);
          if (data != null) await _sendSealed(data);
        }
      case Duplicate() when _peerMissesOurMove(opened.message):
        // L'avversario ripete la sua ultima mossa: non ha visto la nostra.
        await resendLast();
      case PeerJoined() || Duplicate()
          when opened.message is JoinMessage && sync.myLastMove != null:
        // L'avversario entra o rientra: forse non ha visto la nostra mossa.
        await resendLast();
      default:
        break;
    }
    if (!_events.isClosed) _events.add(result);
  }

  // Collegamento nuovo: l'invitato si ripresenta e ciascuno ripete la sua
  // ultima mossa, che l'altro potrebbe non avere ricevuto.
  Future<void> _onConnected() async {
    if (_events.isClosed) return;
    if (!_isHost) await announce();
    await resendLast();
  }

  bool get _isHost => sync.mySide == invite.hostSide;

  bool _peerMissesOurMove(GameMessage m) =>
      m is MoveMessage && (sync.myLastMove?.seq ?? 0) > m.seq;

  Future<void> close() async {
    await _sub.cancel();
    await _connSub.cancel();
    await _events.close();
    await transport.close();
  }
}
