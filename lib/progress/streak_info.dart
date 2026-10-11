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

String _days(int n) => n == 1 ? '1 giorno' : '$n giorni';

/// Descrive la serie. [streak] è la serie mostrata, [progress] l'avanzamento di
/// oggi nell'unità dell'obiettivo.
StreakInfo describeStreak({
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
  final requirement =
      'Per tenere accesa la serie, ogni giorno: '
      '${switch (goal.kind) {
        GoalKind.games => 'gioca ${goalLabel(goal)}',
        GoalKind.puzzles => 'risolvi ${goalLabel(goal)}',
        GoalKind.minutes => 'allenati per ${goalLabel(goal)}',
      }}.';
  final left = switch (goal.kind) {
    GoalKind.games =>
      missing == 1 ? 'Manca 1 partita' : 'Mancano $missing partite',
    GoalKind.puzzles =>
      missing == 1 ? 'Manca 1 puzzle' : 'Mancano $missing puzzle',
    GoalKind.minutes =>
      missing == 1 ? 'Manca 1 minuto' : 'Mancano $missing minuti',
  };
  final String today;
  final String summary;
  if (reached) {
    today = 'Oggi: fatto. La serie è al sicuro fino a domani.';
    summary = 'Oggi: fatto';
  } else if (restDayToday) {
    today = 'Oggi è il tuo giorno di riposo: la serie non si interrompe.';
    summary = 'Oggi: riposo';
  } else {
    today = 'Oggi: da fare. $left.';
    summary = 'Oggi: da fare';
  }
  final next = streakMilestones.where((m) => m > streak).firstOrNull;
  final milestone = next == null
      ? null
      : 'Prossimo traguardo: ${_days(next)} di fila '
            '(${next - streak == 1 ? 'ne manca 1' : 'ne mancano ${next - streak}'}).';
  final String ifSkipped;
  if (streak == 0) {
    ifSkipped = 'Raggiungi l\'obiettivo oggi per iniziare una serie.';
  } else if (freezes > 0) {
    ifSkipped =
        'Se salti un giorno, una protezione lo copre '
        '(ne hai $freezes). Ne guadagni una ogni 7 giorni, al massimo 2.';
  } else {
    ifSkipped =
        'Se salti un giorno, la serie riparte da zero; il record di '
        '${_days(bestStreak)} resta. Ogni 7 giorni di serie guadagni una '
        'protezione.';
  }
  return StreakInfo(
    requirement: requirement,
    today: today,
    summary: summary,
    milestone: milestone,
    ifSkipped: ifSkipped,
  );
}
