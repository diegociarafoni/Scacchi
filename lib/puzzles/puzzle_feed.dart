import 'puzzle.dart';
import 'puzzle_trainer.dart';

/// Esito registrato: variazione di punteggio, se c'è, e diritto agli XP.
typedef FeedOutcome = ({double? ratingDelta, bool awardXp});

/// Sorgente dei puzzle di una schermata e destinazione dei risultati.
abstract interface class PuzzleFeed {
  Puzzle? next();

  /// Vero se [next] ha ancora puzzle da proporre.
  bool get hasNext;

  Future<FeedOutcome> finished(Puzzle puzzle, {required bool solved});
}

Future<FeedOutcome> _rated(
  PuzzleTrainer trainer,
  Puzzle puzzle,
  bool solved,
) async {
  final delta = await trainer.record(puzzle, solved: solved);
  return (ratingDelta: delta, awardXp: delta != null);
}

/// Puzzle scelti per punteggio, eventualmente di un solo tema.
class RatedFeed implements PuzzleFeed {
  RatedFeed(this.trainer, {this.theme});

  final PuzzleTrainer trainer;
  final String? theme;

  @override
  Puzzle? next() => trainer.next(theme: theme);

  @override
  bool get hasNext => true;

  @override
  Future<FeedOutcome> finished(Puzzle puzzle, {required bool solved}) =>
      _rated(trainer, puzzle, solved);
}

/// Un solo puzzle, per esempio quello del giorno.
class SingleFeed implements PuzzleFeed {
  SingleFeed(this.trainer, this.puzzle);

  final PuzzleTrainer trainer;
  final Puzzle puzzle;
  bool _served = false;

  @override
  Puzzle? next() {
    if (_served) return null;
    _served = true;
    return puzzle;
  }

  @override
  bool get hasNext => !_served;

  @override
  Future<FeedOutcome> finished(Puzzle puzzle, {required bool solved}) =>
      _rated(trainer, puzzle, solved);
}

/// Puzzle sbagliati in passato e giunti a scadenza (RF-85).
class ReviewFeed implements PuzzleFeed {
  ReviewFeed(this.trainer);

  final PuzzleTrainer trainer;
  final Set<String> _served = {};

  Puzzle? _peek() {
    for (final p in trainer.dueReviews()) {
      if (!_served.contains(p.id)) return p;
    }
    return null;
  }

  @override
  Puzzle? next() {
    final p = _peek();
    if (p != null) _served.add(p.id);
    return p;
  }

  @override
  bool get hasNext => _peek() != null;

  @override
  Future<FeedOutcome> finished(Puzzle puzzle, {required bool solved}) async {
    await trainer.reviews.reviewed(
      puzzle.id,
      solved: solved,
      now: trainer.now(),
    );
    return (ratingDelta: null, awardXp: true);
  }
}
