import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/puzzles/puzzle.dart';
import 'package:rokko/puzzles/puzzle_library.dart';
import 'package:rokko/puzzles/puzzle_trainer.dart';
import 'package:rokko/storage/key_value_store.dart';

Puzzle p(String id, int rating) => Puzzle.parseCsv(
  '$id,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,$rating,mateIn1',
);

void main() {
  final library = PuzzleLibrary([p('a', 1300), p('b', 1500), p('c', 1700)]);

  group('RF-81 allenamento con punteggio locale', () {
    test('parte da 1500 e propone il puzzle più adatto', () async {
      final t = await PuzzleTrainer.load(library, MemoryStore());
      expect(t.rating.rating, 1500);
      expect(t.next().id, 'b');
    });

    test(
      'un puzzle risolto alza il punteggio e non viene riproposto',
      () async {
        final t = await PuzzleTrainer.load(library, MemoryStore());
        final delta = await t.record(library.byId('b')!, solved: true);
        expect(delta, greaterThan(0));
        expect(t.rating.rating, greaterThan(1500));
        expect(t.next().id, isNot('b'));
        expect(t.solvedCount, 1);
      },
    );

    test('un puzzle fallito abbassa il punteggio', () async {
      final t = await PuzzleTrainer.load(library, MemoryStore());
      expect(await t.record(library.byId('b')!, solved: false), lessThan(0));
    });

    test('i progressi sopravvivono al riavvio', () async {
      final store = MemoryStore();
      final t = await PuzzleTrainer.load(library, store);
      await t.record(library.byId('b')!, solved: true);
      final again = await PuzzleTrainer.load(library, store);
      expect(again.rating, t.rating);
      expect(again.solvedCount, 1);
      expect(again.next().id, isNot('b'));
    });

    test('ripetere un puzzle già visto non cambia il punteggio', () async {
      final t = await PuzzleTrainer.load(library, MemoryStore());
      await t.record(library.byId('b')!, solved: true);
      final rating = t.rating;
      expect(await t.record(library.byId('b')!, solved: true), isNull);
      expect(t.rating, rating);
      expect(t.solvedCount, 1);
    });

    test('visti tutti, ripropone il meno recente', () async {
      final t = await PuzzleTrainer.load(library, MemoryStore());
      for (final id in ['a', 'b', 'c']) {
        await t.record(library.byId(id)!, solved: true);
      }
      final first = t.next();
      expect(first.id, 'a');
      await t.record(first, solved: true);
      expect(t.next().id, 'b');
    });

    test('dati salvati parziali non vengono caricati a metà', () async {
      final store = MemoryStore();
      await store.write(
        PuzzleTrainer.storageKey,
        '{"rating": {"r": 1800, "d": 60, "v": 0.06}, "seen": ["a"], '
        '"solved": "x", "failed": 0}',
      );
      final t = await PuzzleTrainer.load(library, store);
      expect(t.rating.rating, 1500);
      expect(t.seen, isEmpty);
    });

    test('RF-85 un puzzle sbagliato entra nel ripasso', () async {
      var today = DateTime(2026, 10, 10);
      final t = await PuzzleTrainer.load(
        library,
        MemoryStore(),
        now: () => today,
      );
      await t.record(library.byId('b')!, solved: false);
      await t.record(library.byId('c')!, solved: true);
      today = today.add(const Duration(days: 1));
      expect(t.reviews.due(today), ['b']);
    });

    test(
      'RF-85 anche un puzzle già visto sbagliato entra nel ripasso',
      () async {
        var today = DateTime(2026, 10, 10);
        final t = await PuzzleTrainer.load(
          library,
          MemoryStore(),
          now: () => today,
        );
        await t.record(library.byId('b')!, solved: true);
        await t.record(library.byId('b')!, solved: false);
        today = today.add(const Duration(days: 1));
        expect(t.dueReviews().map((p) => p.id), ['b']);
      },
    );

    test(
      'il ripasso ignora i puzzle non più presenti nella raccolta',
      () async {
        final store = MemoryStore();
        final today = DateTime(2026, 10, 10);
        final old = await PuzzleTrainer.load(
          PuzzleLibrary([p('x', 1500)]),
          store,
          now: () => today,
        );
        await old.record(old.library.byId('x')!, solved: false);
        final t = await PuzzleTrainer.load(
          library,
          store,
          now: () => today.add(const Duration(days: 2)),
        );
        expect(t.reviews.size, 1);
        expect(t.dueReviews(), isEmpty);
      },
    );

    test('ignora dati salvati illeggibili', () async {
      final store = MemoryStore();
      await store.write(PuzzleTrainer.storageKey, '{rotto');
      final t = await PuzzleTrainer.load(library, store);
      expect(t.rating.rating, 1500);
    });
  });
}
