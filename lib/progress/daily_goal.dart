enum GoalKind { games, puzzles, minutes }

/// Obiettivo giornaliero scelto dall'utente, per esempio 5 puzzle.
class DailyGoal {
  const DailyGoal(this.kind, this.target) : assert(target > 0);

  final GoalKind kind;
  final int target;

  /// Scelte proposte nelle impostazioni.
  static const presets = [
    DailyGoal(GoalKind.games, 1),
    DailyGoal(GoalKind.games, 3),
    DailyGoal(GoalKind.puzzles, 5),
    DailyGoal(GoalKind.minutes, 10),
    DailyGoal(GoalKind.minutes, 20),
  ];

  Map<String, Object> toJson() => {'kind': kind.name, 'target': target};

  static DailyGoal fromJson(Map<String, Object?> json) => DailyGoal(
    GoalKind.values.byName(json['kind']! as String),
    json['target']! as int,
  );

  @override
  bool operator ==(Object other) =>
      other is DailyGoal && other.kind == kind && other.target == target;

  @override
  int get hashCode => Object.hash(kind, target);
}
