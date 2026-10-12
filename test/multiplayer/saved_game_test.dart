import 'dart:io';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/multiplayer_controller.dart';
import 'package:scacchi/multiplayer/saved_game.dart';
import 'package:scacchi/multiplayer/transport.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

// Attende una condizione invece di un tempo fisso: su un runner carico la
// ripresa da disco può superare i 50 ms.
Future<void> until(bool Function() ok) async {
  for (var i = 0; i < 200 && !ok(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

SavedGame sample() => SavedGame(
  inviteLink: GameInvite(
    gameId: newGameId(),
    secret: newSecret(),
    hostKey: Uint8List(32)..fillRange(0, 32, 7),
    hostSide: Side.white,
    lanAddress: '10.0.0.2:4000',
  ).toLink(),
  isHost: true,
  seed: Uint8List.fromList(List.generate(32, (i) => i)),
  moves: const ['e2e4', 'e7e5'],
  peerKey: Uint8List(32)..fillRange(0, 32, 9),
  sealed: {
    1: Uint8List.fromList([1, 2, 3]),
    2: Uint8List.fromList([4, 5]),
  },
);

void main() {
  late Directory dir;
  late SavedGameStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('rokko_saved_game');
    store = SavedGameStore(File('${dir.path}/multiplayer.json'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('RMP-09 la partita salvata si rilegge uguale', () async {
    final saved = sample();
    await store.save(saved);
    final back = (await store.load())!;
    expect(back.inviteLink, saved.inviteLink);
    expect(back.isHost, isTrue);
    expect(back.seed, saved.seed);
    expect(back.moves, saved.moves);
    expect(back.peerKey, saved.peerKey);
    expect(back.sealed, saved.sealed);
  });

  test('RMP-09 senza salvataggio non c\'è nulla da riprendere', () async {
    expect(await store.load(), isNull);
    await store.save(sample());
    await store.clear();
    expect(await store.load(), isNull);
  });

  test('RMP-09 un salvataggio rovinato viene ignorato', () async {
    File('${dir.path}/multiplayer.json').writeAsStringSync(
      '{"version":1,"inviteLink":"x","isHost":true,"seed":"!!","moves":[]}',
    );
    expect(await store.load(), isNull);
    // Messo da parte, non lasciato lì a ogni avvio.
    expect(File('${dir.path}/multiplayer.json').existsSync(), isFalse);
  });

  test('RMP-09 un seme che non è quello dell\'invito non riprende', () async {
    final bad = sample();
    await expectLater(
      MultiplayerController.resume(
        bad,
        openHost: (_) async => throw StateError('no'),
      ),
      throwsFormatException,
    );
  });

  group('ripresa', () {
    Future<(MultiplayerController, MultiplayerController)> started(
      SavedGameStore hostStore,
      SavedGameStore guestStore,
    ) async {
      final (a, b) = LoopbackTransport.pair();
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
        store: hostStore,
      );
      final guest = await MultiplayerController.join(
        GameInvite.parse(host.inviteLink)!,
        openGuest: (_, _) => b,
        store: guestStore,
      );
      await settle();
      return (host, guest);
    }

    test('RMP-09 chi ospita non salva finché l\'altro non entra', () async {
      final (a, _) = LoopbackTransport.pair();
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
        store: store,
      );
      await settle();
      expect(await store.load(), isNull);
      await host.close();
    });

    test('RMP-09 ogni mossa viene salvata, anche quella ricevuta', () async {
      final guestStore = SavedGameStore(File('${dir.path}/guest.json'));
      final (host, guest) = await started(store, guestStore);
      expect(await host.play(Move.parse('e2e4')!), isTrue);
      await settle();
      await guest.play(Move.parse('e7e5')!);
      await settle();
      final h = (await store.load())!;
      final g = (await guestStore.load())!;
      expect(h.moves, ['e2e4', 'e7e5']);
      expect(g.moves, ['e2e4', 'e7e5']);
      expect(h.isHost, isTrue);
      expect(g.isHost, isFalse);
      expect(h.peerKey, isNotNull);
      expect(h.sealed.keys, containsAll([1, 2]));
      await host.close();
      await guest.close();
    });

    test('RMP-09 dopo un riavvio la partita riprende e continua', () async {
      final guestStore = SavedGameStore(File('${dir.path}/guest.json'));
      final (host, guest) = await started(store, guestStore);
      await host.play(Move.parse('e2e4')!);
      await settle();
      await host.close();
      await guest.close();

      // Entrambi i telefoni si riaprono dal salvataggio.
      final (a, b) = LoopbackTransport.pair();
      final host2 = await MultiplayerController.resume(
        (await store.load())!,
        openHost: (_) async => (transport: a, lanAddress: '10.0.0.2:4000'),
        store: store,
      );
      final guest2 = await MultiplayerController.resume(
        (await guestStore.load())!,
        openGuest: (_, _) => b,
        store: guestStore,
      );
      await until(() => host2.session.sync.moves.isNotEmpty);
      await settle();
      expect(host2.session.sync.moves, ['e2e4']);
      expect(host2.status, MultiplayerStatus.peerTurn);
      expect(guest2.status, MultiplayerStatus.myTurn);
      expect(await guest2.play(Move.parse('c7c5')!), isTrue);
      await until(() => host2.session.sync.moves.length == 2);
      await settle();
      expect(host2.session.sync.moves, ['e2e4', 'c7c5']);
      expect(host2.status, MultiplayerStatus.myTurn);
      await host2.close();
      await guest2.close();
    });

    test('RMP-09 a partita finita il salvataggio sparisce', () async {
      final guestStore = SavedGameStore(File('${dir.path}/guest.json'));
      final (host, guest) = await started(store, guestStore);
      for (final (c, uci) in [
        (host, 'f2f3'),
        (guest, 'e7e5'),
        (host, 'g2g4'),
        (guest, 'd8h4'),
      ]) {
        await c.play(Move.parse(uci)!);
        await settle();
      }
      await until(
        () =>
            host.status == MultiplayerStatus.finished &&
            guest.status == MultiplayerStatus.finished,
      );
      expect(host.status, MultiplayerStatus.finished);
      // Il file si cancella in coda alla scrittura: si attende su disco.
      for (var i = 0; i < 200; i++) {
        if (await store.load() == null && await guestStore.load() == null) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(await store.load(), isNull);
      expect(await guestStore.load(), isNull);
      await host.close();
      await guest.close();
    });
  });
}
