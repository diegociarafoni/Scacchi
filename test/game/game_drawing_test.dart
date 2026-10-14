import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/board_drawing.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/settings/settings.dart';

import '../computer_fakes.dart';
import '../computer_game_test.dart' show square;
import '../game_actions.dart';

void main() {
  testWidgets('RF-05 in partita una pressione prolungata disegna una freccia '
      'che un tocco toglie', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          settings: SettingsController.defaults(),
          computerAvailable: true,
        ),
      ),
    );
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await chooseTwoPlayers(tester);
    await tester.pumpAndSettle();
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle();
    Set<Shape> shapes() =>
        tester.widget<Chessboard>(find.byType(Chessboard)).shapes.toSet();
    final from = square(tester, 'e4');
    final gesture = await tester.startGesture(from);
    await tester.pump(BoardDrawing.holdTime + const Duration(milliseconds: 50));
    await gesture.moveTo(square(tester, 'e6'));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(shapes().whereType<Arrow>(), isNotEmpty);
    await tester.tapAt(square(tester, 'a4'));
    await tester.pump();
    expect(shapes().whereType<Arrow>(), isEmpty);
  });
}
