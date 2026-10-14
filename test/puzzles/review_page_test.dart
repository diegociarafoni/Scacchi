import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/puzzles/puzzle.dart';
import 'package:rokko/puzzles/puzzle_feed.dart';
import 'package:rokko/puzzles/puzzle_library.dart';
import 'package:rokko/puzzles/puzzle_page.dart';
import 'package:rokko/puzzles/puzzle_trainer.dart';
import 'package:rokko/storage/key_value_store.dart';

import '../localized_app.dart';

Puzzle p(String id) => Puzzle.parseCsv(
  '$id,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,1500,mateIn1',
);

void main() {
  testWidgets('RF-85 il ripasso termina con un messaggio e senza punteggio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var today = DateTime(2026, 10, 10);
    final trainer = await PuzzleTrainer.load(
      PuzzleLibrary([p('a')]),
      MemoryStore(),
      now: () => today,
    );
    await trainer.record(trainer.library.byId('a')!, solved: false);
    today = today.add(const Duration(days: 1));
    await tester.pumpWidget(
      localizedApp(
        home: PuzzlePage(trainer: trainer, feed: ReviewFeed(trainer)),
      ),
    );
    final rect = tester.getRect(find.byType(Chessboard));
    final s = rect.width / 8;
    await tester.tapAt(rect.topLeft + Offset(0.5 * s, 7.5 * s));
    await tester.pump();
    await tester.tapAt(rect.topLeft + Offset(0.5 * s, 0.5 * s));
    await tester.pumpAndSettle();
    expect(find.text('Risolto!'), findsOneWidget);
    expect(find.text('Non ci sono altri puzzle per ora.'), findsOneWidget);
    expect(trainer.dueReviews(), isEmpty);
  });

  testWidgets('senza puzzle da proporre la pagina lo dice', (tester) async {
    final trainer = await PuzzleTrainer.load(
      PuzzleLibrary([p('a')]),
      MemoryStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: PuzzlePage(trainer: trainer, feed: ReviewFeed(trainer)),
      ),
    );
    expect(find.text('Nessun puzzle da proporre.'), findsOneWidget);
  });
}
