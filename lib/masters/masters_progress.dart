import 'dart:math';

import 'guess_run.dart';

/// Migliore percentuale di mosse indovinate per ogni partita (RF-88).
class MastersProgress {
  const MastersProgress({this.best = const {}});

  factory MastersProgress.fromJson(Map<String, dynamic> json) =>
      MastersProgress(
        best: {
          for (final e in (json['best'] as Map<String, dynamic>? ?? {}).entries)
            e.key: (e.value as num).toInt(),
        },
      );

  final Map<String, int> best;

  /// `null` se la partita non è mai stata giocata fino in fondo.
  int? bestPercent(String id) => best[id];

  /// Zero stelle se non è mai stata completata.
  int starsFor(String id) {
    final percent = best[id];
    return percent == null ? 0 : guessStars(percent);
  }

  MastersProgress record(String id, int percent) =>
      MastersProgress(best: {...best, id: max(percent, best[id] ?? 0)});

  Map<String, dynamic> toJson() => {'best': best};
}
