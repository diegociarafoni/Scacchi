import 'dart:convert';

import '../storage/key_value_store.dart';
import 'puzzle_run.dart';

/// Miglior punteggio per modalità a serie (RG-08).
class RunRecords {
  RunRecords._(this._store);

  static const storageKey = 'puzzles.records.v1';

  final KeyValueStore _store;
  final Map<String, int> _best = {};

  static Future<RunRecords> load(KeyValueStore store) async {
    final r = RunRecords._(store);
    final raw = await store.read(storageKey);
    if (raw != null) {
      try {
        r._best.addAll((jsonDecode(raw) as Map<String, dynamic>).cast());
      } on Object {
        r._best.clear();
      }
    }
    return r;
  }

  int best(PuzzleRunMode mode) => _best[mode.name] ?? 0;

  /// Registra [score]; restituisce `true` se è un nuovo record.
  Future<bool> submit(PuzzleRunMode mode, int score) async {
    if (score <= best(mode)) return false;
    _best[mode.name] = score;
    await _store.write(storageKey, jsonEncode(_best));
    return true;
  }
}
