import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/progress/activity.dart';
import 'package:rokko/summary/week_log.dart';

void main() {
  final now = DateTime(2026, 10, 12, 9);

  group('RG-16 diario settimanale', () {
    test('registra partite per esito e ignora quelle tra due persone', () {
      var log = const WeekLog();
      log = log.record(const GamePlayed(result: GameResult.win), now);
      log = log.record(const GamePlayed(result: GameResult.draw), now);
      log = log.record(const GamePlayed(result: GameResult.loss), now);
      log = log.record(const GamePlayed(result: GameResult.local), now);
      final day = log.dayOf(now)!;
      expect((day.games, day.wins, day.draws, day.losses), (3, 1, 1, 1));
    });

    test('registra puzzle, lezioni e secondi di allenamento', () {
      var log = const WeekLog();
      log = log.record(
        const PuzzleSolved(duration: Duration(seconds: 40)),
        now,
      );
      log = log.record(
        const LessonCompleted(duration: Duration(minutes: 2)),
        now,
      );
      final day = log.dayOf(now)!;
      expect((day.puzzles, day.lessons, day.seconds), (1, 1, 160));
    });

    test('la revisione somma precisione ed errori per tema', () {
      var log = const WeekLog();
      log = log.record(
        const ReviewCompleted(
          gameId: 'a',
          accuracy: 80,
          errorThemes: {'hangingPiece': 2, 'allowedFork': 1},
        ),
        now,
      );
      log = log.record(
        const ReviewCompleted(
          gameId: 'b',
          accuracy: 60,
          errorThemes: {'hangingPiece': 1},
        ),
        now,
      );
      final day = log.dayOf(now)!;
      expect(day.reviews, 2);
      expect((day.accuracySum, day.accuracyCount), (140, 2));
      expect(day.errors, {'hangingPiece': 3, 'allowedFork': 1});
    });

    test('la stessa partita rivista due volte conta una volta', () {
      var log = const WeekLog();
      const review = ReviewCompleted(
        gameId: 'a',
        accuracy: 80,
        errorThemes: {'hangingPiece': 2},
      );
      log = log.record(review, now);
      log = log.record(review, now.add(const Duration(days: 1)));
      expect(log.dayOf(now)!.errors, {'hangingPiece': 2});
      expect(log.dayOf(now.add(const Duration(days: 1))), isNull);
    });

    test('elimina i giorni più vecchi di 14', () {
      var log = const WeekLog();
      log = log.record(
        const PuzzleSolved(),
        now.subtract(const Duration(days: 14)),
      );
      log = log.record(
        const PuzzleSolved(),
        now.subtract(const Duration(days: 13)),
      );
      log = log.record(const PuzzleSolved(), now);
      expect(log.dayOf(now.subtract(const Duration(days: 14))), isNull);
      expect(log.dayOf(now.subtract(const Duration(days: 13))), isNotNull);
    });

    test('un contatore salvato come numero decimale si legge lo stesso', () {
      final log = WeekLog.fromJson({
        'days': {
          '20261012': {
            'puzzles': 3.0,
            'errors': {'allowedPin': 2.0},
          },
        },
      });
      expect(log.dayOf(now)!.puzzles, 3);
      expect(log.dayOf(now)!.errors, {'allowedPin': 2});
    });

    test('il JSON non contiene nulla oltre ai conteggi e torna uguale', () {
      var log = const WeekLog();
      log = log.record(const GamePlayed(result: GameResult.win), now);
      log = log.record(
        const ReviewCompleted(
          gameId: 'a',
          accuracy: 75.5,
          errorThemes: {'missedMate': 1},
        ),
        now,
      );
      final back = WeekLog.fromJson(log.toJson());
      expect(back.toJson(), log.toJson());
      expect(back.dayOf(now)!.errors, {'missedMate': 1});
    });
  });

  group('RG-16 archivio del diario', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('week'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('senza file il diario è vuoto', () async {
      final store = WeekLogStore(File('${dir.path}/week.json'));
      expect((await store.load()).isEmpty, isTrue);
    });

    test('salva e rilegge', () async {
      final file = File('${dir.path}/week.json');
      final log = const WeekLog().record(const PuzzleSolved(), now);
      await WeekLogStore(file).save(log);
      expect((await WeekLogStore(file).load()).dayOf(now)!.puzzles, 1);
    });

    test('un file rovinato riparte vuoto senza perdere il file', () async {
      final file = File('${dir.path}/week.json')..writeAsStringSync('{ no');
      final log = await WeekLogStore(file).load();
      expect(log.isEmpty, isTrue);
      expect(dir.listSync().any((e) => e.path.contains('.bad-')), isTrue);
    });
  });
}
