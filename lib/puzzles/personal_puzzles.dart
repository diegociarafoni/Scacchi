import 'dart:convert';

import '../storage/key_value_store.dart';
import 'puzzle.dart';

/// Puzzle ricavati dagli errori del giocatore, salvati sul dispositivo.
class PersonalPuzzles {
  PersonalPuzzles._(this._store);

  static const storageKey = 'puzzles.personal.v1';

  /// Oltre questo numero si scartano i più vecchi, per non far crescere il file.
  static const capacity = 200;

  static const idPrefix = 'mio-';

  static bool isPersonal(String id) => id.startsWith(idPrefix);

  final KeyValueStore _store;
  Map<String, Puzzle> _puzzles = {};

  static Future<PersonalPuzzles> load(KeyValueStore store) async {
    final personal = PersonalPuzzles._(store);
    final raw = await store.read(storageKey);
    if (raw == null) return personal;
    try {
      final items = (jsonDecode(raw) as Map<String, dynamic>)['items'] as List;
      for (final item in items) {
        try {
          final puzzle = Puzzle.parseCsv(
            (item as Map<String, dynamic>)['csv'] as String,
          );
          personal._puzzles[puzzle.id] = puzzle;
        } on Object {
          // Una riga rovinata non deve far perdere le altre.
        }
      }
    } on Object {
      personal._puzzles = {};
    }
    return personal;
  }

  int get size => _puzzles.length;

  Puzzle? byId(String id) => _puzzles[id];

  /// Tutti i puzzle salvati, dal più vecchio.
  Iterable<Puzzle> get all => _puzzles.values;

  /// Aggiunge i puzzle che non ci sono già. Restituisce gli id aggiunti e
  /// quelli scartati per far posto (i più vecchi). In memoria cambia solo se
  /// la scrittura riesce, così un errore si può riprovare.
  Future<({List<String> added, List<String> evicted})> add(
    Iterable<Puzzle> puzzles,
  ) async {
    final next = {..._puzzles};
    final added = <String>[];
    for (final puzzle in puzzles) {
      if (next.containsKey(puzzle.id)) continue;
      next[puzzle.id] = puzzle;
      added.add(puzzle.id);
    }
    if (added.isEmpty) return (added: added, evicted: const <String>[]);
    final evicted = <String>[];
    for (final id in next.keys.toList()) {
      if (next.length <= capacity) break;
      next.remove(id);
      // Uno scartato che era appena arrivato non è mai stato salvato.
      if (!added.remove(id)) evicted.add(id);
    }
    await _store.write(
      storageKey,
      jsonEncode({
        'items': [
          for (final p in next.values) {'csv': p.toCsv()},
        ],
      }),
    );
    _puzzles = next;
    return (added: added, evicted: evicted);
  }
}
