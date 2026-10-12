import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/story/story_feed.dart';
import 'package:scacchi/storage/key_value_store.dart';

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
}
