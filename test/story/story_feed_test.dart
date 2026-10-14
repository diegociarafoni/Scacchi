import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/puzzles/puzzle.dart';
import 'package:rokko/puzzles/puzzle_library.dart';
import 'package:rokko/puzzles/puzzle_trainer.dart';
import 'package:rokko/storage/key_value_store.dart';
import 'package:rokko/story/story_feed.dart';

import '../puzzles/fixtures.dart';

void main() {
  Future<PuzzleTrainer> trainer() =>
      PuzzleTrainer.load(PuzzleLibrary([backRank, castle]), MemoryStore());

  test(
    'RG-13 il feed si ferma dopo i puzzle risolti al primo tentativo',
    () async {
      final feed = StoryPuzzleFeed(await trainer(), theme: 'castling', goal: 2);
      expect(feed.hasNext, isTrue);
      final first = feed.next()!;
      expect(first.themes, contains('castling'));
      await feed.finished(first, solved: false);
      expect(feed.solved, 0);
      expect(feed.hasNext, isTrue);
      await feed.finished(feed.next()!, solved: true);
      expect(feed.hasNext, isTrue);
      await feed.finished(feed.next()!, solved: true);
      expect(feed.solved, 2);
      expect(feed.hasNext, isFalse);
      expect(feed.next(), isNull);
    },
  );

  test(
    'RG-13 il puzzle risolto conta subito, senza attendere il salvataggio',
    () async {
      final feed = StoryPuzzleFeed(await trainer(), theme: 'castling', goal: 1);
      final pending = feed.finished(feed.next()!, solved: true);
      expect(feed.solved, 1);
      expect(feed.hasNext, isFalse);
      await pending;
    },
  );

  test('RG-13 con un tetto di punteggio propone puzzle più facili', () async {
    final easy = Puzzle.parseCsv(
      'easy,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,600,mateIn1',
    );
    final hard = Puzzle.parseCsv(
      'hard,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,2200,mateIn1',
    );
    final t = await PuzzleTrainer.load(
      PuzzleLibrary([easy, hard]),
      MemoryStore(),
    );
    final free = StoryPuzzleFeed(t, theme: 'mateIn1', goal: 1);
    expect(free.next()!.id, 'hard');
    final capped = StoryPuzzleFeed(
      t,
      theme: 'mateIn1',
      goal: 1,
      maxRating: 700,
    );
    expect(capped.next()!.id, 'easy');
  });

  group('S6 aiuto quando ci si blocca', () {
    final easy = Puzzle.parseCsv(
      'easy,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,600,mateIn1',
    );
    final hard = Puzzle.parseCsv(
      'hard,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,2200,mateIn1',
    );
    final mid = Puzzle.parseCsv(
      'mid,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,1400,mateIn1',
    );
    final mid2 = Puzzle.parseCsv(
      'mid2,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,1300,mateIn1',
    );

    Future<StoryPuzzleFeed> feed({void Function()? onHelp}) async {
      final t = await PuzzleTrainer.load(
        PuzzleLibrary([easy, mid, mid2, hard]),
        MemoryStore(),
      );
      return StoryPuzzleFeed(t, theme: 'mateIn1', goal: 3, onHelp: onHelp);
    }

    test('un solo errore non cambia la difficoltà né chiama onHelp', () async {
      var helps = 0;
      final f = await feed(onHelp: () => helps++);
      await f.finished(f.next()!, solved: false);
      expect(helps, 0);
      expect(f.helping, isFalse);
    });

    test('dopo due errori di fila propone un puzzle più facile', () async {
      var helps = 0;
      final f = await feed(onHelp: () => helps++);
      final first = f.next()!;
      await f.finished(first, solved: false);
      final second = f.next()!;
      await f.finished(second, solved: false);
      expect(helps, 1);
      expect(f.helping, isTrue);
      final third = f.next()!;
      expect(third.rating, lessThan(second.rating));
      expect(third.rating, lessThanOrEqualTo(1200));
    });

    test('una risposta giusta toglie l\'aiuto', () async {
      final f = await feed();
      await f.finished(f.next()!, solved: false);
      await f.finished(f.next()!, solved: false);
      await f.finished(f.next()!, solved: true);
      expect(f.helping, isFalse);
    });

    test(
      'l\'aiuto non scende sotto i 400 punti e non avvisa due volte',
      () async {
        var helps = 0;
        final f = await feed(onHelp: () => helps++);
        for (var i = 0; i < 5; i++) {
          await f.finished(f.next()!, solved: false);
        }
        expect(helps, 1);
      },
    );
  });
}
