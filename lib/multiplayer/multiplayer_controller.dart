import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import 'game_invite.dart';
import 'game_sync.dart';
import 'lan_transport.dart';
import 'local_address.dart';
import 'multiplayer_session.dart';
import 'player_identity.dart';
import 'transport.dart';

/// Canale aperto da chi ospita, con l'indirizzo da mettere nell'invito.
typedef HostChannel = ({MessageTransport transport, String? lanAddress});

/// Apre il canale di chi ospita.
typedef OpenHost = Future<HostChannel> Function();

/// Apre il canale dell'invitato verso l'ospite.
typedef OpenGuest = MessageTransport Function(String host, int port);

/// Il telefono non è in una rete locale, o l'invito non ne indica una.
class NoLocalNetwork implements Exception {
  const NoLocalNetwork();
}

/// Canale Wi-Fi di chi ospita, in ascolto su tutte le interfacce.
Future<HostChannel> openLanHost() async {
  final address = await localLanAddress();
  if (address == null) throw const NoLocalNetwork();
  final lan = await LanTransport.host();
  return (transport: lan, lanAddress: '$address:${lan.port}');
}

MessageTransport openLanGuest(String host, int port) =>
    LanTransport.connect(host, port);

enum MultiplayerStatus { waitingPeer, connecting, myTurn, peerTurn, finished }

/// Stato della partita a due per l'interfaccia: chi muove, l'ultima mossa,
/// l'esito. Avvisa a ogni cambiamento.
class MultiplayerController extends ChangeNotifier {
  MultiplayerController._(this.session, this.inviteLink) {
    _sub = session.events.listen((_) => _changed());
    // Il canale si è (ri)collegato all'ospite: la sessione si ripresenta da
    // sola, qui basta aggiornare lo stato.
    _connSub = session.transport.connected.listen((_) {
      _reached = true;
      _changed();
    });
  }

  /// Crea l'invito e attende l'avversario. [NoLocalNetwork] se il telefono
  /// non è in una Wi-Fi o in un hotspot.
  static Future<MultiplayerController> host({
    required Side side,
    OpenHost openHost = openLanHost,
  }) async {
    final channel = await openHost();
    try {
      if (channel.lanAddress == null) throw const NoLocalNetwork();
      final identity = await PlayerIdentity.generate();
      final invite = GameInvite(
        gameId: newGameId(),
        secret: newSecret(),
        hostKey: identity.publicKey,
        hostSide: side,
        lanAddress: channel.lanAddress,
      );
      final session = MultiplayerSession.host(
        invite,
        identity,
        MultiTransport([channel.transport]),
      );
      return MultiplayerController._(session, invite.toLink());
    } catch (_) {
      await channel.transport.close();
      rethrow;
    }
  }

  /// Entra nella partita di [invite] e si presenta all'ospite; se non
  /// risponde, il canale riprova da solo e avvisa quando si collega.
  static Future<MultiplayerController> join(
    GameInvite invite, {
    OpenGuest openGuest = openLanGuest,
  }) async {
    final lan = invite.lanAddress;
    final colon = lan?.lastIndexOf(':') ?? -1;
    final port = colon < 0 ? null : int.tryParse(lan!.substring(colon + 1));
    if (port == null) throw const NoLocalNetwork();
    final transport = MultiTransport([
      openGuest(lan!.substring(0, colon), port),
    ]);
    try {
      final identity = await PlayerIdentity.generate();
      final session = MultiplayerSession.join(invite, identity, transport);
      final controller = MultiplayerController._(session, invite.toLink());
      if (await session.announce()) controller._reached = true;
      return controller;
    } catch (_) {
      await transport.close();
      rethrow;
    }
  }

  final MultiplayerSession session;

  /// Link dell'invito, da mostrare come QR all'altro telefono.
  final String inviteLink;

  late final StreamSubscription<SyncResult> _sub;
  late final StreamSubscription<void> _connSub;
  bool _reached = false;
  bool _disposed = false;

  GameSync get _sync => session.sync;
  Side get mySide => _sync.mySide;
  Position get position => _sync.position;
  bool get isHost => mySide == session.invite.hostSide;

  /// La mossa partita da questo telefono non ha ancora trovato un canale.
  bool get pendingDelivery => session.pendingDelivery;

  Move? get lastMove =>
      _sync.moves.isEmpty ? null : Move.parse(_sync.moves.last);

  /// Ultima mossa in notazione SAN, per annunciarla.
  String? get lastSan => _sync.lastSan;

  Outcome? get outcome => position.outcome;

  MultiplayerStatus get status {
    final peer = isHost ? _sync.peerKey != null : _reached;
    if (!peer && _sync.moves.isEmpty) {
      return isHost
          ? MultiplayerStatus.waitingPeer
          : MultiplayerStatus.connecting;
    }
    if (_sync.isGameOver) return MultiplayerStatus.finished;
    return position.turn == mySide
        ? MultiplayerStatus.myTurn
        : MultiplayerStatus.peerTurn;
  }

  /// Gioca [move]; `false` se non è il proprio turno o la mossa è illegale.
  Future<bool> play(Move move) async {
    if (status != MultiplayerStatus.myTurn || !position.isLegal(move)) {
      return false;
    }
    await session.play(move.uci);
    _changed();
    return true;
  }

  void _changed() {
    if (!_reached && !isHost && _sync.moves.isNotEmpty) {
      _reached = true;
    }
    if (!_disposed) notifyListeners();
  }

  /// Chiude canali e sessione; dopo non avvisa più.
  Future<void> close() async {
    if (_disposed) return;
    _disposed = true;
    await _sub.cancel();
    await _connSub.cancel();
    await session.close();
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}
