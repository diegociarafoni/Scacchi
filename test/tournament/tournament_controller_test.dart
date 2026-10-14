import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/progress/activity.dart';
import 'package:rokko/tournament/tournament.dart';
import 'package:rokko/tournament/tournament_controller.dart';

import 'tournament_test.dart' show bots;

/// Attende [condition] con tempi reali: il salvataggio usa file veri.
Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 300 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

void main() {
  late Directory dir;
  final recorded = <Activity>[];

  TournamentController controller({BotGameRunner? runner}) =>
      TournamentController(
        File('${dir.path}/tornei.json'),
        recordActivity: (a) async => recorded.add(a),
        clock: () => DateTime(2026, 10, 11, 18),
        playBotGame: runner,
      );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tornei');
    recorded.clear();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('un torneo iniziato si ritrova alla riapertura', () async {
    final c = controller();
    await c.load();
    await c.start(
      format: TournamentFormat.roundRobin,
      size: 4,
      userName: 'Tu',
      userElo: 1000,
      bots: bots,
    );
    await c.recordUserGame(1);
    final again = controller();
    await again.load();
    expect(again.current!.toJson(), c.current!.toJson());
  });

  test('a torneo finito: trofeo nella bacheca e attività registrata', () async {
    final c = controller();
    await c.load();
    await c.start(
      format: TournamentFormat.knockout,
      size: 4,
      userName: 'Tu',
      userElo: 1000,
      bots: bots,
    );
    while (c.current?.userGame != null) {
      await c.recordUserGame(1);
    }
    expect(c.current!.finished, isTrue);
    expect(c.trophies, hasLength(1));
    final trophy = c.trophies.single;
    expect(trophy.rank, 1);
    expect(trophy.players, 4);
    expect(trophy.format, TournamentFormat.knockout);
    expect(recorded.whereType<TournamentFinished>().single.rank, 1);

    await c.dismiss();
    expect(c.current, isNull);
    final again = controller();
    await again.load();
    expect(again.trophies.single.rank, 1);
    expect(again.current, isNull);
  });

  test('abbandonare non lascia trofei né XP', () async {
    final c = controller();
    await c.load();
    await c.start(
      format: TournamentFormat.roundRobin,
      size: 6,
      userName: 'Tu',
      userElo: 1000,
      bots: bots,
    );
    await c.dismiss();
    expect(c.current, isNull);
    expect(c.trophies, isEmpty);
    expect(recorded, isEmpty);
  });

  test(
    'un torneo o un trofeo non valido si scarta, gli altri restano',
    () async {
      final file = File('${dir.path}/tornei.json');
      await file.writeAsString(
        '{"version":1,"current":{"format":"sconosciuto"},"trophies":['
        '{"date":"2026-10-01T10:00:00.000","format":"knockout","players":4,'
        '"rank":1,"champion":"Anna"},{"rank":"x"},7]}',
      );
      final c = controller();
      await c.load();
      expect(c.current, isNull);
      expect(c.trophies.map((t) => t.champion), ['Anna']);
      expect(dir.listSync().where((f) => f.path.contains('.bad')), isEmpty);
    },
  );

  test('un file che non è un oggetto va in quarantena e non blocca', () async {
    final file = File('${dir.path}/tornei.json');
    await file.writeAsString('{"version":1,"trophies":{}}');
    final c = controller();
    await c.load();
    expect(c.current, isNull);
    expect(c.trophies, isEmpty);
    expect(dir.listSync().where((f) => f.path.contains('.bad')), hasLength(1));
  });

  test('registrare senza torneo non fa nulla', () async {
    final c = controller();
    await c.load();
    await c.recordUserGame(1);
    expect(c.current, isNull);
    expect(recorded, isEmpty);
  });

  group('partite tra bot giocate davvero', () {
    test('dopo la partita dell\'utente il motore gioca le altre', () async {
      final played = <(String, String)>[];
      final c = controller(
        runner: (white, black, seed) async {
          played.add((white.name, black.name));
          return 1;
        },
      );
      await c.load();
      await c.start(
        format: TournamentFormat.roundRobin,
        size: 4,
        userName: 'Tu',
        userElo: 1000,
        bots: bots,
      );
      expect(played, isEmpty, reason: 'prima gioca l\'utente');
      await c.recordUserGame(0.5);
      expect(played, hasLength(1));
      expect(c.current!.currentRound, 1);
      expect(c.playingBots, isFalse);
    });

    test('un torneo intero si chiude solo con risultati del motore', () async {
      var calls = 0;
      final c = controller(
        runner: (w, b, seed) async {
          calls++;
          return 0.5;
        },
      );
      await c.load();
      await c.start(
        format: TournamentFormat.knockout,
        size: 8,
        userName: 'Tu',
        userElo: 1000,
        bots: bots,
      );
      while (c.current?.userGame != null) {
        await c.recordUserGame(1);
      }
      expect(c.current!.finished, isTrue);
      // 3 partite tra bot al primo turno, più gli spareggi per le patte.
      expect(calls, greaterThanOrEqualTo(3));
      expect(c.trophies, hasLength(1));
      expect(recorded.whereType<TournamentFinished>(), hasLength(1));
    });

    test('senza motore (risultato nullo) si simula la partita', () async {
      final c = controller(runner: (w, b, seed) async => null);
      await c.load();
      await c.start(
        format: TournamentFormat.roundRobin,
        size: 4,
        userName: 'Tu',
        userElo: 1000,
        bots: bots,
      );
      while (c.current?.userGame != null) {
        await c.recordUserGame(1);
      }
      expect(c.current!.finished, isTrue);
    });

    test('un errore del motore ripiega sulla simulazione', () async {
      final c = controller(runner: (w, b, seed) => throw StateError('no'));
      await c.load();
      await c.start(
        format: TournamentFormat.roundRobin,
        size: 4,
        userName: 'Tu',
        userElo: 1000,
        bots: bots,
      );
      while (c.current?.userGame != null) {
        await c.recordUserGame(1);
      }
      expect(c.current!.finished, isTrue);
    });

    test('ogni partita giocata si salva: si riprende da dove era', () async {
      final gate = Completer<double?>();
      var calls = 0;
      final c = controller(
        runner: (w, b, seed) {
          calls++;
          return calls == 1 ? Future.value(1) : gate.future;
        },
      );
      await c.load();
      await c.start(
        format: TournamentFormat.roundRobin,
        size: 6,
        userName: 'Tu',
        userElo: 1000,
        bots: bots,
      );
      final running = c.recordUserGame(1);
      await until(() => calls == 2);
      expect(c.playingBots, isTrue);
      final again = controller();
      await again.load();
      expect(again.current!.pendingBotGames, isNotEmpty);
      // Riapertura: la partita rimasta si riprende con un motore.
      final resumed = controller(runner: (w, b, seed) async => 0);
      await resumed.load();
      await resumed.resumeBots();
      expect(
        resumed.current!.userGame != null || resumed.current!.finished,
        isTrue,
      );
      expect(resumed.current!.pendingBotGames, isEmpty);
      gate.complete(null);
      await running;
    });

    test(
      'abbandonare mentre giocano i bot ignora i risultati in arrivo',
      () async {
        final gate = Completer<double?>();
        final c = controller(runner: (w, b, seed) => gate.future);
        await c.load();
        await c.start(
          format: TournamentFormat.roundRobin,
          size: 4,
          userName: 'Tu',
          userElo: 1000,
          bots: bots,
        );
        final running = c.recordUserGame(1);
        await Future<void>.delayed(Duration.zero);
        await c.dismiss();
        gate.complete(1);
        await running;
        expect(c.current, isNull);
        expect(c.trophies, isEmpty);
        expect(c.playingBots, isFalse);
      },
    );
  });
}
