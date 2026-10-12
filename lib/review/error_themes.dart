import 'package:dartchess/dartchess.dart';

import 'coach.dart';
import 'game_review.dart';

/// Errori di [players] in [review] contati per tema del coach
/// (`CoachTheme.name`). I commenti generici non dicono cosa allenare e
/// restano fuori.
Map<String, int> errorThemeCounts(GameReview review, Set<Side> players) {
  final counts = <String, int>{};
  for (final m in review.moves) {
    if (!players.contains(m.side) || !m.classification.isError) continue;
    final comment = explainMove(
      m,
      previous: m.ply > 0 ? review.moves[m.ply - 1] : null,
    );
    if (comment == null || comment.theme == CoachTheme.generic) continue;
    counts.update(comment.theme.name, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
}
