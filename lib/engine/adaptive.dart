import 'dart:convert';
import 'dart:math' as math;

import '../storage/key_value_store.dart';
import 'levels.dart';

/// Avversario adattivo (RF-26): stima Elo del giocatore aggiornata a ogni
/// partita e livello del motore più vicino alla stima, così le vittorie
/// tendono al 50%. Vedi docs/avversario-computer.md.
class AdaptiveOpponent {
  const AdaptiveOpponent({this.rating = _startRating, this.games = 0});

  static const storeKey = 'adaptiveOpponent';

  final int rating;
  final int games;

  /// Livello con l'Elo indicativo più vicino alla stima.
  int get level => engineLevels
      .reduce(
        (a, b) =>
            (a.approxElo - rating).abs() <= (b.approxElo - rating).abs()
            ? a
            : b,
      )
      .id;

  /// Registra il punteggio del giocatore (1, 0.5, 0) contro il livello attuale.
  AdaptiveOpponent record(double score) {
    final opponent = engineLevel(level).approxElo;
    final expected = 1 / (1 + math.pow(10, (opponent - rating) / 400));
    final k = games < _provisionalGames ? 64 : 32;
    final next = (rating + k * (score - expected)).round();
    return AdaptiveOpponent(
      rating: next.clamp(_minRating, _maxRating),
      games: games + 1,
    );
  }

  static Future<AdaptiveOpponent> load(KeyValueStore store) async {
    final raw = await store.read(storeKey);
    if (raw == null) return const AdaptiveOpponent();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AdaptiveOpponent(
        rating: (json['rating'] as int).clamp(_minRating, _maxRating),
        games: json['games'] as int,
      );
    } catch (_) {
      return const AdaptiveOpponent();
    }
  }

  Future<void> save(KeyValueStore store) =>
      store.write(storeKey, jsonEncode({'rating': rating, 'games': games}));
}

const _startRating = 1100;
const _provisionalGames = 10;
const _minRating = 400;
const _maxRating = 3200;
