import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart' show Key;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_tracker.dart';
import 'package:scacchi/puzzles/puzzle.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/review/personal_puzzles.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../localized_app.dart';

void main() {
  testWidgets('RF-80 i puzzle dagli errori finiscono nel ripasso', (
    tester,
  ) async {
    final trainer = await PuzzleTrainer.load(
      PuzzleLibrary([
        Puzzle.parseCsv(
          'a,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,1500,mateIn1',
        ),
      ]),
      MemoryStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: SettingsController.defaults(),
          puzzleTrainer: () async => trainer,
          reminderScheduler: () => null,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('home-play')));
    await tester.pumpAndSettle();
    final game = tester.widget<GamePage>(find.byType(GamePage));
    final mistake = MistakePuzzle(
      id: 'mio-x-5',
      fen: '7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1',
      moves: [Move.parse('b4c2')!, Move.parse('a1a8')!],
      rating: 1500,
      themes: const {'mateIn1'},
      explanation: 'Hai lasciato il matto.',
    );
    expect(await game.onSavePuzzles!([mistake]), 1);
    expect(trainer.dueReviews().map((p) => p.id), ['mio-x-5']);
    expect(trainer.personal.byId('mio-x-5'), isNotNull);
    expect(game.onActivity, isA<Future<ProgressUpdate?> Function(Activity)>());
  });
}
