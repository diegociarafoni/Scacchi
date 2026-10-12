import '../badges/badge_def.dart';
import '../badges/badge_sources.dart';
import 'achievements.dart';
import 'activity.dart';
import 'challenges.dart';
import 'daily_goal.dart';
import 'progress_state.dart';
import 'records.dart';
import 'rewards.dart';
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
    this.challengesCompleted = const [],
    this.weeklyCompleted = false,
    this.newRecords = const [],
    this.rewards = const [],
  });

  final ProgressState state;
  final int xpGained;

  /// Nuovo livello, se l'attività lo ha fatto salire.
  final int? newLevel;

  /// L'obiettivo giornaliero è stato raggiunto con questa attività.
  final bool goalReached;
  final bool freezeEarned;
  final List<Achievement> unlocked;

  /// Sfide giornaliere completate con questa attività.
  final List<Challenge> challengesCompleted;
  final bool weeklyCompleted;
  final List<RecordKind> newRecords;

  /// Ricompense estetiche sbloccate con questa attività (vedi `rewards.dart`).
  final List<Enum> rewards;
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
    ProgressSettings settings, [
    BadgeSources sources = BadgeSources.empty,
  ]) {
    if (!settings.enabled) return ProgressUpdate(state: state);
    final s = _count(_startDay(state, now, settings), activity);
    return _finish(
      _markActive(s, state.lastActiveDay),
      state.xp,
      xpFor(activity),
      activity,
      settings,
      sources,
    );
  }

  /// Badge che gli avanzamenti degli altri salvataggi fanno ottenere; lo
  /// stato è lo stesso oggetto se non cambia nulla.
  ProgressState refreshBadges(
    ProgressState state,
    DateTime now,
    ProgressSettings settings,
    BadgeSources sources,
  ) {
    if (!settings.enabled) return state;
    return _unlockBadges(state, sources, _day(state, now));
  }

  /// Riconosce l'obiettivo di oggi già raggiunto, per esempio dopo averlo
  /// abbassato sotto il progresso del giorno.
  ProgressUpdate refreshGoal(
    ProgressState state,
    DateTime now,
    ProgressSettings settings,
  ) {
    if (!settings.enabled) return ProgressUpdate(state: state);
    return _finish(
      _startDay(state, now, settings),
      state.xp,
      0,
      null,
      settings,
    );
  }

  ProgressUpdate _finish(
    ProgressState s,
    int oldXp,
    int xp,
    Activity? activity,
    ProgressSettings settings, [
    BadgeSources sources = BadgeSources.empty,
  ]) {
    final start = s;
    final today = s.today!;
    final goalReached =
        s.coveredThrough != today &&
        _progress(s, settings.goal) >= settings.goal.target;
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

    final daily = dailyChallenges(today);
    final dailyProgress = s.challengeDay == today
        ? [...s.dailyProgress]
        : List.filled(daily.length, 0);
    final completed = <Challenge>[];
    for (final (i, c) in daily.indexed) {
      final before = dailyProgress[i];
      dailyProgress[i] += _advance(c.kind, activity, goalReached);
      if (before < c.target && dailyProgress[i] >= c.target) completed.add(c);
    }
    final allDone = daily.indexed.every(
      (e) => dailyProgress[e.$1] >= e.$2.target,
    );
    xp += completed.length * dailyChallengeBonusXp;

    final week = weekNumber(today);
    final weekly = weeklyChallenge(week);
    final weeklyBefore = s.challengeWeek == week ? s.weeklyProgress : 0;
    final weeklyAfter =
        weeklyBefore + _advance(weekly.kind, activity, goalReached);
    final weeklyCompleted =
        weeklyBefore < weekly.target && weeklyAfter >= weekly.target;
    if (weeklyCompleted) xp += weeklyChallengeBonusXp;

    var records = s.records;
    var newRecords = const <RecordKind>[];
    if (activity != null) (records, newRecords) = records.apply(activity);

    s = s.copyWith(
      xp: s.xp + xp,
      challengeDay: today,
      dailyProgress: dailyProgress,
      challengesCompleted: s.challengesCompleted + completed.length,
      perfectDays: s.perfectDays + (allDone && completed.isNotEmpty ? 1 : 0),
      challengeWeek: week,
      weeklyProgress: weeklyAfter,
      records: records,
    );
    final oldLevel = levelForXp(oldXp);
    final level = levelForXp(s.xp);

    final unlocked = [
      for (final a in achievements)
        if (!s.unlocked.contains(a.id) && a.test(s, activity)) a,
    ];
    if (unlocked.isNotEmpty) {
      s = s.copyWith(unlocked: [...s.unlocked, for (final a in unlocked) a.id]);
    }
    s = _unlockBadges(s, sources, today);
    return ProgressUpdate(
      state: s,
      xpGained: xp,
      newLevel: level > oldLevel ? level : null,
      goalReached: goalReached,
      freezeEarned: freezeEarned,
      unlocked: unlocked,
      challengesCompleted: completed,
      weeklyCompleted: weeklyCompleted,
      newRecords: newRecords,
      // Con "Sblocca tutto" le ricompense erano già disponibili.
      rewards: settings.unlockAll ? const [] : newRewards(start, s),
    );
  }

  ProgressState _unlockBadges(ProgressState s, BadgeSources sources, int day) {
    final facts = BadgeFacts(s, sources);
    final earned = [
      for (final b in badges)
        if (!s.badges.containsKey(b.id) && b.isMet(facts)) b.id,
    ];
    if (earned.isEmpty) return s;
    return s.copyWith(badges: {...s.badges, for (final id in earned) id: day});
  }

  /// Conta il giorno di gioco e un eventuale ritorno dopo una lunga pausa.
  ProgressState _markActive(ProgressState s, int? lastActive) {
    final today = s.today!;
    if (lastActive != null && today <= lastActive) return s;
    final tally = {...s.tally};
    tally['days'] = (tally['days'] ?? 0) + 1;
    if (lastActive != null && today - lastActive >= comebackDays) {
      tally['comeback'] = (tally['comeback'] ?? 0) + 1;
    }
    return s.copyWith(tally: tally, lastActiveDay: today);
  }

  int _advance(ChallengeKind kind, Activity? activity, bool goalReached) {
    if (kind == ChallengeKind.goalDays) return goalReached ? 1 : 0;
    return activity == null ? 0 : kind.advance(activity);
  }

  /// Sfide di oggi con il relativo avanzamento.
  List<(Challenge, int)> challengeProgress(ProgressState state, DateTime now) {
    final today = _day(state, now);
    final daily = dailyChallenges(today);
    return [
      for (final (i, c) in daily.indexed)
        (c, state.challengeDay == today ? state.dailyProgress[i] : 0),
    ];
  }

  /// Sfida della settimana con il relativo avanzamento.
  (Challenge, int) weeklyProgress(ProgressState state, DateTime now) {
    final week = weekNumber(_day(state, now));
    return (
      weeklyChallenge(week),
      state.challengeWeek == week ? state.weeklyProgress : 0,
    );
  }

  /// Giorno di [now]; se l'orologio torna indietro resta il giorno già visto.
  int _day(ProgressState state, DateTime now) {
    final day = dayNumber(now);
    final seen = state.today;
    return seen != null && seen > day ? seen : day;
  }

  ProgressState _startDay(
    ProgressState state,
    DateTime now,
    ProgressSettings settings,
  ) {
    final today = _day(state, now);
    final s = _settle(state, today, settings);
    if (s.today == today) return s;
    return s.copyWith(
      today: today,
      todayGames: 0,
      todayPuzzles: 0,
      todaySeconds: 0,
    );
  }

  /// Serie valida a [now], tenendo conto di riposi e congelamenti.
  int currentStreak(
    ProgressState state,
    DateTime now, [
    ProgressSettings settings = const ProgressSettings(),
  ]) => _settle(state, _day(state, now), settings).streak;

  /// Congelamenti rimasti a [now] dopo aver coperto i giorni saltati.
  int currentFreezes(
    ProgressState state,
    DateTime now, [
    ProgressSettings settings = const ProgressSettings(),
  ]) => _settle(state, _day(state, now), settings).freezes;

  /// Avanzamento verso l'obiettivo di oggi, nell'unità dell'obiettivo.
  int todayProgress(
    ProgressState state,
    DateTime now,
    ProgressSettings settings,
  ) => state.today == _day(state, now) ? _progress(state, settings.goal) : 0;

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
      GamePlayed(:final result, :final matedWith, :final highlights) =>
        s.copyWith(
          gamesPlayed: s.gamesPlayed + 1,
          todayGames: s.todayGames + 1,
          wins: s.wins + (result == GameResult.win ? 1 : 0),
          draws: s.draws + (result == GameResult.draw ? 1 : 0),
          tally: _bump(s.tally, [
            for (final h in highlights) 'game:${h.name}',
            if (result == GameResult.win && matedWith != null)
              mateKey(matedWith),
          ]),
        ),
      PuzzleSolved(:final themes) => s.copyWith(
        puzzlesSolved: s.puzzlesSolved + 1,
        todayPuzzles: s.todayPuzzles + 1,
        puzzleThemes: {
          ...s.puzzleThemes,
          for (final t in themes) t: (s.puzzleThemes[t] ?? 0) + 1,
        },
      ),
      PuzzleRunFinished() => s,
      MinigameFinished(:final score) =>
        score > 0 ? s.copyWith(tally: _bump(s.tally, ['minigames'])) : s,
      TournamentFinished(:final rank, :final players) => s.copyWith(
        tally: _bump(s.tally, [
          'tournaments',
          if (rank <= 3 && players >= podiumMinPlayers) 'podium',
        ]),
      ),
      LessonCompleted() => s.copyWith(lessonsCompleted: s.lessonsCompleted + 1),
      ReviewCompleted(:final brilliantMoves) => s.copyWith(
        reviewsCompleted: s.reviewsCompleted + 1,
        brilliantFound: s.brilliantFound + brilliantMoves,
      ),
    };
  }
}

Map<String, int> _bump(Map<String, int> tally, Iterable<String> keys) => {
  ...tally,
  for (final k in keys) k: (tally[k] ?? 0) + 1,
};
