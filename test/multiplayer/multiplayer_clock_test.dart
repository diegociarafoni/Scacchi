import 'dart:io';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/exchange/qr_code_view.dart';
import 'package:scacchi/game/clock.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/game_message.dart';
import 'package:scacchi/multiplayer/game_sync.dart';
import 'package:scacchi/multiplayer/match_clock.dart';
import 'package:scacchi/multiplayer/multiplayer_controller.dart';
import 'package:scacchi/multiplayer/multiplayer_page.dart';
import 'package:scacchi/multiplayer/saved_game.dart';
import 'package:scacchi/multiplayer/transport.dart';

import '../localized_app.dart';

const blitz = TimeControl(minutes: 3, increment: 2);

final hostKey = Uint8List.fromList(List.filled(32, 1));
final guestKey = Uint8List.fromList(List.filled(32, 2));

/// Orologio di parete che avanza solo quando lo si dice.
class FakeNow {
  DateTime value = DateTime.utc(2026, 10, 12, 15);
  DateTime call() => value;
  void advance(Duration d) => value = value.add(d);
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

GameInvite invite({TimeControl? control}) => GameInvite(
  gameId: newGameId(),
  secret: newSecret(),
  hostKey: hostKey,
  hostSide: Side.white,
  lanAddress: '10.0.0.2:4000',
  timeControl: control,
);

Future<(MultiplayerController, MultiplayerController)> pair(
  FakeNow now, {
  TimeControl? control = blitz,
  Side hostSide = Side.white,
  (LoopbackTransport, LoopbackTransport)? loops,
  FakeNow? guestNow,
}) async {
  final (a, b) = loops ?? LoopbackTransport.pair();
  final host = await MultiplayerController.host(
    side: hostSide,
    timeControl: control,
    now: now.call,
    openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
  );
  final guest = await MultiplayerController.join(
    GameInvite.parse(host.inviteLink)!,
    now: (guestNow ?? now).call,
    openGuest: (_, _) => b,
  );
  await settle();
  return (host, guest);
}

Future<void> play(MultiplayerController c, String uci) async {
  expect(await c.play(Move.parse(uci)!), isTrue);
  await settle();
}

void main() {
  group('invito con la cadenza', () {
    test('RMP-50 la cadenza viaggia nel link e si rilegge', () {
      final link = invite(control: blitz).toLink();
      expect(GameInvite.parse(link)!.timeControl, blitz);
    });

    test('RMP-50 senza cadenza la partita resta senza orologio', () {
      final back = GameInvite.parse(invite().toLink())!;
      expect(back.timeControl, isNull);
    });

    test(
      'RMP-50 una cadenza non valida o fuori misura rende nullo l\'invito',
      () {
        final base = invite().toLink();
        for (final tc in [
          'abc',
          '0+0',
          '-1+0',
          '5+-1',
          '5',
          '999+0',
          '5+999',
        ]) {
          expect(GameInvite.parse('$base&tc=$tc'), isNull, reason: tc);
        }
      },
    );
  });

  group('messaggi', () {
    test('RMP-50 la mossa porta il tempo di chi l\'ha giocata', () {
      const m = MoveMessage(
        seq: 1,
        uci: 'e2e4',
        positionHash: 'abc',
        timeMs: 179000,
      );
      expect(GameMessage.fromJson(m.toJson()), m);
      expect(m.toJson()['c'], 179000);
    });

    test('RMP-50 una mossa senza tempo resta valida', () {
      final json = {'t': 'move', 'n': 1, 'm': 'e2e4', 'h': 'abc'};
      expect((GameMessage.fromJson(json)! as MoveMessage).timeMs, isNull);
    });

    test('RMP-50 un tempo negativo, enorme o non numerico è scartato', () {
      for (final c in <Object>[-1, 86400001, 'x', 1.5]) {
        final json = {'t': 'move', 'n': 1, 'm': 'e2e4', 'h': 'abc', 'c': c};
        expect(GameMessage.fromJson(json), isNull, reason: '$c');
      }
    });

    test('RMP-50 il messaggio di tempo scaduto si rilegge', () {
      const f = FlagMessage(plies: 6);
      expect(GameMessage.fromJson(f.toJson()), f);
      expect(GameMessage.fromJson({'t': 'flag', 'n': 0}), isNull);
      expect(GameMessage.fromJson({'t': 'flag', 'n': 99999}), isNull);
    });
  });

  group('registro', () {
    GameSync host() => GameSync(mySide: Side.white, myKey: hostKey);
    GameSync guest() =>
        GameSync(mySide: Side.black, myKey: guestKey, peerKey: hostKey);

    test('RMP-50 i tempi delle mosse si conservano e si rimandano', () {
      final h = host()..receive(const JoinMessage(), guestKey);
      final g = guest();
      g.receive(h.playLocal('e2e4', timeMs: 180000), hostKey);
      expect(g.times, [180000]);
      expect(g.movesFrom(1).single.timeMs, 180000);
      expect(
        GameSync(
          mySide: Side.black,
          myKey: guestKey,
          peerKey: hostKey,
          moves: g.moves,
          times: g.times,
        ).times,
        [180000],
      );
    });

    test('RMP-50 il tempo scaduto di chi è di turno chiude la partita', () {
      final h = host()..receive(const JoinMessage(), guestKey);
      final g = guest();
      g.receive(h.playLocal('e2e4'), hostKey);
      final flag = g.flagSelf();
      expect(flag.plies, 1);
      expect(g.isGameOver, isTrue);
      expect(g.outcome, Outcome.whiteWins);
      expect(h.receive(flag, guestKey), isA<Flagged>());
      expect(h.isGameOver, isTrue);
      expect(h.outcome, Outcome.whiteWins);
      expect(h.receive(flag, guestKey), isA<Duplicate>());
    });

    test('RMP-50 il tempo scaduto è valido solo dal giocatore di turno', () {
      final h = host()..receive(const JoinMessage(), guestKey);
      // Tocca al Bianco: il Nero non può dichiarare scaduto il proprio tempo.
      expect(h.receive(const FlagMessage(plies: 0 + 1), guestKey), isA<Gap>());
      expect(h.isGameOver, isFalse);
      h.playLocal('e2e4');
      expect(h.receive(const FlagMessage(plies: 1), hostKey), isA<Rejected>());
      expect(
        h.receive(const FlagMessage(plies: 1), Uint8List(32)),
        isA<Rejected>(),
      );
      expect(h.isGameOver, isFalse);
    });

    test('RMP-50 con la partita chiusa non si gioca più', () {
      final h = host()..receive(const JoinMessage(), guestKey);
      h.flagSelf();
      expect(() => h.playLocal('e2e4'), throwsStateError);
    });

    test('RMP-50 senza materiale per il matto il tempo scaduto è patta', () {
      final bare = Chess.fromSetup(
        Setup.parseFen('8/8/8/8/8/2k5/8/K6R w - - 0 1'),
      );
      // Se scade il Bianco ha comunque la torre; se scade il Nero resta il Re.
      expect(timeoutOutcome(bare, Side.black), Outcome.whiteWins);
      final kings = Chess.fromSetup(
        Setup.parseFen('8/8/8/8/8/2k5/8/K7 w - - 0 1'),
      );
      expect(timeoutOutcome(kings, Side.black), Outcome.draw);
      expect(timeoutOutcome(kings, Side.white), Outcome.draw);
    });
  });

  group('orologio della partita', () {
    test('RMP-50 parte alla prima mossa e il primo bianco non perde tempo', () {
      final now = FakeNow();
      final clock = MatchClock(blitz, now: now.call);
      expect(clock.active, isNull);
      now.advance(const Duration(minutes: 1));
      clock.moved(1);
      expect(clock.active, Side.black);
      expect(clock.remaining(Side.white), const Duration(minutes: 3));
    });

    test(
      'RMP-50 la mossa aggiunge l\'incremento e il tempo dichiarato vale',
      () {
        final now = FakeNow();
        final clock = MatchClock(blitz, now: now.call)..moved(1);
        now.advance(const Duration(seconds: 10));
        final left = clock.moved(2);
        expect(left, const Duration(seconds: 172));
        expect(clock.active, Side.white);
        // L'avversario dichiara il proprio tempo: prevale sul calcolo locale.
        now.advance(const Duration(seconds: 5));
        clock.moved(3, left: const Duration(seconds: 170));
        expect(clock.remaining(Side.white), const Duration(seconds: 170));
        expect(clock.active, Side.black);
      },
    );

    test('RMP-50 un tempo dichiarato troppo alto viene limitato', () {
      final clock = MatchClock(blitz, now: FakeNow().call)..moved(1);
      clock.moved(2, left: const Duration(hours: 5));
      // Tempo iniziale più incremento, non di più.
      expect(clock.remaining(Side.black), const Duration(seconds: 182));
      // Alla mossa dopo il tetto parte dal valore dichiarato prima.
      clock.moved(3);
      clock.moved(4, left: const Duration(hours: 1));
      expect(clock.remaining(Side.black), const Duration(seconds: 184));
    });

    test('RMP-50 il lato senza tempo risulta scaduto', () {
      final now = FakeNow();
      final clock = MatchClock(blitz, now: now.call)..moved(1);
      now.advance(const Duration(minutes: 3, seconds: 1));
      expect(clock.flagged, Side.black);
    });

    test(
      'RMP-50 dal registro si ricostruisce lo stato, col tempo trascorso',
      () {
        final now = FakeNow();
        final started = now.value;
        now.advance(const Duration(seconds: 30));
        final clock = MatchClock.restore(
          blitz,
          times: [null, 150000],
          turnStartedAt: started,
          now: now.call,
        );
        expect(clock.active, Side.white);
        expect(clock.remaining(Side.black), const Duration(seconds: 150));
        expect(clock.remaining(Side.white), const Duration(seconds: 150));
      },
    );
  });

  group('partita a tempo tra due telefoni', () {
    test('RMP-50 chi crea decide la cadenza e l\'altro la riceve', () async {
      final (host, guest) = await pair(FakeNow());
      expect(host.timeControl, blitz);
      expect(guest.timeControl, blitz);
      await host.close();
      await guest.close();
    });

    test('RMP-50 senza cadenza non c\'è orologio', () async {
      final (host, guest) = await pair(FakeNow(), control: null);
      expect(host.clock, isNull);
      expect(guest.clock, isNull);
      await host.close();
      await guest.close();
    });

    test(
      'RMP-50 il tempo viaggia con la mossa e i due orologi concordano',
      () async {
        final now = FakeNow();
        final (host, guest) = await pair(now);
        await play(host, 'e2e4');
        now.advance(const Duration(seconds: 7));
        await play(guest, 'e7e5');
        now.advance(const Duration(seconds: 4));
        await play(host, 'g1f3');
        // Nero: 3:00 - 7 s + 2 s. Bianco: 3:00 - 4 s + 2 s.
        for (final c in [host, guest]) {
          expect(c.clock!.remaining(Side.black), const Duration(seconds: 175));
          expect(c.clock!.remaining(Side.white), const Duration(seconds: 178));
          expect(c.clock!.active, Side.black);
        }
        expect(guest.session.sync.times, host.session.sync.times);
        await host.close();
        await guest.close();
      },
    );

    test('RMP-50 scaduto il proprio tempo si perde e l\'altro lo sa', () async {
      final now = FakeNow();
      final (host, guest) = await pair(now);
      await play(host, 'e2e4');
      now.advance(const Duration(minutes: 3, seconds: 1));
      guest.tick();
      await settle();
      expect(guest.status, MultiplayerStatus.finished);
      expect(guest.outcome, Outcome.whiteWins);
      expect(guest.endedOnTime, isTrue);
      expect(host.status, MultiplayerStatus.finished);
      expect(host.outcome, Outcome.whiteWins);
      expect(host.endedOnTime, isTrue);
      await host.close();
      await guest.close();
    });

    test('RMP-50 non si muove a tempo scaduto', () async {
      final now = FakeNow();
      final (host, guest) = await pair(now);
      await play(host, 'e2e4');
      now.advance(const Duration(minutes: 4));
      expect(await guest.play(Move.parse('e7e5')!), isFalse);
      await host.close();
      await guest.close();
    });

    test(
      'RMP-50 se l\'avversario sparisce, dopo la tolleranza si vince',
      () async {
        final now = FakeNow();
        final loops = LoopbackTransport.pair();
        final (host, guest) = await pair(now, loops: loops);
        await play(host, 'e2e4');
        loops.$1.online = false;
        now.advance(const Duration(minutes: 3, seconds: 1));
        host.tick();
        expect(host.status, MultiplayerStatus.peerTurn);
        now.advance(peerFlagGrace + const Duration(seconds: 1));
        host.tick();
        expect(host.status, MultiplayerStatus.finished);
        expect(host.outcome, Outcome.whiteWins);
        await host.close();
        await guest.close();
      },
    );

    test(
      'RMP-50 una mossa in tempo arrivata durante l\'attesa non perde',
      () async {
        final now = FakeNow();
        final (host, guest) = await pair(now, guestNow: FakeNow());
        await play(host, 'e2e4');
        now.advance(const Duration(minutes: 3, seconds: 1));
        host.tick();
        // Il telefono dell'avversario ha ancora tempo: la mossa era in viaggio.
        await play(guest, 'e7e5');
        now.advance(peerFlagGrace + const Duration(seconds: 1));
        host.tick();
        expect(host.status, MultiplayerStatus.myTurn);
        expect(host.clock!.remaining(Side.black), const Duration(seconds: 182));
        await host.close();
        await guest.close();
      },
    );

    test(
      'RMP-50 la partita riprende col tempo che passa mentre l\'app è chiusa',
      () async {
        final dir = Directory.systemTemp.createTempSync('rokko_clock');
        addTearDown(() => dir.deleteSync(recursive: true));
        final store = SavedGameStore(File('${dir.path}/multiplayer.json'));
        final now = FakeNow();
        final (a, b) = LoopbackTransport.pair();
        final host = await MultiplayerController.host(
          side: Side.white,
          timeControl: blitz,
          now: now.call,
          store: store,
          openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
        );
        final guest = await MultiplayerController.join(
          GameInvite.parse(host.inviteLink)!,
          now: now.call,
          openGuest: (_, _) => b,
        );
        await settle();
        await play(host, 'e2e4');
        now.advance(const Duration(seconds: 5));
        await play(guest, 'e7e5');
        await guest.close();
        await host.close();

        now.advance(const Duration(seconds: 20));
        final saved = (await store.load())!;
        expect(saved.times, [180000, 177000]);
        final back = await MultiplayerController.resume(
          saved,
          now: now.call,
          openHost: (_) async => (
            transport: LoopbackTransport.pair().$1,
            lanAddress: '10.0.0.2:4000',
          ),
        );
        expect(back.clock!.active, Side.white);
        expect(back.clock!.remaining(Side.white), const Duration(seconds: 160));
        expect(back.clock!.remaining(Side.black), const Duration(seconds: 177));
        await back.close();
      },
    );
  });

  group('salvataggio', () {
    SavedGame sample({List<int?> times = const [], int? at}) => SavedGame(
      inviteLink: invite(control: blitz).toLink(),
      isHost: true,
      seed: Uint8List(32),
      moves: const ['e2e4', 'e7e5'],
      sealed: const {},
      times: times,
      turnStartedAt: at,
    );

    test('RMP-50 tempi e inizio del turno si rileggono', () {
      final json = sample(times: [180000, 177000], at: 1700000000000).toJson();
      final back = SavedGame.fromJson(json)!;
      expect(back.times, [180000, 177000]);
      expect(back.turnStartedAt, 1700000000000);
    });

    test('RMP-50 un salvataggio senza tempi si legge ancora', () {
      final json = sample().toJson();
      expect(json.containsKey('times'), isFalse);
      final back = SavedGame.fromJson(json)!;
      expect(back.times, isEmpty);
      expect(back.turnStartedAt, isNull);
    });
  });

  group('schermata', () {
    testWidgets('RMP-50 chi crea sceglie la cadenza e la trova nell\'invito', (
      tester,
    ) async {
      final (a, _) = LoopbackTransport.pair();
      await tester.pumpWidget(
        localizedApp(
          home: MultiplayerPage(
            remoteByDefault: false,
            openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
          ),
        ),
      );
      expect(find.text('Senza orologio'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<TimeControl?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3+2').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Crea la partita'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Crea la partita'));
      await tester.pump();
      await tester.tap(find.text('Crea la partita'));
      await tester.runAsync(settle);
      await tester.pumpAndSettle();
      final qr = tester.widget<QrCodeView>(find.byType(QrCodeView));
      expect(GameInvite.parse(qr.data)!.timeControl, blitz);
    });

    testWidgets(
      'RMP-50 in partita si vedono i due orologi e l\'esito a tempo',
      (tester) async {
        final now = FakeNow();
        final (host, guest) = (await tester.runAsync(() => pair(now)))!;
        await tester.pumpWidget(
          localizedApp(home: MultiplayerGamePage(controller: guest)),
        );
        await tester.runAsync(() => play(host, 'e2e4'));
        await tester.pump();
        expect(find.byKey(const ValueKey('clock-white')), findsOneWidget);
        expect(find.byKey(const ValueKey('clock-black')), findsOneWidget);
        expect(find.text('3:00'), findsNWidgets(2));

        now.advance(const Duration(minutes: 3, seconds: 1));
        guest.tick();
        await tester.runAsync(settle);
        await tester.pump();
        expect(find.text('Tempo scaduto: vince il Bianco'), findsOneWidget);
        await tester.runAsync(host.close);
      },
    );
  });
}
