import 'dart:convert';

import '../storage/key_value_store.dart';

/// Ripasso dei puzzle sbagliati a intervalli crescenti (sistema di Leitner).
class ReviewQueue {
  ReviewQueue._(this._store);

  static const storageKey = 'puzzles.review.v1';

  /// Giorni di attesa per ciascun livello; superato l'ultimo il puzzle è imparato.
  static const intervals = [1, 3, 7, 14, 30];

  final KeyValueStore _store;
  final Map<String, ({int box, DateTime due})> _items = {};

  static Future<ReviewQueue> load(KeyValueStore store) async {
    final q = ReviewQueue._(store);
    final raw = await store.read(storageKey);
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

  /// Puzzle da ripassare, dal più in ritardo.
  List<String> due(DateTime now) {
    final list = _items.entries.where((e) => !e.value.due.isAfter(now)).toList()
      ..sort((a, b) => a.value.due.compareTo(b.value.due));
    return [for (final e in list) e.key];
  }

  Future<void> failed(String id, DateTime now) => _schedule(id, 0, now);

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
      _items.remove(id);
      return _save();
    }
    return _schedule(id, box, now);
  }

  Future<void> _schedule(String id, int box, DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    _items[id] = (box: box, due: day.add(Duration(days: intervals[box])));
    return _save();
  }

  Future<void> _save() => _store.write(
    storageKey,
    jsonEncode({
      for (final e in _items.entries)
        e.key: {'b': e.value.box, 'd': e.value.due.millisecondsSinceEpoch},
    }),
  );
}
