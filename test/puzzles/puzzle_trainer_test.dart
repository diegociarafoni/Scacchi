import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/puzzles/puzzle.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/storage/key_value_store.dart';

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

    test('notifica ogni puzzle completato (per XP e obiettivi)', () async {
      final t = await PuzzleTrainer.load(library, MemoryStore());
      final events = <PuzzleCompleted>[];
      t.onCompleted = events.add;
      await t.record(library.byId('a')!, solved: true);
      expect(events.single.puzzle.id, 'a');
      expect(events.single.solved, isTrue);
    });

    test('ignora dati salvati illeggibili', () async {
      final store = MemoryStore();
      await store.write(PuzzleTrainer.storageKey, '{rotto');
      final t = await PuzzleTrainer.load(library, store);
      expect(t.rating.rating, 1500);
    });
  });
}
