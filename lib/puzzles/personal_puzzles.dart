import 'dart:convert';

import '../storage/key_value_store.dart';
import 'puzzle.dart';

/// Puzzle ricavati dagli errori del giocatore, salvati sul dispositivo.
class PersonalPuzzles {
  PersonalPuzzles._(this._store);

  static const storageKey = 'puzzles.personal.v1';

  /// Oltre questo numero si scartano i più vecchi, per non far crescere il file.
  static const capacity = 200;

  /// Prefisso degli id, per distinguerli da quelli del database.
  static const idPrefix = 'mio-';

  static bool isPersonal(String id) => id.startsWith(idPrefix);

  final KeyValueStore _store;
  final Map<String, Puzzle> _puzzles = {};
  final Map<String, String> _csv = {};
  final Map<String, String> _why = {};

  static Future<PersonalPuzzles> load(KeyValueStore store) async {
    final personal = PersonalPuzzles._(store);
    final raw = await store.read(storageKey);
    if (raw == null) return personal;
    try {
      final items = (jsonDecode(raw) as Map<String, dynamic>)['items'] as List;
      for (final item in items) {
        try {
          final map = item as Map<String, dynamic>;
          final csv = map['csv'] as String;
          personal._put(Puzzle.parseCsv(csv), csv, map['why'] as String?);
        } on Object {
          // Una riga rovinata non deve far perdere le altre.
        }
      }
    } on Object {
      personal._puzzles.clear();
      personal._csv.clear();
      personal._why.clear();
    }
    return personal;
  }

  int get size => _puzzles.length;

  Puzzle? byId(String id) => _puzzles[id];

  /// Spiegazione del coach dell'errore da cui nasce il puzzle.
  String? explanation(String id) => _why[id];

  /// Aggiunge i puzzle nuovi; restituisce quanti non c'erano già.
  Future<int> add(Iterable<(Puzzle, String?)> items) async {
    var added = 0;
    for (final (puzzle, why) in items) {
      if (_puzzles.containsKey(puzzle.id)) continue;
      _put(puzzle, _toCsv(puzzle), why);
      added++;
    }
    if (added == 0) return 0;
    while (_puzzles.length > capacity) {
      final oldest = _puzzles.keys.first;
      _puzzles.remove(oldest);
      _csv.remove(oldest);
      _why.remove(oldest);
    }
    await _store.write(
      storageKey,
      jsonEncode({
        'items': [
          for (final id in _puzzles.keys)
            {'csv': _csv[id], if (_why[id] != null) 'why': _why[id]},
        ],
      }),
    );
    return added;
  }

  void _put(Puzzle puzzle, String csv, String? why) {
    _puzzles[puzzle.id] = puzzle;
    _csv[puzzle.id] = csv;
    if (why != null) _why[puzzle.id] = why;
  }

  static String _toCsv(Puzzle p) =>
      '${p.id},${p.fen},${p.moves.map((m) => m.uci).join(' ')},'
      '${p.rating},${p.themes.join(' ')}';
}
