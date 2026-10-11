import 'dart:async';
import 'dart:typed_data';

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
    _sub = transport.incoming.listen(_onData);
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

  final _events = StreamController<SyncResult>.broadcast();

  /// Esiti dei messaggi ricevuti, per aggiornare l'interfaccia.
  Stream<SyncResult> get events => _events.stream;

  /// L'ultima mossa non è partita su nessun canale.
  bool get pendingDelivery => _pending;
  bool _pending = false;

  /// L'invitato si presenta all'ospite.
  Future<void> announce() => _send(const JoinMessage());

  /// Gioca [uci]; se nessun canale è disponibile la mossa resta in attesa
  /// e parte con [resendLast].
  Future<void> play(String uci) async {
    final message = sync.playLocal(uci);
    _pending = !await _send(message);
  }

  /// Ripete l'ultima mossa: da chiamare quando un canale torna disponibile.
  Future<void> resendLast() async {
    final last = sync.myLastMove;
    if (last == null) return;
    _pending = !await _send(last);
  }

  Future<bool> _send(GameMessage message) async {
    try {
      await transport.send(await _codec.seal(message, identity));
      return true;
    } on TransportUnavailable {
      return false;
    }
  }

  Future<void> _onData(Uint8List data) async {
    final opened = await _codec.open(data);
    if (opened == null || _events.isClosed) return;
    final result = sync.receive(opened.message, opened.author);
    switch (result) {
      case Gap(:final fromSeq):
        await _send(SyncRequest(fromSeq: fromSeq));
      case ResendRequested(:final fromSeq):
        for (final m in sync.movesFrom(fromSeq)) {
          await _send(m);
        }
      case Duplicate() when _peerMissesOurMove(opened.message):
        // L'avversario ripete la sua ultima mossa: non ha visto la nostra.
        await resendLast();
      case PeerJoined() when sync.myLastMove != null:
        await resendLast();
      default:
        break;
    }
    if (!_events.isClosed) _events.add(result);
  }

  bool _peerMissesOurMove(GameMessage m) =>
      m is MoveMessage && (sync.myLastMove?.seq ?? 0) > m.seq;

  Future<void> close() async {
    await _sub.cancel();
    await _events.close();
    await transport.close();
  }
}
