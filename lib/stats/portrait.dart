import 'package:dartchess/dartchess.dart';

import '../archive/saved_game.dart';
import '../game/chess_game.dart';
import '../openings/opening_names.dart';
import 'stats.dart';

/// Riepilogo degli ultimi sette giorni dell'utente, calcolato dall'archivio
/// senza alcun server (proposta del capitolo 7 dei requisiti).
class PlayerPortrait {
  const PlayerPortrait._({
    required this.from,
    required this.to,
    required this.score,
    required this.openings,
    required this.accuracy,
    required this.matingPiece,
    required this.matingGames,
    required this.strongestBeaten,
    required this.busiestWeekday,
  });

  factory PlayerPortrait.from(
    Iterable<SavedGame> games, {
    required DateTime now,
    Duration window = const Duration(days: 7),
  }) {
    final since = now.subtract(window);
    final mine = [
      for (final g in games)
        if (g.mode != SavedGame.imported &&
            g.playerScore != null &&
            !g.createdAt.isBefore(since) &&
            !g.createdAt.isAfter(now))
          g,
    ];

    var score = const Score();
    final openings = <String, int>{};
    final accuracies = <double>[];
    final mates = <Role, int>{};
    final days = <int, int>{};
    int? strongest;
    for (final g in mine) {
      final points = g.playerScore!;
      score = score.add(points);
      if (g.opening case final o?) {
        final name = localOpeningName(o);
        openings[name] = (openings[name] ?? 0) + 1;
      }
      if (g.accuracy case final a?) accuracies.add(a);
      days[g.createdAt.weekday] = (days[g.createdAt.weekday] ?? 0) + 1;
      if (points == 1) {
        final elo = g.opponentElo;
        if (elo != null && (strongest == null || elo > strongest)) {
          strongest = elo;
        }
        final role = _matingRole(g);
        if (role != null) mates[role] = (mates[role] ?? 0) + 1;
      }
    }

    final topOpenings = openings.entries.toList()
      ..sort(
        (a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key),
      );
    final topMate = mates.entries.isEmpty
        ? null
        : (mates.entries.toList()..sort((a, b) {
                final byCount = b.value.compareTo(a.value);
                return byCount != 0 ? byCount : a.key.index - b.key.index;
              }))
              .first;
    final topDay = days.entries.isEmpty
        ? null
        : (days.entries.toList()..sort((a, b) {
                final byCount = b.value.compareTo(a.value);
                return byCount != 0 ? byCount : a.key.compareTo(b.key);
              }))
              .first
              .key;
    return PlayerPortrait._(
      from: since,
      to: now,
      score: score,
      openings: [
        for (final e in topOpenings.take(3)) (name: e.key, games: e.value),
      ],
      accuracy: accuracies.isEmpty
          ? null
          : accuracies.reduce((a, b) => a + b) / accuracies.length,
      matingPiece: topMate?.key,
      matingGames: mates.values.fold(0, (a, b) => a + b),
      strongestBeaten: strongest,
      busiestWeekday: topDay,
    );
  }

  final DateTime from;
  final DateTime to;
  final Score score;

  /// Fino a tre aperture, dalla più giocata.
  final List<({String name, int games})> openings;

  /// Precisione media delle partite riviste, in percentuale.
  final double? accuracy;

  /// Pezzo che ha dato più spesso il matto nelle vittorie.
  final Role? matingPiece;

  /// Vittorie concluse con un matto.
  final int matingGames;

  /// Elo del computer più forte battuto.
  final int? strongestBeaten;

  /// Giorno della settimana (`DateTime.monday`…) con più partite.
  final int? busiestWeekday;

  bool get isEmpty => score.games == 0;
}

/// Ruolo del pezzo che ha dato il matto, se la partita è finita così.
Role? _matingRole(SavedGame g) {
  final game = g.toGame();
  if (game.endReason != GameEndReason.checkmate || game.moves.isEmpty) {
    return null;
  }
  return switch (game.moves.last.san[0]) {
    'K' => Role.king,
    // L'arrocco dà matto con la torre.
    'O' => Role.rook,
    'Q' => Role.queen,
    'R' => Role.rook,
    'B' => Role.bishop,
    'N' => Role.knight,
    _ => Role.pawn,
  };
}
