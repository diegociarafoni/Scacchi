import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/challenges.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_tracker.dart';

DateTime day(int d, [int hour = 12]) => DateTime(2026, 10, d, hour);

extension on ChallengeKind {
  /// Attività che fa avanzare la sfida.
  Activity get sample => switch (this) {
    ChallengeKind.playGames ||
    ChallengeKind.winGames ||
    ChallengeKind.winWithWhite => const GamePlayed(
      result: GameResult.win,
      playerSide: Side.white,
      moveCount: 20,
    ),
    ChallengeKind.winWithBlack => const GamePlayed(
      result: GameResult.win,
      playerSide: Side.black,
      moveCount: 20,
    ),
    ChallengeKind.winShort => const GamePlayed(
      result: GameResult.win,
      moveCount: 20,
      checkmate: true,
    ),
    ChallengeKind.solvePuzzles ||
    ChallengeKind.forkPuzzles ||
    ChallengeKind.matePuzzles => const PuzzleSolved(
      themes: {'fork', 'mateIn2'},
    ),
    ChallengeKind.reviewGame => const ReviewCompleted(),
    ChallengeKind.completeLesson => const LessonCompleted(),
    ChallengeKind.goalDays => const GamePlayed(result: GameResult.loss),
  };
}

void main() {
  group('RG-07 sfide giornaliere', () {
    test('tre sfide diverse al giorno, sempre le stesse per la data', () {
      for (var d = 0; d < 60; d++) {
        final today = 20000 + d;
        final a = dailyChallenges(today);
        expect(a, hasLength(3));
        expect(a.map((c) => c.kind).toSet(), hasLength(3));
        expect(dailyChallenges(today), a);
      }
    });

    test('almeno una sfida riguarda le partite', () {
      for (var d = 0; d < 60; d++) {
        expect(dailyChallenges(20000 + d).any((c) => c.kind.isGame), isTrue);
      }
    });

    test('valori fissati: stessa scelta su ogni piattaforma', () {
      // Valori calcolati a parte con aritmetica a 32 bit.
      expect(mix32(1), 1364076727);
      expect(mix32(20000), 3557571671);
      expect(mix32(0xFFFFFFFF), 2180083513);
      expect(mix32(123456789), 3126909082);
    });

    test('cambiano da un giorno all\'altro', () {
      final days = {for (var d = 0; d < 14; d++) dailyChallenges(20000 + d)};
      expect(days.length, greaterThan(5));
    });

    test('ogni sfida ha un titolo leggibile', () {
      for (final kind in ChallengeKind.values) {
        expect(Challenge(kind, 3).title, isNotEmpty);
      }
    });

    test('avanzamento per tipo di attività', () {
      const winBlack = GamePlayed(
        result: GameResult.win,
        playerSide: Side.black,
        moveCount: 40,
      );
      expect(ChallengeKind.winWithBlack.advance(winBlack), 1);
      expect(
        ChallengeKind.winWithBlack.advance(
          const GamePlayed(result: GameResult.win, playerSide: Side.white),
        ),
        0,
      );
      expect(ChallengeKind.playGames.advance(winBlack), 1);
      expect(ChallengeKind.winGames.advance(winBlack), 1);
      expect(ChallengeKind.winShort.advance(winBlack), 0);
      expect(
        ChallengeKind.winShort.advance(
          const GamePlayed(
            result: GameResult.win,
            moveCount: 25,
            checkmate: true,
          ),
        ),
        1,
      );
      expect(
        ChallengeKind.winShort.advance(
          const GamePlayed(result: GameResult.win, moveCount: 25),
        ),
        0,
      );
      expect(
        ChallengeKind.forkPuzzles.advance(
          const PuzzleSolved(themes: {'fork', 'middlegame'}),
        ),
        1,
      );
      expect(
        ChallengeKind.forkPuzzles.advance(const PuzzleSolved(themes: {'pin'})),
        0,
      );
      expect(ChallengeKind.solvePuzzles.advance(const PuzzleSolved()), 1);
      expect(ChallengeKind.reviewGame.advance(const ReviewCompleted()), 1);
      expect(ChallengeKind.completeLesson.advance(const LessonCompleted()), 1);
    });
  });

  group('RG-07 sfide nel tracker', () {
    final tracker = ProgressTracker();
    const settings = ProgressSettings();

    ({ProgressState state, int xp, List<Challenge> done}) completeAll(
      ProgressState state,
      DateTime now,
    ) {
      var xp = 0;
      final done = <Challenge>[];
      for (final c in dailyChallenges(dayNumber(now))) {
        for (var i = 0; i < c.target; i++) {
          final u = tracker.record(state, c.kind.sample, now, settings);
          state = u.state;
          xp += u.xpGained;
          done.addAll(u.challengesCompleted);
        }
      }
      return (state: state, xp: xp, done: done);
    }

    test('completare una sfida dà XP bonus una sola volta', () {
      final result = completeAll(ProgressState.initial, day(5));
      expect(
        result.done.toSet(),
        containsAll(dailyChallenges(dayNumber(day(5)))),
      );
      final progress = tracker.challengeProgress(result.state, day(5));
      for (final (c, p) in progress) {
        expect(p, greaterThanOrEqualTo(c.target));
      }
      expect(result.state.challengesCompleted, greaterThanOrEqualTo(3));
      final again = completeAll(result.state, day(5));
      expect(
        again.done.where((c) => dailyChallenges(dayNumber(day(5))).contains(c)),
        isEmpty,
      );
    });

    test('il giorno dopo il progresso riparte da zero', () {
      final result = completeAll(ProgressState.initial, day(5));
      final next = tracker.challengeProgress(result.state, day(6));
      expect(next.map((e) => e.$2), everyElement(0));
    });

    test('tutte e tre le sfide del giorno sbloccano un traguardo', () {
      final result = completeAll(ProgressState.initial, day(5));
      expect(result.state.unlocked, contains('challenges_all'));
    });
  });

  group('RG-07 sfida settimanale', () {
    final tracker = ProgressTracker();
    const settings = ProgressSettings();

    test('una per settimana, uguale da lunedì a domenica', () {
      // 5-11 ottobre 2026: da lunedì a domenica.
      final monday = weeklyChallenge(weekNumber(dayNumber(day(5))));
      for (var d = 6; d <= 11; d++) {
        expect(weeklyChallenge(weekNumber(dayNumber(day(d)))), monday);
      }
      expect(weekNumber(dayNumber(day(12))), weekNumber(dayNumber(day(5))) + 1);
    });

    test('si completa sommando i giorni della settimana', () {
      final weekly = weeklyChallenge(weekNumber(dayNumber(day(5))));
      var state = ProgressState.initial;
      var completed = false;
      for (var i = 0; i < weekly.target * 3 && !completed; i++) {
        final u = tracker.record(
          state,
          weekly.kind.sample,
          day(5 + (i % 7)),
          settings,
        );
        state = u.state;
        completed = u.weeklyCompleted;
      }
      expect(completed, isTrue);
    });
  });
}
