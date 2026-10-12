import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import 'game_invite.dart';
import 'game_sync.dart';
import 'lan_transport.dart';
import 'local_address.dart';
import 'multiplayer_session.dart';
import 'player_identity.dart';
import 'saved_game.dart';
import 'transport.dart';

/// Canale aperto da chi ospita, con l'indirizzo da mettere nell'invito.
typedef HostChannel = ({MessageTransport transport, String? lanAddress});

/// Apre il canale di chi ospita.
typedef OpenHost = Future<HostChannel> Function();

/// Apre il canale di chi riprende la partita, preferendo la porta di prima
/// così l'invitato lo ritrova all'indirizzo che ha già.
typedef ResumeHost = Future<HostChannel> Function(int? port);

/// Apre il canale dell'invitato verso l'ospite.
typedef OpenGuest = MessageTransport Function(String host, int port);

/// Il telefono non è in una rete locale, o l'invito non ne indica una.
class NoLocalNetwork implements Exception {
  const NoLocalNetwork();
}

/// Canale Wi-Fi di chi ospita, in ascolto su tutte le interfacce.
Future<HostChannel> openLanHost() => openLanHostAt(null);

/// Come [openLanHost], sulla porta [port] se è libera.
Future<HostChannel> openLanHostAt(int? port) async {
  final address = await localLanAddress();
  if (address == null) throw const NoLocalNetwork();
  LanTransport lan;
  try {
    lan = await LanTransport.host(port: port ?? 0);
  } on SocketException {
    if (port == null) rethrow;
    lan = await LanTransport.host();
  }
  return (transport: lan, lanAddress: '$address:${lan.port}');
}

MessageTransport openLanGuest(String host, int port) =>
    LanTransport.connect(host, port);

enum MultiplayerStatus { waitingPeer, connecting, myTurn, peerTurn, finished }

/// Stato della partita a due per l'interfaccia: chi muove, l'ultima mossa,
/// l'esito. Avvisa a ogni cambiamento.
class MultiplayerController extends ChangeNotifier {
  MultiplayerController._(this.session, this.inviteLink, this._store) {
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
    SavedGameStore? store,
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
      return MultiplayerController._(session, invite.toLink(), store);
    } catch (_) {
      await channel.transport.close();
      rethrow;
    }
  }

  /// Riprende la partita [saved] dopo un riavvio. Chi ospita riapre il
  /// canale (sulla porta di prima, se libera), l'invitato si ricollega
  /// all'indirizzo dell'invito; i registri si riallineano da soli.
  static Future<MultiplayerController> resume(
    SavedGame saved, {
    ResumeHost openHost = openLanHostAt,
    OpenGuest openGuest = openLanGuest,
    SavedGameStore? store,
  }) async {
    final invite = saved.invite;
    final identity = await PlayerIdentity.fromSeed(saved.seed);
    if (!saved.isHost) {
      return _joinAs(
        invite,
        identity,
        openGuest,
        store,
        moves: saved.moves,
        sealed: saved.sealed,
      );
    }
    final lan = invite.lanAddress;
    final port = lan == null ? null : _split(lan)?.$2;
    final channel = await openHost(port);
    try {
      final session = MultiplayerSession.host(
        invite,
        identity,
        MultiTransport([channel.transport]),
        moves: saved.moves,
        peerKey: saved.peerKey,
        sealed: saved.sealed,
      );
      return MultiplayerController._(session, saved.inviteLink, store);
    } catch (_) {
      await channel.transport.close();
      rethrow;
    }
  }

  static (String, int)? _split(String lan) {
    final colon = lan.lastIndexOf(':');
    final port = colon < 0 ? null : int.tryParse(lan.substring(colon + 1));
    return port == null ? null : (lan.substring(0, colon), port);
  }

  /// Entra nella partita di [invite] e si presenta all'ospite; se non
  /// risponde, il canale riprova da solo e avvisa quando si collega.
  static Future<MultiplayerController> join(
    GameInvite invite, {
    OpenGuest openGuest = openLanGuest,
    SavedGameStore? store,
  }) async =>
      _joinAs(invite, await PlayerIdentity.generate(), openGuest, store);

  static Future<MultiplayerController> _joinAs(
    GameInvite invite,
    PlayerIdentity identity,
    OpenGuest openGuest,
    SavedGameStore? store, {
    List<String> moves = const [],
    Map<int, Uint8List> sealed = const {},
  }) async {
    final lan = invite.lanAddress;
    final target = lan == null ? null : _split(lan);
    if (target == null) throw const NoLocalNetwork();
    final transport = MultiTransport([openGuest(target.$1, target.$2)]);
    try {
      final session = MultiplayerSession.join(
        invite,
        identity,
        transport,
        moves: moves,
        sealed: sealed,
      );
      final controller = MultiplayerController._(
        session,
        invite.toLink(),
        store,
      );
      if (await session.announce()) controller._reached = true;
      unawaited(controller._persist());
      return controller;
    } catch (_) {
      await transport.close();
      rethrow;
    }
  }

  final MultiplayerSession session;
  final SavedGameStore? _store;
  late final Future<Uint8List> _seed = session.identity.seed();

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
    if (_disposed) return;
    notifyListeners();
    unawaited(_persist());
  }

  /// Salva la partita a ogni cambiamento; a partita finita la toglie. Chi
  /// ospita non salva finché nessuno è entrato: l'invito non è ancora usato.
  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    if (_sync.isGameOver) return store.clear();
    if (isHost && _sync.peerKey == null && _sync.moves.isEmpty) return;
    await store.save(
      SavedGame(
        inviteLink: inviteLink,
        isHost: isHost,
        seed: await _seed,
        moves: _sync.moves,
        peerKey: isHost ? _sync.peerKey : null,
        sealed: session.sealedMessages,
      ),
    );
  }

  /// Lascia la partita per sempre: non sarà più possibile riprenderla.
  Future<void> abandon() async {
    await close();
    await _store?.clear();
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
