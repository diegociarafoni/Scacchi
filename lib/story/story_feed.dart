import '../puzzles/puzzle.dart';
import '../puzzles/puzzle_feed.dart';
import '../puzzles/puzzle_trainer.dart';

/// Puzzle di un tema finché non ne sono stati risolti [goal] al primo
/// tentativo. Si registrano come gli altri puzzle (punteggio e XP).
class StoryPuzzleFeed implements PuzzleFeed {
  StoryPuzzleFeed(
    this.trainer, {
    required this.theme,
    required this.goal,
    int? maxRating,
    this.onOutcome,
  }) : _inner = RatedFeed(
         trainer,
         theme: theme,
         maxRating: maxRating?.toDouble(),
       );

  final PuzzleTrainer trainer;
  final String theme;
  final int goal;
  final RatedFeed _inner;

  /// Chiamata a ogni puzzle concluso, con l'esito.
  final void Function(bool solved)? onOutcome;
  int _solved = 0;

  /// Puzzle risolti al primo tentativo in questa sessione.
  int get solved => _solved;

  @override
  bool get hasNext => _solved < goal;

  @override
  Puzzle? next() => hasNext ? _inner.next() : null;

  @override
  Future<FeedOutcome> finished(Puzzle puzzle, {required bool solved}) async {
    // Prima dell'attesa: la pagina legge hasNext subito dopo la soluzione.
    if (solved) _solved++;
    final outcome = await _inner.finished(puzzle, solved: solved);
    onOutcome?.call(solved);
    return outcome;
  }
}
