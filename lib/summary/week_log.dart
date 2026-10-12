import 'dart:io';

import '../progress/activity.dart';
import '../storage/json_file.dart';

/// Conteggi di un giorno: nessuna mossa, posizione o nome, solo numeri.
class DayLog {
  const DayLog({
    this.games = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.puzzles = 0,
    this.lessons = 0,
    this.reviews = 0,
    this.seconds = 0,
    this.accuracySum = 0,
    this.accuracyCount = 0,
    this.errors = const {},
    this.reviewedGames = const [],
  });

  factory DayLog.fromJson(Map<String, Object?> json) => DayLog(
    games: json['games'] as int? ?? 0,
    wins: json['wins'] as int? ?? 0,
    draws: json['draws'] as int? ?? 0,
    losses: json['losses'] as int? ?? 0,
    puzzles: json['puzzles'] as int? ?? 0,
    lessons: json['lessons'] as int? ?? 0,
    reviews: json['reviews'] as int? ?? 0,
    seconds: json['seconds'] as int? ?? 0,
    accuracySum: (json['accuracySum'] as num?)?.toDouble() ?? 0,
    accuracyCount: json['accuracyCount'] as int? ?? 0,
    errors: {
      for (final e in ((json['errors'] as Map?) ?? const {}).entries)
        e.key as String: e.value as int,
    },
    reviewedGames: [
      for (final id in (json['reviewedGames'] as List?) ?? const [])
        id as String,
    ],
  );

  final int games;
  final int wins;
  final int draws;
  final int losses;
  final int puzzles;
  final int lessons;
  final int reviews;

  /// Secondi di allenamento.
  final int seconds;
  final double accuracySum;
  final int accuracyCount;

  /// Errori per tema del coach (`CoachTheme.name`).
  final Map<String, int> errors;

  /// Partite già riviste in questo giorno, per non contarle due volte.
  final List<String> reviewedGames;

  DayLog copyWith({
    int? games,
    int? wins,
    int? draws,
    int? losses,
    int? puzzles,
    int? lessons,
    int? reviews,
    int? seconds,
    double? accuracySum,
    int? accuracyCount,
    Map<String, int>? errors,
    List<String>? reviewedGames,
  }) => DayLog(
    games: games ?? this.games,
    wins: wins ?? this.wins,
    draws: draws ?? this.draws,
    losses: losses ?? this.losses,
    puzzles: puzzles ?? this.puzzles,
    lessons: lessons ?? this.lessons,
    reviews: reviews ?? this.reviews,
    seconds: seconds ?? this.seconds,
    accuracySum: accuracySum ?? this.accuracySum,
    accuracyCount: accuracyCount ?? this.accuracyCount,
    errors: errors ?? this.errors,
    reviewedGames: reviewedGames ?? this.reviewedGames,
  );

  Map<String, Object?> toJson() => {
    'games': games,
    'wins': wins,
    'draws': draws,
    'losses': losses,
    'puzzles': puzzles,
    'lessons': lessons,
    'reviews': reviews,
    'seconds': seconds,
    'accuracySum': accuracySum,
    'accuracyCount': accuracyCount,
    'errors': errors,
    'reviewedGames': reviewedGames,
  };
}

/// Diario degli ultimi giorni, per il riepilogo settimanale (RG-16).
class WeekLog {
  const WeekLog([this.days = const {}]);

  factory WeekLog.fromJson(Map<String, Object?> json) => WeekLog({
    for (final e in ((json['days'] as Map?) ?? const {}).entries)
      int.parse(e.key as String): DayLog.fromJson(
        (e.value as Map).cast<String, Object?>(),
      ),
  });

  /// Giorni di storia da tenere: la settimana corrente e la precedente.
  static const keptDays = 14;

  /// Conteggi per giorno, con chiave `aaaammgg`.
  final Map<int, DayLog> days;

  bool get isEmpty => days.isEmpty;

  /// Chiave del giorno di [date] nel calendario locale.
  static int keyOf(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  DayLog? dayOf(DateTime date) => days[keyOf(date)];

  /// Diario con [activity] aggiunta al giorno di [now].
  WeekLog record(Activity activity, DateTime now) {
    final key = keyOf(now);
    final day = days[key] ?? const DayLog();
    final DayLog next;
    switch (activity) {
      case GamePlayed(result: GameResult.local):
        return this;
      case GamePlayed(:final result):
        next = day.copyWith(
          games: day.games + 1,
          wins: day.wins + (result == GameResult.win ? 1 : 0),
          draws: day.draws + (result == GameResult.draw ? 1 : 0),
          losses: day.losses + (result == GameResult.loss ? 1 : 0),
          seconds: day.seconds + activity.duration.inSeconds,
        );
      case PuzzleSolved():
        next = day.copyWith(
          puzzles: day.puzzles + 1,
          seconds: day.seconds + activity.duration.inSeconds,
        );
      case LessonCompleted():
        next = day.copyWith(
          lessons: day.lessons + 1,
          seconds: day.seconds + activity.duration.inSeconds,
        );
      case ReviewCompleted(:final gameId, :final accuracy, :final errorThemes):
        if (gameId != null &&
            days.values.any((d) => d.reviewedGames.contains(gameId))) {
          return this;
        }
        final errors = {...day.errors};
        for (final e in errorThemes.entries) {
          errors.update(e.key, (n) => n + e.value, ifAbsent: () => e.value);
        }
        next = day.copyWith(
          reviews: day.reviews + 1,
          accuracySum: day.accuracySum + (accuracy ?? 0),
          accuracyCount: day.accuracyCount + (accuracy == null ? 0 : 1),
          errors: errors,
          reviewedGames: [...day.reviewedGames, ?gameId],
        );
      default:
        return this;
    }
    return WeekLog(_pruned({...days, key: next}, now));
  }

  static Map<int, DayLog> _pruned(Map<int, DayLog> days, DateTime now) {
    final oldest = keyOf(
      DateTime(now.year, now.month, now.day - (keptDays - 1)),
    );
    return {
      for (final e in days.entries)
        if (e.key >= oldest) e.key: e.value,
    };
  }

  Map<String, Object?> toJson() => {
    'days': {for (final e in days.entries) '${e.key}': e.value.toJson()},
  };
}

/// Salvataggio locale del diario in un file JSON (vedi [JsonFile]).
class WeekLogStore {
  WeekLogStore(File file) : _file = JsonFile(file, version: 1);

  final JsonFile _file;

  /// Diario salvato, o vuoto se il file manca o non è valido.
  Future<WeekLog> load() async =>
      await _file.read(WeekLog.fromJson) ?? const WeekLog();

  Future<void> save(WeekLog log) => _file.write(log.toJson());
}
