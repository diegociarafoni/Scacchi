import 'dart:math' as math;

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
    this.onHelp,
  }) : _cap = maxRating?.toDouble(),
       _inner = RatedFeed(
         trainer,
         theme: theme,
         maxRating: maxRating?.toDouble(),
       );

  final PuzzleTrainer trainer;
  final String theme;
  final int goal;
  final RatedFeed _inner;
  final double? _cap;

  /// Chiamata a ogni puzzle concluso, con l'esito.
  final void Function(bool solved)? onOutcome;

  /// Chiamata una volta, quando dopo due errori di fila si passa a puzzle più
  /// facili.
  final void Function()? onHelp;
  int _solved = 0;
  int _failedInRow = 0;

  /// Puzzle risolti al primo tentativo in questa sessione.
  int get solved => _solved;

  /// Vero finché, dopo due errori di fila, si propongono puzzle più facili.
  bool get helping => _failedInRow >= 2;

  @override
  bool get hasNext => _solved < goal;

  @override
  Puzzle? next() {
    if (!hasNext) return null;
    if (!helping) return _inner.next();
    // 300 punti sotto il livello da cui si è inciampati, mai sotto 400.
    final level = math.min(
      _cap ?? trainer.rating.rating,
      trainer.rating.rating,
    );
    return trainer.next(theme: theme, maxRating: math.max(400, level - 300));
  }

  @override
  Future<FeedOutcome> finished(Puzzle puzzle, {required bool solved}) async {
    // Prima dell'attesa: la pagina legge hasNext subito dopo la soluzione.
    if (solved) {
      _solved++;
      _failedInRow = 0;
    } else {
      _failedInRow++;
      if (_failedInRow == 2) onHelp?.call();
    }
    final outcome = await _inner.finished(puzzle, solved: solved);
    onOutcome?.call(solved);
    return outcome;
  }
}
