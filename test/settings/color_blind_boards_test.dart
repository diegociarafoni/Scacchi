import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/minigames/capture_all_page.dart';
import 'package:scacchi/minigames/coordinates_page.dart';
import 'package:scacchi/openings/repertoire.dart';
import 'package:scacchi/openings/repertoire_page.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/path/stage_page.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_page.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/settings/board_marks.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../localized_app.dart';
import '../puzzles/fixtures.dart';

Future<void> pumpColorBlind(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final settings = SettingsController.defaults();
  await settings.update(AppSettings(colorBlind: true));
  await tester.pumpWidget(
    SettingsScope(
      controller: settings,
      child: localizedApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

Offset squareOn(WidgetTester tester, Finder board, Square square) {
  final rect = tester.getRect(board);
  final size = rect.width / 8;
  return rect.topLeft +
      Offset((square.file + 0.5) * size, (7 - square.rank + 0.5) * size);
}

/// Il blu Okabe-Ito scelto per la scacchiera verde.
final safeHint = BoardMarks.of(BoardTheme.green, colorBlind: true).hint;

void main() {
  final safe = AppSettings(colorBlind: true);

  testWidgets('RNF-07 coordinate: esito in blu e arancio', (tester) async {
    await pumpColorBlind(
      tester,
      CoordinatesPage(random: Random(1), onFinished: (_) {}),
    );
    await tester.tap(find.text('Inizia'));
    await tester.pump();
    final board = find.byType(StaticChessboard);
    Color? tapped() => tester
        .widget<StaticChessboard>(board)
        .squareHighlights
        .values
        .single
        .details
        .solidColor;
    Square target() => Square.parse(
      tester.widget<Text>(find.byKey(const Key('coordinate-target'))).data!,
    )!;
    await tester.tapAt(squareOn(tester, board, target()));
    await tester.pump();
    expect(tapped(), safe.answerColor(true));
    await tester.tapAt(
      squareOn(tester, board, Square((target().value + 1) % 64)),
    );
    await tester.pump();
    expect(tapped(), safe.answerColor(false));
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
  });

  testWidgets('RNF-07 cattura tutto usa le evidenziazioni per daltonici', (
    tester,
  ) async {
    await pumpColorBlind(
      tester,
      CaptureAllPage(random: Random(5), onFinished: (_) {}),
    );
    expect(
      tester.widget<Chessboard>(find.byType(Chessboard)).settings.colorScheme,
      same(BoardTheme.green.colorBlindScheme),
    );
  });

  testWidgets('RNF-07 le tappe del percorso usano le evidenziazioni per '
      'daltonici', (tester) async {
    await pumpColorBlind(tester, StagePage(stage: stageById('pieces.king')!));
    expect(
      tester.widget<Chessboard>(find.byType(Chessboard)).settings.colorScheme,
      same(BoardTheme.green.colorBlindScheme),
    );
  });

  testWidgets('RNF-07 il suggerimento dei problemi è blu', (tester) async {
    final trainer = await PuzzleTrainer.load(
      PuzzleLibrary([backRank, castle]),
      MemoryStore(),
    );
    await pumpColorBlind(
      tester,
      PuzzlePage(trainer: trainer, puzzle: backRank),
    );
    await tester.tap(find.text('Suggerimento'));
    await tester.pumpAndSettle();
    final shapes = tester.widget<Chessboard>(find.byType(Chessboard)).shapes;
    expect(shapes.single, isA<Circle>());
    expect((shapes.single as Circle).color, safeHint);
  });

  testWidgets('RNF-07 la freccia del ripasso è blu', (tester) async {
    final t = await RepertoireTrainer.load(MemoryStore());
    await t.addLine(Side.white, 'Italiana', [
      for (final m in ['e2e4', 'e7e5', 'g1f3']) Move.parse(m)!,
    ]);
    await pumpColorBlind(tester, RepertoirePage(trainer: t, side: Side.white));
    await tester.tap(find.text('Ripassa 2 mosse'));
    await tester.pumpAndSettle();
    final shapes = tester.widget<Chessboard>(find.byType(Chessboard)).shapes;
    expect((shapes.single as Arrow).color, safeHint);
  });
}
