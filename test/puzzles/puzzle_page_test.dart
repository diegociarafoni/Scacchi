import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_page.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/storage/key_value_store.dart';

import 'fixtures.dart';

Offset square(WidgetTester tester, String name, {bool flipped = false}) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  var file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  var rank = int.parse(name[1]) - 1;
  if (flipped) {
    file = 7 - file;
    rank = 7 - rank;
  }
  return rect.topLeft + Offset((file + 0.5) * size, (7 - rank + 0.5) * size);
}

Future<void> tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(square(tester, uci.substring(2, 4)));
  await tester.pumpAndSettle();
}

String message(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('puzzle-message'))).data!;

Future<PuzzleTrainer> pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final trainer = await PuzzleTrainer.load(
    PuzzleLibrary([backRank, castle]),
    MemoryStore(),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: PuzzlePage(trainer: trainer, puzzle: backRank),
    ),
  );
  return trainer;
}

void main() {
  testWidgets('RF-81 una mossa sbagliata viene annullata, la giusta risolve', (
    tester,
  ) async {
    final trainer = await pump(tester);
    expect(message(tester), 'Trova la mossa migliore per il Bianco.');
    await tapMove(tester, 'a1a7');
    expect(message(tester), 'Non è la mossa giusta. Riprova.');
    await tapMove(tester, 'a1a8');
    expect(message(tester), startsWith('Puzzle concluso.'));
    expect(trainer.failedCount, 1);
  });

  testWidgets('RF-83 il suggerimento evidenzia il pezzo da muovere', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Suggerimento'));
    await tester.pump();
    final board = tester.widget<Chessboard>(find.byType(Chessboard));
    expect(board.shapes, isNotEmpty);
  });

  testWidgets('RF-83 la soluzione conclude il puzzle come fallito', (
    tester,
  ) async {
    final trainer = await pump(tester);
    await tester.tap(find.text('Soluzione'));
    await tester.pumpAndSettle();
    expect(message(tester), startsWith('Puzzle concluso.'));
    expect(trainer.failedCount, 1);
  });
}
