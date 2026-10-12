import 'package:dartchess/dartchess.dart';

import '../progress/activity.dart';
import 'error_themes.dart';
import 'game_review.dart';
import 'move_classification.dart';
import 'personal_puzzles.dart';
import 'review_page.dart';

/// Attività registrata a revisione finita. Con due giocatori sullo stesso
/// dispositivo precisione ed errori non sono di nessuno in particolare e non
/// si registrano.
ReviewCompleted reviewActivity(
  GameReview review,
  Set<Side> players, {
  required Position initial,
  required List<Move> moves,
}) {
  final single = players.length == 1;
  return ReviewCompleted(
    accuracy: single ? review.accuracy(players.single) : null,
    brilliantMoves: [
      for (final side in players) review.count(side, MoveClass.brilliant),
    ].fold(0, (a, b) => a + b),
    gameId: gameIdOf(ReviewCache.key(initial, moves)),
    errorThemes: single ? errorThemeCounts(review, players) : const {},
  );
}
