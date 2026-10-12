import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import 'channel_registry.dart';
import 'game_invite.dart';
import 'game_sync.dart';
import 'lan_transport.dart';
import 'local_address.dart';
import 'multiplayer_session.dart';
import 'player_identity.dart';
import 'remote_watch.dart';
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
  MultiplayerController._(
    this.session,
    this.inviteLink,
    this._store,
    this._seedBytes,
  ) {
    _sub = session.events.listen((_) => _changed());
    // Il canale si è (ri)collegato all'ospite: la sessione si ripresenta da
    // sola, qui basta aggiornare lo stato.
    _connSub = session.transport.connected.listen((_) {
      _reached = true;
      _changed();
    });
    addExtraChannels(session.transport, session.invite, isHost: isHost);
  }

  /// Crea l'invito e attende l'avversario. Con [remote] la partita si gioca
  /// anche a distanza, e basta internet: senza Wi-Fi né hotspot l'invito
  /// viaggia come link. Altrimenti [NoLocalNetwork] se il telefono non è in
  /// una rete locale.
  static Future<MultiplayerController> host({
    required Side side,
    OpenHost openHost = openLanHost,
    bool remote = false,
    SavedGameStore? store,
  }) async {
    HostChannel? lan;
    try {
      lan = await openHost();
    } on Object {
      // A distanza la rete locale è facoltativa: porta occupata, VPN o
      // permesso negato non impediscono di giocare via internet.
      if (!remote) rethrow;
    }
    if (!remote && lan?.lanAddress == null) {
      await lan?.transport.close();
      throw const NoLocalNetwork();
    }
    final opened = <MessageTransport>[?lan?.transport];
    try {
      final identity = await PlayerIdentity.generate();
      final invite = GameInvite(
        gameId: newGameId(),
        secret: newSecret(),
        hostKey: identity.publicKey,
        hostSide: side,
        lanAddress: lan?.lanAddress,
        remote: remote,
      );
      final session = MultiplayerSession.host(
        invite,
        identity,
        MultiTransport(opened),
      );
      final controller = MultiplayerController._(
        session,
        invite.toLink(),
        store,
        await identity.seed(),
      );
      // A distanza l'amico può arrivare ore dopo: l'invito si salva subito.
      if (remote) unawaited(controller._persist());
      return controller;
    } catch (_) {
      for (final t in opened) {
        await t.close();
      }
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
    final lanInvite = invite.lanAddress;
    final port = lanInvite == null ? null : _split(lanInvite)?.$2;
    if (!listEquals(identity.publicKey, invite.hostKey)) {
      throw const FormatException('chiave non coerente con l\'invito');
    }
    HostChannel? lan;
    // Un invito solo a distanza non ha un indirizzo da riaprire; uno misto
    // riparte anche senza Wi-Fi.
    if (lanInvite != null || !invite.remote) {
      try {
        lan = await openHost(port);
      } on Object {
        if (!invite.remote) rethrow;
      }
    }
    final opened = <MessageTransport>[?lan?.transport];
    try {
      // Se la porta di prima era occupata l'indirizzo è cambiato.
      final current = GameInvite(
        gameId: invite.gameId,
        secret: invite.secret,
        hostKey: invite.hostKey,
        hostSide: invite.hostSide,
        lanAddress: lan?.lanAddress ?? invite.lanAddress,
        remote: invite.remote,
      );
      final session = MultiplayerSession.host(
        current,
        identity,
        MultiTransport(opened),
        moves: saved.moves,
        peerKey: saved.peerKey,
        sealed: saved.sealed,
      );
      return MultiplayerController._(
        session,
        current.toLink(),
        store,
        saved.seed,
      );
    } catch (_) {
      for (final t in opened) {
        await t.close();
      }
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
    if (target == null && !invite.remote) throw const NoLocalNetwork();
    final opened = <MessageTransport>[
      ?target == null ? null : openGuest(target.$1, target.$2),
    ];
    try {
      final session = MultiplayerSession.join(
        invite,
        identity,
        MultiTransport(opened),
        moves: moves,
        sealed: sealed,
      );
      final controller = MultiplayerController._(
        session,
        invite.toLink(),
        store,
        await identity.seed(),
      );
      if (await session.announce()) controller._reached = true;
      unawaited(controller._persist());
      return controller;
    } catch (_) {
      for (final t in opened) {
        await t.close();
      }
      rethrow;
    }
  }

  final MultiplayerSession session;
  SavedGameStore? _store;
  final Uint8List _seedBytes;
  bool _finished = false;
  Future<void> _writes = Future.value();

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
    _syncWatch();
    unawaited(_persist());
  }

  RemoteWatch? _watch;
  bool _watching = false;

  /// Controllo in background delle partite a distanza: si accende finché la
  /// partita è in corso e si spegne alla fine.
  void useWatch(RemoteWatch? watch) {
    _watch = watch;
    _syncWatch();
  }

  void _syncWatch() {
    final watch = _watch;
    if (watch == null || !session.invite.remote || _disposed) return;
    final wanted = !_sync.isGameOver;
    if (wanted == _watching) return;
    _watching = wanted;
    unawaited(wanted ? watch.enable() : watch.disable());
  }

  /// Archivio arrivato dopo la creazione del controller (se non ne ha già uno).
  void useStore(SavedGameStore? store) {
    if (_store != null || store == null || _disposed) return;
    _store = store;
    unawaited(_persist());
  }

  /// Salva la partita a ogni cambiamento; a partita finita la toglie. Chi
  /// ospita in rete locale non salva finché nessuno è entrato: l'invito non è
  /// ancora usato. A distanza sì, perché l'amico può arrivare molto dopo.
  Future<void> _persist() {
    final store = _store;
    if (store == null || _finished) return Future.value();
    if (isHost &&
        !session.invite.remote &&
        _sync.peerKey == null &&
        _sync.moves.isEmpty) {
      return Future.value();
    }
    final finished = _sync.isGameOver;
    // Istantanea subito, scrittura in ordine: un salvataggio in ritardo non
    // può far riapparire una partita già chiusa.
    final game = SavedGame(
      inviteLink: inviteLink,
      isHost: isHost,
      seed: _seedBytes,
      moves: _sync.moves,
      peerKey: isHost ? _sync.peerKey : null,
      sealed: session.sealedMessages,
    );
    if (finished) _finished = true;
    return _writes = _writes.then((_) async {
      try {
        await (finished ? store.clear() : store.save(game));
      } on Object catch (e) {
        if (kDebugMode) debugPrint('Salvataggio della partita fallito: $e');
      }
    });
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
