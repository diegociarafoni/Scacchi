import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/puzzles/themes.dart';
import 'package:scacchi/review/coach.dart';
import 'package:scacchi/summary/week_log.dart';
import 'package:scacchi/summary/weekly_summary.dart';

void main() {
  final now = DateTime(2026, 10, 12, 9);
  DateTime ago(int days) => now.subtract(Duration(days: days));

  WeekLog log(List<(Activity, int)> items) =>
      items.fold(const WeekLog(), (l, e) => l.record(e.$1, ago(e.$2)));

  ReviewCompleted review(
    String id,
    Map<String, int> errors, {
    double accuracy = 70,
  }) => ReviewCompleted(gameId: id, accuracy: accuracy, errorThemes: errors);

  group('RG-16 progressi', () {
    test('senza attività il riepilogo è vuoto', () {
      expect(WeeklySummary.from(const WeekLog(), now).isEmpty, isTrue);
    });

    test('somma gli ultimi sette giorni, oggi compreso', () {
      final s = WeeklySummary.from(
        log([
          (const GamePlayed(result: GameResult.win), 0),
          (const GamePlayed(result: GameResult.loss), 6),
          (const GamePlayed(result: GameResult.win), 7),
          (const PuzzleSolved(duration: Duration(minutes: 3)), 2),
          (const LessonCompleted(duration: Duration(minutes: 2)), 2),
        ]),
        now,
      );
      expect((s.week.games, s.week.wins, s.week.losses), (2, 1, 1));
      expect((s.week.puzzles, s.week.lessons), (1, 1));
      expect(s.week.minutes, 5);
      expect(s.week.activeDays, 3);
      expect(s.isEmpty, isFalse);
    });

    test('la settimana prima serve al confronto', () {
      final s = WeeklySummary.from(
        log([
          (review('a', const {}, accuracy: 80), 1),
          (review('b', const {}, accuracy: 60), 9),
        ]),
        now,
      );
      expect(s.week.accuracy, 80);
      expect(s.previous.accuracy, 60);
      expect(s.accuracyChange, 20);
    });

    test('senza precisione la settimana prima non c\'è differenza', () {
      final s = WeeklySummary.from(
        log([(review('a', const {}, accuracy: 80), 1)]),
        now,
      );
      expect(s.accuracyChange, isNull);
    });
  });

  group('RG-16 errore più frequente', () {
    test('è il tema con più occorrenze nella settimana', () {
      final s = WeeklySummary.from(
        log([
          (review('a', const {'hangingPiece': 2, 'allowedFork': 1}), 1),
          (review('b', const {'allowedFork': 3}), 2),
        ]),
        now,
      );
      expect(s.topError, 'allowedFork');
      expect(s.topErrorCount, 4);
    });

    test('un errore isolato non è ricorrente', () {
      final s = WeeklySummary.from(
        log([
          (review('a', const {'hangingPiece': 1}), 1),
        ]),
        now,
      );
      expect(s.topError, isNull);
    });

    test('a parità vince il tema in ordine alfabetico', () {
      final s = WeeklySummary.from(
        log([
          (review('a', const {'hangingPiece': 2, 'allowedPin': 2}), 1),
        ]),
        now,
      );
      expect(s.topError, 'allowedPin');
    });

    test('gli errori della settimana prima non contano', () {
      final s = WeeklySummary.from(
        log([
          (review('a', const {'hangingPiece': 5}), 8),
        ]),
        now,
      );
      expect(s.topError, isNull);
    });
  });

  group('RG-16 consiglio', () {
    Advice adviceFor(String error) => WeeklySummary.from(
      log([
        (review('a', {error: 2}), 1),
      ]),
      now,
    ).advice;

    test('ogni errore del coach ha un collegamento valido', () {
      final stages = {
        for (final c in curriculum)
          for (final s in c.stages) s.id,
      };
      for (final theme in CoachTheme.values) {
        if (!recurringErrors.contains(theme.name)) continue;
        final advice = adviceFor(theme.name);
        switch (advice.kind) {
          case AdviceKind.lesson:
            expect(stages, contains(advice.target), reason: theme.name);
          case AdviceKind.puzzles:
            expect(
              puzzleThemeLabels,
              contains(advice.target),
              reason: theme.name,
            );
          default:
            fail('${theme.name}: consiglio senza collegamento');
        }
      }
    });

    test('i commenti generici e i complimenti non sono errori', () {
      expect(recurringErrors, isNot(contains('generic')));
      expect(recurringErrors, isNot(contains('praise')));
    });

    test('pezzi in presa rimandano alla lezione sui pezzi in presa', () {
      final a = adviceFor('hangingPiece');
      expect((a.kind, a.target), (AdviceKind.lesson, 'tactics.hanging'));
    });

    test('catture mancate rimandano ai puzzle del pezzo in presa', () {
      final a = adviceFor('missedCapture');
      expect((a.kind, a.target), (AdviceKind.puzzles, 'hangingPiece'));
    });

    test('con partite ma senza revisioni si consiglia di rivederne una', () {
      final s = WeeklySummary.from(
        log([(const GamePlayed(result: GameResult.win), 1)]),
        now,
      );
      expect(s.advice.kind, AdviceKind.reviewGame);
      expect(s.advice.target, isNull);
    });

    test('senza puzzle si consiglia di risolverne qualcuno', () {
      final s = WeeklySummary.from(
        log([
          (const GamePlayed(result: GameResult.win), 1),
          (review('a', const {}), 1),
        ]),
        now,
      );
      expect(s.advice.kind, AdviceKind.solvePuzzles);
    });

    test('nel profilo bambino non si consiglia di rivedere le partite', () {
      final s = WeeklySummary.from(
        log([
          (const GamePlayed(result: GameResult.win), 1),
          (const PuzzleSolved(), 1),
        ]),
        now,
        kid: true,
      );
      expect(s.advice.kind, AdviceKind.keepGoing);
    });

    test('altrimenti si continua così', () {
      final s = WeeklySummary.from(
        log([
          (const GamePlayed(result: GameResult.win), 1),
          (review('a', const {}), 1),
          (const PuzzleSolved(), 1),
        ]),
        now,
      );
      expect(s.advice.kind, AdviceKind.keepGoing);
    });
  });
}
