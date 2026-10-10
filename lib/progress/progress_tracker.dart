import 'achievements.dart';
import 'activity.dart';
import 'daily_goal.dart';
import 'progress_state.dart';
import 'xp.dart';

/// Numero del giorno di calendario locale di [time], indipendente dall'ora.
int dayNumber(DateTime time) =>
    DateTime.utc(time.year, time.month, time.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

int _weekday(int day) => DateTime.fromMillisecondsSinceEpoch(
  day * Duration.millisecondsPerDay,
  isUtc: true,
).weekday;

/// Esito di [ProgressTracker.record].
class ProgressUpdate {
  const ProgressUpdate({
    required this.state,
    this.xpGained = 0,
    this.newLevel,
    this.goalReached = false,
    this.freezeEarned = false,
    this.unlocked = const [],
  });

  final ProgressState state;
  final int xpGained;

  /// Nuovo livello, se l'attività lo ha fatto salire.
  final int? newLevel;

  /// L'obiettivo giornaliero è stato raggiunto con questa attività.
  final bool goalReached;
  final bool freezeEarned;
  final List<Achievement> unlocked;
}

/// Regole di XP, obiettivo giornaliero, serie e traguardi, senza stato proprio.
class ProgressTracker {
  static const maxFreezes = 2;

  /// Giorni della serie che fanno guadagnare un congelamento.
  static const freezeEvery = 7;

  ProgressUpdate record(
    ProgressState state,
    Activity activity,
    DateTime now,
    ProgressSettings settings,
  ) {
    if (!settings.enabled) return ProgressUpdate(state: state);
    final today = dayNumber(now);
    var s = _settle(state, today, settings);
    if (s.today != today) {
      s = s.copyWith(
        today: today,
        todayGames: 0,
        todayPuzzles: 0,
        todaySeconds: 0,
      );
    }
    final before = _progress(s, settings.goal);
    s = _count(s, activity);
    final goalReached =
        before < settings.goal.target &&
        _progress(s, settings.goal) >= settings.goal.target;

    var xp = xpFor(activity);
    var freezeEarned = false;
    if (goalReached) {
      xp += dailyGoalBonusXp;
      final streak = s.streak + 1;
      freezeEarned = streak % freezeEvery == 0 && s.freezes < maxFreezes;
      s = s.copyWith(
        streak: streak,
        bestStreak: streak > s.bestStreak ? streak : s.bestStreak,
        freezes: s.freezes + (freezeEarned ? 1 : 0),
        coveredThrough: () => today,
      );
    }
    final oldLevel = levelForXp(s.xp);
    s = s.copyWith(xp: s.xp + xp);
    final level = levelForXp(s.xp);

    final unlocked = [
      for (final a in achievements)
        if (!s.unlocked.contains(a.id) && a.test(s, activity)) a,
    ];
    if (unlocked.isNotEmpty) {
      s = s.copyWith(unlocked: [...s.unlocked, for (final a in unlocked) a.id]);
    }
    return ProgressUpdate(
      state: s,
      xpGained: xp,
      newLevel: level > oldLevel ? level : null,
      goalReached: goalReached,
      freezeEarned: freezeEarned,
      unlocked: unlocked,
    );
  }

  /// Serie valida a [now], tenendo conto di riposi e congelamenti.
  int currentStreak(
    ProgressState state,
    DateTime now, [
    ProgressSettings settings = const ProgressSettings(),
  ]) => _settle(state, dayNumber(now), settings).streak;

  /// Congelamenti rimasti a [now] dopo aver coperto i giorni saltati.
  int currentFreezes(
    ProgressState state,
    DateTime now, [
    ProgressSettings settings = const ProgressSettings(),
  ]) => _settle(state, dayNumber(now), settings).freezes;

  /// Avanzamento verso l'obiettivo di oggi, nell'unità dell'obiettivo.
  int todayProgress(
    ProgressState state,
    DateTime now,
    ProgressSettings settings,
  ) => state.today == dayNumber(now) ? _progress(state, settings.goal) : 0;

  /// Copre i giorni tra l'ultimo coperto e ieri con riposi o congelamenti;
  /// se non basta, la serie si azzera.
  ProgressState _settle(ProgressState s, int today, ProgressSettings settings) {
    final from = s.coveredThrough;
    if (from == null || from >= today - 1) return s;
    var freezes = s.freezes;
    for (var d = from + 1; d < today; d++) {
      if (_weekday(d) == settings.restDay) continue;
      if (freezes == 0) {
        return s.copyWith(streak: 0, coveredThrough: () => null);
      }
      freezes--;
    }
    return s.copyWith(freezes: freezes, coveredThrough: () => today - 1);
  }

  int _progress(ProgressState s, DailyGoal goal) => switch (goal.kind) {
    GoalKind.games => s.todayGames,
    GoalKind.puzzles => s.todayPuzzles,
    GoalKind.minutes => s.todaySeconds ~/ 60,
  };

  ProgressState _count(ProgressState s, Activity a) {
    s = s.copyWith(todaySeconds: s.todaySeconds + a.duration.inSeconds);
    return switch (a) {
      GamePlayed(:final result) => s.copyWith(
        gamesPlayed: s.gamesPlayed + 1,
        todayGames: s.todayGames + 1,
        wins: s.wins + (result == GameResult.win ? 1 : 0),
        draws: s.draws + (result == GameResult.draw ? 1 : 0),
      ),
      PuzzleSolved() => s.copyWith(
        puzzlesSolved: s.puzzlesSolved + 1,
        todayPuzzles: s.todayPuzzles + 1,
      ),
      LessonCompleted() => s.copyWith(lessonsCompleted: s.lessonsCompleted + 1),
      ReviewCompleted() => s.copyWith(reviewsCompleted: s.reviewsCompleted + 1),
    };
  }
}
