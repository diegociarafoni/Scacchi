import 'dart:math' as math;

import '../archive/saved_game.dart';

/// Rating locale stimato contro il computer (RF-110), ricalcolato
/// dall'archivio con la formula Elo: nessuno stato da salvare.
class LocalRating {
  const LocalRating({required this.rating, required this.history});

  static const initial = 800;

  /// Partite oltre le quali il rating non è più provvisorio.
  static const provisionalGames = 10;

  factory LocalRating.from(Iterable<SavedGame> games) {
    final rated = [
      for (final g in games)
        if (g.mode != SavedGame.imported &&
            g.opponentElo != null &&
            g.playerScore != null)
          g,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    var rating = initial.toDouble();
    final history = <(DateTime, int)>[];
    for (final (i, g) in rated.indexed) {
      final expected = 1 / (1 + math.pow(10, (g.opponentElo! - rating) / 400));
      // K più alto all'inizio, per avvicinarsi presto al livello reale.
      final k = i < provisionalGames ? 40 : 20;
      rating += k * (g.playerScore! - expected);
      history.add((g.createdAt, rating.round()));
    }
    return LocalRating(rating: rating.round(), history: history);
  }

  final int rating;

  /// Rating dopo ogni partita, in ordine di data.
  final List<(DateTime, int)> history;

  bool get provisional => history.length < provisionalGames;
}
