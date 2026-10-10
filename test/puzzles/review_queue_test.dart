import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/puzzles/review_queue.dart';
import 'package:scacchi/storage/key_value_store.dart';

void main() {
  final day0 = DateTime(2026, 10, 10, 9);
  DateTime day(int n) => day0.add(Duration(days: n));

  group('RF-85 ripetizione dei puzzle sbagliati', () {
    test('un puzzle sbagliato torna il giorno dopo', () async {
      final q = await ReviewQueue.load(MemoryStore());
      await q.failed('a', day0);
      expect(q.due(day0), isEmpty);
      expect(q.due(day(1)), ['a']);
    });

    test('gli intervalli crescono a ogni ripasso riuscito', () async {
      final q = await ReviewQueue.load(MemoryStore());
      await q.failed('a', day0);
      await q.reviewed('a', solved: true, now: day(1));
      expect(q.due(day(3)), isEmpty);
      expect(q.due(day(4)), ['a']);
      await q.reviewed('a', solved: true, now: day(4));
      expect(q.due(day(10)), isEmpty);
      expect(q.due(day(11)), ['a']);
    });

    test('un nuovo errore riporta il puzzle all\'inizio', () async {
      final q = await ReviewQueue.load(MemoryStore());
      await q.failed('a', day0);
      await q.reviewed('a', solved: true, now: day(1));
      await q.reviewed('a', solved: false, now: day(4));
      expect(q.due(day(5)), ['a']);
    });

    test('dopo l\'ultimo intervallo il puzzle è imparato ed esce', () async {
      final q = await ReviewQueue.load(MemoryStore());
      await q.failed('a', day0);
      var now = day0;
      for (final gap in ReviewQueue.intervals) {
        now = now.add(Duration(days: gap));
        await q.reviewed('a', solved: true, now: now);
      }
      expect(q.size, 0);
    });

    test('i più in ritardo vengono prima', () async {
      final q = await ReviewQueue.load(MemoryStore());
      await q.failed('b', day(1));
      await q.failed('a', day0);
      expect(q.due(day(5)), ['a', 'b']);
    });

    test('sopravvive al riavvio', () async {
      final store = MemoryStore();
      await (await ReviewQueue.load(store)).failed('a', day0);
      expect((await ReviewQueue.load(store)).due(day(1)), ['a']);
    });
  });
}
