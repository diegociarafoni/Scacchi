import 'package:dartchess/dartchess.dart';

import '../archive/saved_game.dart';
import '../openings/opening_names.dart';
import '../review/game_phase.dart';

/// Vittorie, patte e sconfitte.
class Score {
  const Score({this.wins = 0, this.draws = 0, this.losses = 0});

  final int wins;
  final int draws;
  final int losses;

  int get games => wins + draws + losses;

  /// Percentuale di punti, o `null` senza partite.
  double? get percent => games == 0 ? null : 100 * (wins + draws / 2) / games;

  Score add(double points) => Score(
    wins: wins + (points == 1 ? 1 : 0),
    draws: draws + (points == 0.5 ? 1 : 0),
    losses: losses + (points == 0 ? 1 : 0),
  );

  @override
  bool operator ==(Object other) =>
      other is Score &&
      other.wins == wins &&
      other.draws == draws &&
      other.losses == losses;

  @override
  int get hashCode => Object.hash(wins, draws, losses);

  @override
  String toString() => '+$wins =$draws -$losses';
}

/// Chiave neutra delle partite senza orologio: la pagina la traduce.
const noClock = '';

/// Statistiche calcolate dall'archivio (RF-111).
class GameStats {
  const GameStats({
    required this.all,
    required this.byColor,
    required this.byTimeControl,
    required this.localGames,
    required this.openings,
    required this.accuracyTrend,
    this.phaseTrends = const {},
  });

  /// Considera le partite concluse con un colore dell'utente; le importate
  /// non sono dell'utente e restano fuori.
  factory GameStats.from(Iterable<SavedGame> games) {
    var all = const Score();
    final byColor = <Side, Score>{};
    final byTc = <String, Score>{};
    final openings = <String, int>{};
    final trend = <(DateTime, double)>[];
    final phases = {
      for (final p in GamePhase.values) p: <(DateTime, double)>[],
    };
    var local = 0;
    for (final g in games) {
      if (g.mode == SavedGame.imported || !g.finished) continue;
      if (g.mode == SavedGame.local) {
        local++;
        continue;
      }
      final points = g.playerScore;
      if (points == null) continue;
      all = all.add(points);
      byColor[g.playerSide!] = (byColor[g.playerSide!] ?? const Score()).add(
        points,
      );
      final tc = g.timeControl ?? noClock;
      byTc[tc] = (byTc[tc] ?? const Score()).add(points);
      if (g.opening case final o?) {
        final name = localOpeningName(o);
        openings[name] = (openings[name] ?? 0) + 1;
      }
      if (g.accuracy case final a?) trend.add((g.createdAt, a));
      for (final e
          in (g.phaseAccuracy ?? const <GamePhase, double>{}).entries) {
        phases[e.key]!.add((g.createdAt, e.value));
      }
    }
    trend.sort((a, b) => a.$1.compareTo(b.$1));
    for (final list in phases.values) {
      list.sort((a, b) => a.$1.compareTo(b.$1));
    }
    final sortedOpenings = openings.entries.toList()..sort(_byCountThenName);
    final sortedTc = byTc.entries.toList()
      ..sort((a, b) {
        final byGames = b.value.games.compareTo(a.value.games);
        if (byGames != 0) return byGames;
        // Senza orologio in fondo, a pari partite.
        if (a.key == noClock || b.key == noClock) {
          return a.key == noClock ? 1 : -1;
        }
        return a.key.compareTo(b.key);
      });
    return GameStats(
      all: all,
      byColor: byColor,
      byTimeControl: Map.fromEntries(sortedTc),
      localGames: local,
      openings: [for (final e in sortedOpenings) (name: e.key, games: e.value)],
      accuracyTrend: trend,
      phaseTrends: phases,
    );
  }

  final Score all;
  final Map<Side, Score> byColor;

  /// Bilancio per cadenza, dalla più giocata.
  final Map<String, Score> byTimeControl;

  /// Partite tra due persone sullo stesso dispositivo.
  final int localGames;

  /// Aperture dalla più giocata.
  final List<({String name, int games})> openings;

  /// Precisione per partita in ordine di data.
  final List<(DateTime, double)> accuracyTrend;

  /// Precisione per partita in ciascuna fase (RF-68), in ordine di data.
  final Map<GamePhase, List<(DateTime, double)>> phaseTrends;

  List<(DateTime, double)> phaseTrend(GamePhase phase) =>
      phaseTrends[phase] ?? const [];

  /// Media della precisione nella fase, o `null` senza dati.
  double? phaseAverage(GamePhase phase) {
    final trend = phaseTrend(phase);
    return trend.isEmpty
        ? null
        : trend.fold(0.0, (s, p) => s + p.$2) / trend.length;
  }

  double? get averageAccuracy => accuracyTrend.isEmpty
      ? null
      : accuracyTrend.fold(0.0, (s, p) => s + p.$2) / accuracyTrend.length;
}

int _byCountThenName(MapEntry<String, int> a, MapEntry<String, int> b) {
  final byCount = b.value.compareTo(a.value);
  return byCount != 0 ? byCount : a.key.compareTo(b.key);
}
