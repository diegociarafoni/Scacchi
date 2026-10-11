import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/achievements.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/daily_goal.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_tracker.dart';
import 'package:scacchi/progress/xp.dart';

// 2026-10-05 è un lunedì.
DateTime day(int d, [int hour = 12]) => DateTime(2026, 10, d, hour);

const loss = GamePlayed(result: GameResult.loss);
const win = GamePlayed(result: GameResult.win);

void main() {
  const settings = ProgressSettings();
  final tracker = ProgressTracker();

  ProgressState playDays(Iterable<int> days, {ProgressSettings? s}) {
    var state = ProgressState.initial;
    for (final d in days) {
      state = tracker.record(state, loss, day(d), s ?? settings).state;
    }
    return state;
  }

  group('RG-01 XP e livelli nel profilo', () {
    test('registrare una partita aggiunge XP e la conta', () {
      final update = tracker.record(
        ProgressState.initial,
        win,
        day(5),
        settings,
      );
      expect(update.xpGained, greaterThan(0));
      expect(update.state.xp, greaterThanOrEqualTo(update.xpGained));
      expect(update.state.gamesPlayed, 1);
      expect(update.state.wins, 1);
    });

    test('segnala il passaggio di livello', () {
      var state = ProgressState.initial;
      int? newLevel;
      for (var i = 0; i < 20 && newLevel == null; i++) {
        newLevel = tracker.record(state, loss, day(5), settings).newLevel;
        state = tracker.record(state, loss, day(5), settings).state;
      }
      expect(newLevel, 2);
    });
  });

  group('RG-02 obiettivo giornaliero', () {
    test('obiettivo predefinito: una partita', () {
      expect(settings.goal, const DailyGoal(GoalKind.games, 1));
    });

    test('raggiunto con il numero richiesto di puzzle', () {
      const s = ProgressSettings(goal: DailyGoal(GoalKind.puzzles, 3));
      var state = ProgressState.initial;
      final reached = <bool>[];
      for (var i = 0; i < 4; i++) {
        final u = tracker.record(state, const PuzzleSolved(), day(5), s);
        reached.add(u.goalReached);
        state = u.state;
      }
      expect(reached, [false, false, true, false]);
      expect(tracker.todayProgress(state, day(5, 20), s), 4);
    });

    test('obiettivo a minuti somma la durata delle attività', () {
      const s = ProgressSettings(goal: DailyGoal(GoalKind.minutes, 10));
      final first = tracker.record(
        ProgressState.initial,
        const GamePlayed(
          result: GameResult.loss,
          duration: Duration(minutes: 6),
        ),
        day(5),
        s,
      );
      expect(first.goalReached, isFalse);
      final second = tracker.record(
        first.state,
        const PuzzleSolved(duration: Duration(minutes: 4)),
        day(5),
        s,
      );
      expect(second.goalReached, isTrue);
    });

    test('il progresso del giorno si azzera il giorno dopo', () {
      final state = playDays([5]);
      expect(tracker.todayProgress(state, day(5, 23), settings), 1);
      expect(tracker.todayProgress(state, day(6, 0), settings), 0);
    });

    test('alzare l\'obiettivo dopo averlo raggiunto non conta due volte', () {
      final first = tracker.record(
        ProgressState.initial,
        loss,
        day(5),
        settings,
      );
      const three = ProgressSettings(goal: DailyGoal(GoalKind.games, 3));
      var state = first.state;
      for (var i = 0; i < 2; i++) {
        final u = tracker.record(state, loss, day(5), three);
        expect(u.goalReached, isFalse);
        state = u.state;
      }
      expect(state.streak, 1);
    });

    test('abbassare l\'obiettivo sotto il progresso lo fa raggiungere', () {
      const three = ProgressSettings(goal: DailyGoal(GoalKind.games, 3));
      var state = tracker
          .record(ProgressState.initial, loss, day(5), three)
          .state;
      state = tracker.record(state, loss, day(5), three).state;
      final u = tracker.refreshGoal(state, day(5), settings);
      expect(u.goalReached, isTrue);
      expect(u.state.streak, 1);
      expect(
        tracker.refreshGoal(u.state, day(5), settings).goalReached,
        isFalse,
      );
    });

    test('l\'orologio che torna indietro non raddoppia il giorno', () {
      final state = playDays([6]);
      final u = tracker.record(state, loss, day(5), settings);
      expect(u.goalReached, isFalse);
      expect(u.state.streak, 1);
      expect(u.state.coveredThrough, state.coveredThrough);
    });

    test('raggiungere l\'obiettivo dà un bonus di XP', () {
      final first = tracker.record(
        ProgressState.initial,
        loss,
        day(5),
        settings,
      );
      expect(first.goalReached, isTrue);
      expect(
        first.xpGained,
        xpFor(loss) +
            dailyGoalBonusXp +
            first.challengesCompleted.length * dailyChallengeBonusXp,
      );
    });
  });

  group('RG-02 serie (streak)', () {
    test('giorni consecutivi formano la serie', () {
      final state = playDays([5, 6, 7]);
      expect(tracker.currentStreak(state, day(7)), 3);
      expect(state.bestStreak, 3);
    });

    test('la serie resta valida il giorno dopo finché non finisce', () {
      final state = playDays([5, 6]);
      expect(tracker.currentStreak(state, day(7, 22)), 2);
    });

    test('un giorno saltato senza protezioni azzera la serie', () {
      final state = playDays([5, 6, 8]);
      expect(tracker.currentStreak(state, day(8)), 1);
      expect(state.bestStreak, 2);
      expect(tracker.currentStreak(playDays([5, 6]), day(8)), 0);
    });

    test('il giorno di riposo settimanale non interrompe la serie', () {
      // Riposo il mercoledì (7 ottobre).
      const s = ProgressSettings(restDay: DateTime.wednesday);
      final state = playDays([5, 6, 8], s: s);
      expect(tracker.currentStreak(state, day(8), s), 3);
    });

    test('si guadagna un congelamento ogni 7 giorni, al massimo 2', () {
      expect(playDays([5, 6, 7, 8, 9, 10]).freezes, 0);
      expect(playDays([5, 6, 7, 8, 9, 10, 11]).freezes, 1);
      final long = playDays([for (var d = 1; d <= 28; d++) d]);
      expect(long.freezes, ProgressTracker.maxFreezes);
    });

    test('un congelamento copre un giorno saltato e viene consumato', () {
      final week = playDays([for (var d = 1; d <= 7; d++) d]);
      expect(week.freezes, 1);
      final after = tracker.record(week, loss, day(9), settings).state;
      expect(after.freezes, 0);
      expect(tracker.currentStreak(after, day(9)), 8);
    });

    test('il congelamento protegge anche solo guardando la serie', () {
      final week = playDays([for (var d = 1; d <= 7; d++) d]);
      expect(tracker.currentStreak(week, day(9)), 7);
      expect(tracker.currentStreak(week, day(10)), 0);
    });

    test('l\'orario non conta, solo il giorno di calendario', () {
      var state = tracker
          .record(ProgressState.initial, loss, day(5, 23), settings)
          .state;
      state = tracker.record(state, loss, day(6, 0), settings).state;
      expect(tracker.currentStreak(state, day(6, 1)), 2);
    });
  });

  group('RG-05 traguardi', () {
    test('prima partita e prima vittoria', () {
      final first = tracker.record(
        ProgressState.initial,
        loss,
        day(5),
        settings,
      );
      expect(first.unlocked.map((a) => a.id), contains('first_game'));
      expect(first.unlocked.map((a) => a.id), isNot(contains('first_win')));
      final second = tracker.record(first.state, win, day(5), settings);
      expect(second.unlocked.map((a) => a.id), ['first_win']);
    });

    test('un traguardo si ottiene una sola volta', () {
      final first = tracker.record(
        ProgressState.initial,
        loss,
        day(5),
        settings,
      );
      final second = tracker.record(first.state, loss, day(5), settings);
      expect(second.unlocked, isEmpty);
    });

    test('matto con il cavallo', () {
      final u = tracker.record(
        ProgressState.initial,
        const GamePlayed(result: GameResult.win, matedWith: Role.knight),
        day(5),
        settings,
      );
      expect(u.unlocked.map((a) => a.id), contains('knight_mate'));
    });

    test('arrocco lungo vincente', () {
      final u = tracker.record(
        ProgressState.initial,
        const GamePlayed(result: GameResult.win, castledLong: true),
        day(5),
        settings,
      );
      expect(u.unlocked.map((a) => a.id), contains('long_castle_win'));
    });

    test('7 giorni di fila', () {
      final state = playDays([for (var d = 1; d <= 7; d++) d]);
      expect(state.unlocked, containsAll(['streak_3', 'streak_7']));
    });

    test('identificativi unici e testi presenti', () {
      final ids = achievements.map((a) => a.id).toSet();
      expect(ids.length, achievements.length);
      for (final a in achievements) {
        expect(a.title, isNotEmpty);
        expect(a.description, isNotEmpty);
      }
    });
  });

  group('RG-12 tutto disattivabile', () {
    test('con la gamification spenta non si registra nulla', () {
      const off = ProgressSettings(enabled: false);
      final u = tracker.record(ProgressState.initial, win, day(5), off);
      expect(u.state, same(ProgressState.initial));
      expect(u.xpGained, 0);
      expect(u.unlocked, isEmpty);
      expect(u.goalReached, isFalse);
    });
  });
}
