import '../review/coach.dart';
import 'week_log.dart';

/// Temi del coach che contano come errori ricorrenti: i commenti generici e i
/// complimenti non dicono cosa allenare.
final recurringErrors = {
  for (final t in CoachTheme.values)
    if (t != CoachTheme.generic && t != CoachTheme.praise) t.name,
};

/// Un errore compare nel riepilogo solo se si ripete.
const minRecurrence = 2;

/// Totali di sette giorni.
class WeekTotals {
  const WeekTotals({
    required this.games,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.puzzles,
    required this.lessons,
    required this.reviews,
    required this.seconds,
    required this.activeDays,
    required this.accuracy,
    required this.errors,
  });

  final int games;
  final int wins;
  final int draws;
  final int losses;
  final int puzzles;
  final int lessons;
  final int reviews;
  final int seconds;

  /// Giorni con almeno un'attività.
  final int activeDays;

  /// Precisione media delle revisioni, in percentuale.
  final double? accuracy;
  final Map<String, int> errors;

  int get minutes => (seconds / 60).round();

  bool get isEmpty => activeDays == 0;
}

enum AdviceKind { lesson, puzzles, reviewGame, solvePuzzles, keepGoing }

/// L'unico consiglio della settimana. [target] è l'identificativo della tappa
/// del Percorso (`lesson`) o il tema dei puzzle (`puzzles`).
class Advice {
  const Advice(this.kind, {this.target, this.error});

  final AdviceKind kind;
  final String? target;

  /// Errore (`CoachTheme.name`) che il consiglio corregge.
  final String? error;
}

/// Come correggere ogni errore: una lezione del Percorso o i puzzle di un tema.
const _fixes = <String, Advice>{
  'hangingPiece': Advice(AdviceKind.lesson, target: 'tactics.hanging'),
  'allowedFork': Advice(AdviceKind.lesson, target: 'tactics.fork'),
  'missedFork': Advice(AdviceKind.lesson, target: 'tactics.fork'),
  'allowedPin': Advice(AdviceKind.lesson, target: 'tactics.pin'),
  'missedDiscovery': Advice(AdviceKind.lesson, target: 'tactics.discovered'),
  'exposedKing': Advice(AdviceKind.lesson, target: 'openings.castle'),
  'missedMate': Advice(AdviceKind.lesson, target: 'mates.two'),
  'allowedMate': Advice(AdviceKind.puzzles, target: 'defensiveMove'),
  'materialLoss': Advice(AdviceKind.puzzles, target: 'defensiveMove'),
  'missedCapture': Advice(AdviceKind.puzzles, target: 'hangingPiece'),
};

/// Riepilogo degli ultimi sette giorni dal diario (RG-16).
class WeeklySummary {
  WeeklySummary._(
    this.week,
    this.previous,
    this.topError,
    this.topErrorCount, {
    required bool kid,
  }) {
    advice = _advise(kid: kid);
  }

  /// Con [kid] (profilo bambino, senza revisione delle partite) non si consiglia
  /// di rivederle.
  factory WeeklySummary.from(WeekLog log, DateTime now, {bool kid = false}) {
    final week = _totals(log, now, 0);
    final top = week.errors.entries
        .where((e) => recurringErrors.contains(e.key))
        .where((e) => e.value >= minRecurrence)
        .fold<MapEntry<String, int>?>(null, (best, e) {
          if (best == null || e.value > best.value) return e;
          return e.value == best.value && e.key.compareTo(best.key) < 0
              ? e
              : best;
        });
    return WeeklySummary._(
      week,
      _totals(log, now, 7),
      top?.key,
      top?.value ?? 0,
      kid: kid,
    );
  }

  final WeekTotals week;
  final WeekTotals previous;

  /// Errore ricorrente più frequente (`CoachTheme.name`), se c'è.
  final String? topError;
  final int topErrorCount;
  late final Advice advice;

  bool get isEmpty => week.isEmpty;

  /// Punti di precisione in più (o in meno) rispetto alla settimana prima.
  double? get accuracyChange {
    final now = week.accuracy;
    final before = previous.accuracy;
    return now == null || before == null ? null : now - before;
  }

  Advice _advise({required bool kid}) {
    final fix = _fixes[topError];
    if (fix != null) {
      return Advice(fix.kind, target: fix.target, error: topError);
    }
    if (!kid && week.games > 0 && week.reviews == 0) {
      return const Advice(AdviceKind.reviewGame);
    }
    if (week.puzzles == 0) return const Advice(AdviceKind.solvePuzzles);
    return const Advice(AdviceKind.keepGoing);
  }
}

/// Totali dei sette giorni che finiscono [offset] giorni prima di [now].
WeekTotals _totals(WeekLog log, DateTime now, int offset) {
  var games = 0, wins = 0, draws = 0, losses = 0;
  var puzzles = 0, lessons = 0, reviews = 0, seconds = 0;
  var activeDays = 0, accuracyCount = 0;
  var accuracySum = 0.0;
  final errors = <String, int>{};
  for (var i = offset; i < offset + 7; i++) {
    final day = log.dayOf(DateTime(now.year, now.month, now.day - i));
    if (day == null) continue;
    games += day.games;
    wins += day.wins;
    draws += day.draws;
    losses += day.losses;
    puzzles += day.puzzles;
    lessons += day.lessons;
    reviews += day.reviews;
    seconds += day.seconds;
    accuracySum += day.accuracySum;
    accuracyCount += day.accuracyCount;
    for (final e in day.errors.entries) {
      errors.update(e.key, (n) => n + e.value, ifAbsent: () => e.value);
    }
    if (day.games + day.puzzles + day.lessons + day.reviews > 0) activeDays++;
  }
  return WeekTotals(
    games: games,
    wins: wins,
    draws: draws,
    losses: losses,
    puzzles: puzzles,
    lessons: lessons,
    reviews: reviews,
    seconds: seconds,
    activeDays: activeDays,
    accuracy: accuracyCount == 0 ? null : accuracySum / accuracyCount,
    errors: errors,
  );
}
