import 'dart:convert';

import 'glicko2.dart';
import 'puzzle.dart';
import 'puzzle_library.dart';
import '../storage/key_value_store.dart';

/// Evento emesso a ogni puzzle concluso, per XP, obiettivi e statistiche.
class PuzzleCompleted {
  const PuzzleCompleted({
    required this.puzzle,
    required this.solved,
    required this.ratingDelta,
  });

  final Puzzle puzzle;
  final bool solved;
  final double ratingDelta;
}

/// Punteggio puzzle del giocatore e scelta del puzzle successivo.
class PuzzleTrainer {
  PuzzleTrainer._(this.library, this._store);

  static const storageKey = 'puzzles.trainer.v1';

  /// Deviazione attribuita ai puzzle, il cui punteggio è già stabile.
  static const puzzleDeviation = 75.0;

  final PuzzleLibrary library;
  final KeyValueStore _store;
  Glicko2Rating _rating = const Glicko2Rating();
  final Set<String> _seen = {};
  int _solved = 0;
  int _failed = 0;

  void Function(PuzzleCompleted)? onCompleted;

  Glicko2Rating get rating => _rating;
  int get solvedCount => _solved;
  int get failedCount => _failed;
  Set<String> get seen => Set.unmodifiable(_seen);

  static Future<PuzzleTrainer> load(
    PuzzleLibrary library,
    KeyValueStore store,
  ) async {
    final t = PuzzleTrainer._(library, store);
    final raw = await store.read(storageKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        t._rating = Glicko2Rating.fromJson(
          json['rating'] as Map<String, dynamic>,
        );
        t._seen.addAll((json['seen'] as List).cast<String>());
        t._solved = json['solved'] as int;
        t._failed = json['failed'] as int;
      } on Object {
        // Dati corrotti: si riparte da zero invece di bloccare i puzzle.
      }
    }
    return t;
  }

  Puzzle next({String? theme}) =>
      library.next(rating: _rating.rating, theme: theme, seen: _seen);

  /// Registra l'esito e restituisce la variazione di punteggio.
  Future<double> record(Puzzle puzzle, {required bool solved}) async {
    final before = _rating.rating;
    _rating = _rating.update([
      GameResult(
        opponent: puzzle.rating.toDouble(),
        opponentDeviation: puzzleDeviation,
        score: solved ? 1 : 0,
      ),
    ]);
    _seen.add(puzzle.id);
    solved ? _solved++ : _failed++;
    await _save();
    final delta = _rating.rating - before;
    onCompleted?.call(
      PuzzleCompleted(puzzle: puzzle, solved: solved, ratingDelta: delta),
    );
    return delta;
  }

  Future<void> _save() => _store.write(
    storageKey,
    jsonEncode({
      'rating': _rating.toJson(),
      'seen': _seen.toList(),
      'solved': _solved,
      'failed': _failed,
    }),
  );
}
