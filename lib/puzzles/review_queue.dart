import 'dart:convert';

import '../storage/key_value_store.dart';

/// Ripetizione dilazionata a intervalli crescenti (sistema di Leitner), per i
/// puzzle sbagliati e per le mosse del repertorio.
class ReviewQueue {
  ReviewQueue._(this._store, this._key, this._retire);

  static const storageKey = 'puzzles.review.v1';

  /// Giorni di attesa per ciascun livello.
  static const intervals = [1, 3, 7, 14, 30];

  /// Livello delle carte nuove, mai ripassate.
  static const newBox = -1;

  final KeyValueStore _store;
  final String _key;

  /// Se vero, superato l'ultimo livello la carta è imparata ed esce; altrimenti
  /// resta all'ultimo intervallo.
  final bool _retire;
  final Map<String, ({int box, DateTime due})> _items = {};

  static Future<ReviewQueue> load(
    KeyValueStore store, {
    String key = storageKey,
    bool retire = true,
  }) async {
    final q = ReviewQueue._(store, key, retire);
    final raw = await store.read(key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        json.forEach((id, v) {
          final m = v as Map<String, dynamic>;
          q._items[id] = (
            box: m['b'] as int,
            due: DateTime.fromMillisecondsSinceEpoch(m['d'] as int),
          );
        });
      } on Object {
        q._items.clear();
      }
    }
    return q;
  }

  int get size => _items.length;

  bool contains(String id) => _items.containsKey(id);

  bool isNew(String id) => _items[id]?.box == newBox;

  Iterable<String> get ids => _items.keys;

  /// Puzzle da ripassare, dal più in ritardo.
  List<String> due(DateTime now) {
    final list = _items.entries.where((e) => !e.value.due.isAfter(now)).toList()
      ..sort((a, b) => a.value.due.compareTo(b.value.due));
    return [for (final e in list) e.key];
  }

  Future<void> failed(String id, DateTime now) => _schedule(id, 0, now);

  /// Aggiunge carte nuove, da imparare subito; quelle già presenti restano.
  Future<void> addNew(Iterable<String> ids, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    for (final id in ids) {
      _items.putIfAbsent(id, () => (box: newBox, due: today));
    }
    return _save();
  }

  Future<void> remove(Iterable<String> ids) {
    ids.forEach(_items.remove);
    return _save();
  }

  Future<void> reviewed(
    String id, {
    required bool solved,
    required DateTime now,
  }) async {
    final item = _items[id];
    if (item == null) return;
    if (!solved) return _schedule(id, 0, now);
    final box = item.box + 1;
    if (box >= intervals.length) {
      if (!_retire) return _schedule(id, intervals.length - 1, now);
      _items.remove(id);
      return _save();
    }
    return _schedule(id, box, now);
  }

  Future<void> _schedule(String id, int box, DateTime now) {
    // Costruttore per componenti: resta a mezzanotte anche con l'ora legale.
    final due = DateTime(now.year, now.month, now.day + intervals[box]);
    _items[id] = (box: box, due: due);
    return _save();
  }

  Future<void> _save() => _store.write(
    _key,
    jsonEncode({
      for (final e in _items.entries)
        e.key: {'b': e.value.box, 'd': e.value.due.millisecondsSinceEpoch},
    }),
  );
}
