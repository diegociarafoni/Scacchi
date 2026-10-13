import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/puzzles/puzzle.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/storage/key_value_store.dart';
import 'package:scacchi/story/story_feed.dart';

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

  test('RG-13 il feed riferisce l\'esito di ogni puzzle concluso', () async {
    final outcomes = <bool>[];
    final feed = StoryPuzzleFeed(
      await trainer(),
      theme: 'castling',
      goal: 1,
      onOutcome: outcomes.add,
    );
    await feed.finished(feed.next()!, solved: false);
    await feed.finished(feed.next()!, solved: true);
    expect(outcomes, [false, true]);
  });

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
}
