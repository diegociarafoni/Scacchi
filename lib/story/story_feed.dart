import '../puzzles/puzzle.dart';
import '../puzzles/puzzle_feed.dart';
import '../puzzles/puzzle_trainer.dart';

/// Puzzle di un tema finché non ne sono stati risolti [goal] al primo
/// tentativo. Si registrano come gli altri puzzle (punteggio e XP).
class StoryPuzzleFeed implements PuzzleFeed {
  StoryPuzzleFeed(this.trainer, {required this.theme, required this.goal})
    : _inner = RatedFeed(trainer, theme: theme);

  final PuzzleTrainer trainer;
  final String theme;
  final int goal;
  final RatedFeed _inner;
  int _solved = 0;

  /// Puzzle risolti al primo tentativo in questa sessione.
  int get solved => _solved;

  @override
  bool get hasNext => _solved < goal;

  @override
  Puzzle? next() => hasNext ? _inner.next() : null;

  @override
  Future<FeedOutcome> finished(Puzzle puzzle, {required bool solved}) async {
    final outcome = await _inner.finished(puzzle, solved: solved);
    if (solved) _solved++;
    return outcome;
  }
}
