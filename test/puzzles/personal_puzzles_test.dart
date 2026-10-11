import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/puzzles/personal_puzzles.dart';
import 'package:scacchi/puzzles/puzzle.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/storage/key_value_store.dart';

Puzzle p(String id, {int rating = 1500}) => Puzzle.parseCsv(
  '$id,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,$rating,mateIn1',
);

class _FlakyStore extends MemoryStore {
  bool fail = false;

  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('disco pieno');
    await super.write(key, value);
  }
}

void main() {
  final day = DateTime(2026, 10, 11, 9);

  group('RF-80 puzzle personali salvati', () {
    test('si salvano, sopravvivono al riavvio e non si duplicano', () async {
      final store = MemoryStore();
      final personal = await PersonalPuzzles.load(store);
      expect((await personal.add([p('mio-a-3')])).added, ['mio-a-3']);
      expect((await personal.add([p('mio-a-3')])).added, isEmpty);

      final again = await PersonalPuzzles.load(store);
      expect(again.byId('mio-a-3')!.id, 'mio-a-3');
      expect(again.size, 1);
    });

    test('conserva solo gli ultimi puzzle', () async {
      final personal = await PersonalPuzzles.load(MemoryStore());
      await personal.add([
        for (var i = 0; i < PersonalPuzzles.capacity + 5; i++) p('mio-$i'),
      ]);
      expect(personal.size, PersonalPuzzles.capacity);
      expect(personal.byId('mio-0'), isNull);
      expect(personal.byId('mio-${PersonalPuzzles.capacity + 4}'), isNotNull);
    });

    test('indica i puzzle scartati per far posto', () async {
      final personal = await PersonalPuzzles.load(MemoryStore());
      await personal.add([
        for (var i = 0; i < PersonalPuzzles.capacity; i++) p('mio-$i'),
      ]);
      final result = await personal.add([p('mio-nuovo')]);
      expect(result.added, ['mio-nuovo']);
      expect(result.evicted, ['mio-0']);
    });

    test('se la scrittura fallisce niente cambia e si può riprovare', () async {
      final store = _FlakyStore();
      final personal = await PersonalPuzzles.load(store);
      store.fail = true;
      await expectLater(personal.add([p('mio-a')]), throwsStateError);
      expect(personal.byId('mio-a'), isNull);
      store.fail = false;
      expect((await personal.add([p('mio-a')])).added, ['mio-a']);
    });

    test('dati corrotti: si riparte da zero', () async {
      final store = MemoryStore();
      await store.write(PersonalPuzzles.storageKey, '{non json');
      expect((await PersonalPuzzles.load(store)).size, 0);
      await store.write(
        PersonalPuzzles.storageKey,
        '{"items":[{"csv":"riga,rotta"},'
        '{"csv":"ok,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,1500,mateIn1"}]}',
      );
      // Una riga non valida non butta via le altre.
      final partial = await PersonalPuzzles.load(store);
      expect(partial.size, 1);
      expect(partial.byId('ok'), isNotNull);
    });
  });

  group('RF-80 puzzle personali nel ripasso', () {
    late PuzzleTrainer trainer;
    late MemoryStore store;
    setUp(() async {
      store = MemoryStore();
      trainer = await PuzzleTrainer.load(
        PuzzleLibrary([p('a', rating: 1300), p('b'), p('c', rating: 1700)]),
        store,
        now: () => day,
      );
    });

    test('entrano nel ripasso di oggi come carte nuove', () async {
      expect(await trainer.addPersonal([p('mio-x-4')]), 1);
      expect(trainer.dueReviews().map((e) => e.id), ['mio-x-4']);
      expect(trainer.reviews.isNew('mio-x-4'), isTrue);
    });

    test('restano dopo il riavvio', () async {
      await trainer.addPersonal([p('mio-x-4')]);
      final again = await PuzzleTrainer.load(
        trainer.library,
        store,
        now: () => day,
      );
      expect(again.dueReviews().map((e) => e.id), ['mio-x-4']);
    });

    test('non cambiano il punteggio né i conteggi', () async {
      await trainer.addPersonal([p('mio-x-4', rating: 2400)]);
      final puzzle = trainer.dueReviews().single;
      expect(await trainer.record(puzzle, solved: false), isNull);
      expect(trainer.rating.rating, 1500);
      expect(trainer.failedCount, 0);
      expect(trainer.solvedCount, 0);
      expect(trainer.reviews.contains('mio-x-4'), isTrue);
    });

    test('non compaiono tra i puzzle proposti', () async {
      await trainer.addPersonal([p('mio-x-4')]);
      expect(trainer.library.byId('mio-x-4'), isNull);
      expect(trainer.next().id, 'b');
    });

    test('un puzzle scartato esce anche dal ripasso', () async {
      await trainer.addPersonal([
        for (var i = 0; i < PersonalPuzzles.capacity; i++) p('mio-$i'),
      ]);
      await trainer.addPersonal([p('mio-nuovo')]);
      expect(trainer.reviews.contains('mio-0'), isFalse);
      expect(trainer.reviews.contains('mio-nuovo'), isTrue);
    });

    test('un puzzle personale già in coda non torna carta nuova', () async {
      await trainer.addPersonal([p('mio-x-4')]);
      await trainer.reviews.failed('mio-x-4', day);
      expect(await trainer.addPersonal([p('mio-x-4')]), 0);
      expect(trainer.reviews.isNew('mio-x-4'), isFalse);
    });
  });
}
