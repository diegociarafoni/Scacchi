import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/multiplayer/channel_registry.dart';
import 'package:rokko/multiplayer/game_invite.dart';
import 'package:rokko/multiplayer/multiplayer_controller.dart';
import 'package:rokko/multiplayer/nostr_transport.dart';
import 'package:rokko/multiplayer/remote_turn_check.dart';
import 'package:rokko/multiplayer/saved_game.dart';
import 'package:rokko/multiplayer/transport.dart';

import '../support/wait.dart';
import 'fake_relay.dart';

class _Notifier implements TurnNotifier {
  final turns = <RemoteTurn>[];

  @override
  Future<void> notify(RemoteTurn turn) async => turns.add(turn);
}

class _Log implements NotifiedLog {
  final moves = <String, int>{};

  @override
  Future<int> read(String gameId) async => moves[gameId] ?? 0;

  @override
  Future<void> write(String gameId, int count) async => moves[gameId] = count;
}

void main() {
  late Directory dir;
  late FakeRelay relay;
  late SavedGameStore store;
  final opened = <NostrTransport>[];

  Future<MessageTransport?> open(
    GameInvite invite, {
    required bool isHost,
  }) async {
    final t = await NostrTransport.open(
      gameId: invite.gameId,
      secret: invite.secret,
      side: isHost ? invite.hostSide : invite.hostSide.opposite,
      relays: [Uri.parse('wss://relay.prova')],
      connector: relay.connect,
      minBackoff: const Duration(milliseconds: 20),
      maxBackoff: const Duration(milliseconds: 80),
    );
    opened.add(t);
    return t;
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('rokko_turn');
    relay = FakeRelay();
    store = SavedGameStore(File('${dir.path}/m.json'));
    extraChannelFactories
      ..clear()
      ..add(open);
  });

  tearDown(() async {
    extraChannelFactories.clear();
    for (final t in opened) {
      await t.close();
    }
    opened.clear();
    await removeDir(dir);
  });

  Future<MultiplayerController> startHost() => MultiplayerController.host(
    side: Side.white,
    openHost: () async => throw const NoLocalNetwork(),
    remote: true,
  );

  /// Invitato che ha giocato 1…e5 e poi è uscito; la partita è nel file.
  Future<MultiplayerController> guestAway(MultiplayerController host) async {
    final guest = await MultiplayerController.join(
      GameInvite.parse(host.inviteLink)!,
      store: store,
    );
    await until(
      () => host.status == MultiplayerStatus.myTurn,
      what: 'invitato',
    );
    await host.play(Move.parse('e2e4')!);
    await untilMoves(guest, 1);
    await guest.play(Move.parse('e7e5')!);
    await untilMoves(host, 2);
    await untilSaved(store, 2);
    await guest.close();
    return guest;
  }

  // Con novità il controllo termina subito: l'attesa lunga serve solo sotto carico.
  // Senza novità si aspetta tutta la finestra, quindi lì resta breve.
  Future<bool> check(_Notifier n, _Log log, {bool news = true}) =>
      checkRemoteGame(
        store: store,
        notifier: n,
        log: log,
        openChannel: open,
        wait: news
            ? const Duration(seconds: 30)
            : const Duration(milliseconds: 600),
      );

  test(
    'RMP-40 se l\'amico ha mosso, parte l\'avviso con la sua mossa',
    () async {
      final host = await startHost();
      await guestAway(host);
      await host.play(Move.parse('g1f3')!);
      final n = _Notifier();
      await check(n, _Log());
      expect(n.turns, hasLength(1));
      expect(n.turns.single.moves, 3);
      expect(n.turns.single.san, 'Nf3');
      expect(n.turns.single.over, isFalse);
      await host.close();
    },
  );

  test('RMP-40 se l\'amico non ha mosso, nessun avviso', () async {
    final host = await startHost();
    await guestAway(host);
    final n = _Notifier();
    expect(await check(n, _Log(), news: false), isTrue);
    expect(n.turns, isEmpty);
    await host.close();
  });

  test(
    'RMP-40 lo stesso avviso non si ripete finché l\'amico non muove ancora',
    () async {
      final host = await startHost();
      await guestAway(host);
      await host.play(Move.parse('g1f3')!);
      final n = _Notifier();
      final log = _Log();
      await check(n, log);
      await check(n, log);
      expect(n.turns, hasLength(1));
      expect(log.moves.values.single, 3);
      await host.close();
    },
  );

  test('RMP-40 senza partita salvata o in rete locale non fa nulla', () async {
    final n = _Notifier();
    // Niente da seguire: il controllo periodico si può togliere.
    expect(await check(n, _Log()), isFalse);
    expect(n.turns, isEmpty);

    final (a, b) = LoopbackTransport.pair();
    final host = await MultiplayerController.host(
      side: Side.white,
      openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
      store: store,
    );
    final guest = await MultiplayerController.join(
      GameInvite.parse(host.inviteLink)!,
      openGuest: (_, _) => b,
      store: store,
    );
    await until(
      () => host.status == MultiplayerStatus.myTurn,
      what: 'invitato',
    );
    await host.play(Move.parse('e2e4')!);
    await untilSaved(store, 1);
    expect(await check(n, _Log()), isFalse);
    expect(n.turns, isEmpty);
    await host.close();
    await guest.close();
  });

  test('RMP-40 l\'ultima mossa che chiude la partita lo dice', () async {
    final host = await startHost();
    final guest = await MultiplayerController.join(
      GameInvite.parse(host.inviteLink)!,
      store: store,
    );
    await until(
      () => host.status == MultiplayerStatus.myTurn,
      what: 'invitato',
    );
    var plies = 0;
    // Matto del barbiere: bianco matta alla quarta mossa.
    for (final (c, uci) in [
      (host, 'e2e4'),
      (guest, 'e7e5'),
      (host, 'f1c4'),
      (guest, 'b8c6'),
      (host, 'd1h5'),
      (guest, 'g8f6'),
    ]) {
      expect(await c.play(Move.parse(uci)!), isTrue);
      await untilMoves(host, ++plies);
      await untilMoves(guest, plies);
    }
    await untilSaved(store, 6);
    await guest.close();
    expect(await host.play(Move.parse('h5f7')!), isTrue);
    final n = _Notifier();
    // Partita chiusa dall'amico: dopo l'avviso non c'è più nulla da seguire.
    expect(await check(n, _Log()), isFalse);
    expect(n.turns.single.over, isTrue);
    expect(n.turns.single.san, 'Qxf7#');
    await host.close();
  });

  test(
    'RMP-40 il giorno dopo, un\'altra mossa dell\'amico avvisa di nuovo',
    () async {
      final host = await startHost();
      await guestAway(host);
      await host.play(Move.parse('g1f3')!);
      final n = _Notifier();
      final log = _Log();
      await check(n, log);
      // L'invitato apre l'app, gioca, richiude; l'ospite muove ancora.
      final guest = await MultiplayerController.resume(
        (await store.load())!,
        store: store,
      );
      await untilMoves(guest, 3);
      await guest.play(Move.parse('b8c6')!);
      await untilMoves(host, 4);
      await untilSaved(store, 4);
      await guest.close();
      await host.play(Move.parse('f1b5')!);
      await check(n, log);
      expect(n.turns.map((t) => t.moves), [3, 5]);
      await host.close();
    },
  );
}
