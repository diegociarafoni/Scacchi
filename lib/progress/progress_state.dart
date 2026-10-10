import 'dart:convert';

import 'daily_goal.dart';

/// Preferenze della gamification.
class ProgressSettings {
  const ProgressSettings({
    this.enabled = true,
    this.goal = const DailyGoal(GoalKind.games, 1),
    this.restDay,
  });

  /// Interruttore generale: spento, non si registra nulla e il profilo è nascosto.
  final bool enabled;
  final DailyGoal goal;

  /// Giorno di riposo settimanale ([DateTime.monday]..[DateTime.sunday]) che
  /// non interrompe la serie; `null` se non previsto.
  final int? restDay;

  ProgressSettings copyWith({
    bool? enabled,
    DailyGoal? goal,
    int? Function()? restDay,
  }) => ProgressSettings(
    enabled: enabled ?? this.enabled,
    goal: goal ?? this.goal,
    restDay: restDay == null ? this.restDay : restDay(),
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'goal': goal.toJson(),
    'restDay': restDay,
  };

  static ProgressSettings fromJson(Map<String, Object?> json) =>
      ProgressSettings(
        enabled: json['enabled'] as bool? ?? true,
        goal: json['goal'] == null
            ? const DailyGoal(GoalKind.games, 1)
            : DailyGoal.fromJson((json['goal']! as Map).cast()),
        restDay: json['restDay'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      other is ProgressSettings &&
      other.enabled == enabled &&
      other.goal == goal &&
      other.restDay == restDay;

  @override
  int get hashCode => Object.hash(enabled, goal, restDay);
}

/// Progressi del giocatore. I giorni sono numeri di giorno di calendario
/// locale (vedi `dayNumber`).
class ProgressState {
  const ProgressState({
    this.xp = 0,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.draws = 0,
    this.puzzlesSolved = 0,
    this.lessonsCompleted = 0,
    this.reviewsCompleted = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.freezes = 0,
    this.coveredThrough,
    this.today,
    this.todayGames = 0,
    this.todayPuzzles = 0,
    this.todaySeconds = 0,
    this.unlocked = const [],
  });

  static const initial = ProgressState();

  final int xp;
  final int gamesPlayed;
  final int wins;
  final int draws;
  final int puzzlesSolved;
  final int lessonsCompleted;
  final int reviewsCompleted;

  /// Giorni con l'obiettivo raggiunto nella serie in corso.
  final int streak;
  final int bestStreak;

  /// Protezioni della serie disponibili.
  final int freezes;

  /// Ultimo giorno già coperto dalla serie (obiettivo, riposo o congelamento).
  final int? coveredThrough;

  /// Giorno a cui si riferiscono i contatori `today*`.
  final int? today;
  final int todayGames;
  final int todayPuzzles;
  final int todaySeconds;

  /// Identificativi dei traguardi ottenuti, in ordine di sblocco.
  final List<String> unlocked;

  ProgressState copyWith({
    int? xp,
    int? gamesPlayed,
    int? wins,
    int? draws,
    int? puzzlesSolved,
    int? lessonsCompleted,
    int? reviewsCompleted,
    int? streak,
    int? bestStreak,
    int? freezes,
    int? Function()? coveredThrough,
    int? today,
    int? todayGames,
    int? todayPuzzles,
    int? todaySeconds,
    List<String>? unlocked,
  }) => ProgressState(
    xp: xp ?? this.xp,
    gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    wins: wins ?? this.wins,
    draws: draws ?? this.draws,
    puzzlesSolved: puzzlesSolved ?? this.puzzlesSolved,
    lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
    reviewsCompleted: reviewsCompleted ?? this.reviewsCompleted,
    streak: streak ?? this.streak,
    bestStreak: bestStreak ?? this.bestStreak,
    freezes: freezes ?? this.freezes,
    coveredThrough: coveredThrough == null
        ? this.coveredThrough
        : coveredThrough(),
    today: today ?? this.today,
    todayGames: todayGames ?? this.todayGames,
    todayPuzzles: todayPuzzles ?? this.todayPuzzles,
    todaySeconds: todaySeconds ?? this.todaySeconds,
    unlocked: unlocked ?? this.unlocked,
  );

  Map<String, Object?> toJson() => {
    'xp': xp,
    'gamesPlayed': gamesPlayed,
    'wins': wins,
    'draws': draws,
    'puzzlesSolved': puzzlesSolved,
    'lessonsCompleted': lessonsCompleted,
    'reviewsCompleted': reviewsCompleted,
    'streak': streak,
    'bestStreak': bestStreak,
    'freezes': freezes,
    'coveredThrough': coveredThrough,
    'today': today,
    'todayGames': todayGames,
    'todayPuzzles': todayPuzzles,
    'todaySeconds': todaySeconds,
    'unlocked': unlocked,
  };

  static ProgressState fromJson(Map<String, Object?> json) {
    int n(String key) => json[key] as int? ?? 0;
    return ProgressState(
      xp: n('xp'),
      gamesPlayed: n('gamesPlayed'),
      wins: n('wins'),
      draws: n('draws'),
      puzzlesSolved: n('puzzlesSolved'),
      lessonsCompleted: n('lessonsCompleted'),
      reviewsCompleted: n('reviewsCompleted'),
      streak: n('streak'),
      bestStreak: n('bestStreak'),
      freezes: n('freezes'),
      coveredThrough: json['coveredThrough'] as int?,
      today: json['today'] as int?,
      todayGames: n('todayGames'),
      todayPuzzles: n('todayPuzzles'),
      todaySeconds: n('todaySeconds'),
      unlocked: [...(json['unlocked'] as List? ?? const []).cast<String>()],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProgressState &&
      jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}
