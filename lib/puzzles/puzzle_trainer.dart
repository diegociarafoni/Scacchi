import 'dart:convert';

import 'glicko2.dart';
import 'personal_puzzles.dart';
import 'puzzle.dart';
import 'puzzle_library.dart';
import 'review_queue.dart';
import 'run_records.dart';
import '../storage/key_value_store.dart';

/// Punteggio puzzle del giocatore e scelta del puzzle successivo.
class PuzzleTrainer {
  PuzzleTrainer._(this.library, this._store, this.now);

  static const storageKey = 'puzzles.trainer.v1';

  /// Deviazione attribuita ai puzzle, il cui punteggio è già stabile.
  static const puzzleDeviation = 75.0;

  final PuzzleLibrary library;
  final KeyValueStore _store;
  final DateTime Function() now;
  late final ReviewQueue reviews;
  late final PersonalPuzzles personal;
  late final RunRecords records;
  Glicko2Rating _rating = const Glicko2Rating();
  final Set<String> _seen = {};
  int _solved = 0;
  int _failed = 0;

  Glicko2Rating get rating => _rating;
  int get solvedCount => _solved;
  int get failedCount => _failed;
  Set<String> get seen => Set.unmodifiable(_seen);

  static Future<PuzzleTrainer> load(
    PuzzleLibrary library,
    KeyValueStore store, {
    DateTime Function() now = DateTime.now,
  }) async {
    final t = PuzzleTrainer._(library, store, now);
    t.reviews = await ReviewQueue.load(store);
    t.personal = await PersonalPuzzles.load(store);
    t.records = await RunRecords.load(store);
    final raw = await store.read(storageKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final rating = Glicko2Rating.fromJson(
          json['rating'] as Map<String, dynamic>,
        );
        final seen = [for (final id in json['seen'] as List) id as String];
        final solved = json['solved'] as int;
        final failed = json['failed'] as int;
        t._rating = rating;
        t._seen.addAll(seen);
        t._solved = solved;
        t._failed = failed;
      } on Object {
        // Dati corrotti: si riparte da zero invece di bloccare i puzzle.
      }
    }
    return t;
  }

  /// Puzzle della raccolta o tra quelli personali.
  Puzzle? puzzleById(String id) => library.byId(id) ?? personal.byId(id);

  /// Puzzle da ripassare oggi che esistono ancora.
  List<Puzzle> dueReviews() => [
    for (final id in reviews.due(now())) ?puzzleById(id),
  ];

  /// Salva puzzle ricavati dagli errori e li mette nel ripasso di oggi come
  /// carte nuove. Restituisce quanti non erano già presenti.
  Future<int> addPersonal(Iterable<(Puzzle, String?)> items) async {
    final added = await personal.add(items);
    await reviews.addNew([for (final (p, _) in items) p.id], now());
    return added;
  }

  Puzzle next({String? theme}) =>
      library.next(rating: _rating.rating, theme: theme, seen: _seen);

  /// Registra l'esito e restituisce la variazione di punteggio, oppure `null`
  /// se il puzzle era già stato visto: le ripetizioni non cambiano il punteggio.
  Future<double?> record(Puzzle puzzle, {required bool solved}) async {
    if (PersonalPuzzles.isPersonal(puzzle.id)) {
      // Il punteggio misura i puzzle del database: quelli personali valgono
      // solo per il ripasso.
      if (!solved) await reviews.failed(puzzle.id, now());
      return null;
    }
    if (!_seen.add(puzzle.id)) {
      if (!solved) await reviews.failed(puzzle.id, now());
      // In fondo all'ordine dei visti, così si ricomincia dal meno recente.
      _seen
        ..remove(puzzle.id)
        ..add(puzzle.id);
      await _save();
      return null;
    }
    final before = _rating.rating;
    _rating = _rating.update([
      GameResult(
        opponent: puzzle.rating.toDouble(),
        opponentDeviation: puzzleDeviation,
        score: solved ? 1 : 0,
      ),
    ]);
    solved ? _solved++ : _failed++;
    await _save();
    if (!solved) await reviews.failed(puzzle.id, now());
    return _rating.rating - before;
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
