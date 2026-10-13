import '../l10n/app_localizations.dart';
import 'daily_goal.dart';

/// Giorni di serie che sbloccano un traguardo (vedi `achievements.dart`).
const streakMilestones = [3, 7, 30];

/// Spiegazione della serie in parole: cosa serve ogni giorno, a che punto si è
/// oggi, il prossimo traguardo e cosa succede se si salta un giorno.
class StreakInfo {
  const StreakInfo({
    required this.requirement,
    required this.today,
    required this.summary,
    required this.milestone,
    required this.ifSkipped,
  });

  /// Cosa fare ogni giorno per far crescere la serie.
  final String requirement;

  /// Stato di oggi: fatto, da fare (con quanto manca) o riposo.
  final String today;

  /// Stato di oggi in due parole, per la scheda Tu.
  final String summary;

  /// Prossimo traguardo di serie; `null` dopo l'ultimo.
  final String? milestone;

  /// Cosa succede se si salta un giorno.
  final String ifSkipped;

  /// Tutte le frasi, nell'ordine di lettura.
  List<String> get lines => [requirement, today, ?milestone, ifSkipped];
}

/// Descrive la serie. [streak] è la serie mostrata, [progress] l'avanzamento di
/// oggi nell'unità dell'obiettivo.
StreakInfo describeStreak(
  AppLocalizations l, {
  required int streak,
  required int bestStreak,
  required int freezes,
  required DailyGoal goal,
  required int progress,
  required bool restDayToday,
}) {
  final target = goal.target;
  final reached = progress >= target;
  final missing = target - progress;
  final label = goalLabel(l, goal);
  final requirement = switch (goal.kind) {
    GoalKind.games => l.progressStreakNeedGames(label),
    GoalKind.puzzles => l.progressStreakNeedPuzzles(label),
    GoalKind.minutes => l.progressStreakNeedMinutes(label),
  };
  final left = switch (goal.kind) {
    GoalKind.games => l.progressStreakLeftGames(missing),
    GoalKind.puzzles => l.progressStreakLeftPuzzles(missing),
    GoalKind.minutes => l.progressStreakLeftMinutes(missing),
  };
  final String today;
  final String summary;
  if (reached) {
    today = l.progressStreakTodayDone;
    summary = l.progressStreakSummaryDone;
  } else if (restDayToday) {
    today = l.progressStreakTodayRest;
    summary = l.progressStreakSummaryRest;
  } else {
    today = l.progressStreakTodayTodo(left);
    summary = l.progressStreakSummaryTodo;
  }
  final next = streakMilestones.where((m) => m > streak).firstOrNull;
  final milestone = next == null
      ? null
      : l.progressStreakNext(l.progressDaysCount(next), next - streak);
  final String ifSkipped;
  if (streak == 0) {
    ifSkipped = l.progressStreakSkipNone;
  } else if (freezes > 0) {
    ifSkipped = l.progressStreakSkipFreeze(freezes);
  } else {
    ifSkipped = l.progressStreakSkipReset(l.progressDaysCount(bestStreak));
  }
  return StreakInfo(
    requirement: requirement,
    today: today,
    summary: summary,
    milestone: milestone,
    ifSkipped: ifSkipped,
  );
}
