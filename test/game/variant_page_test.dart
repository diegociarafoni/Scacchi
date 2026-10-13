import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart' show chooseTwoPlayers;
import '../game_actions.dart';

Offset square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(square(tester, uci.substring(2, 4)));
  await tester.pumpAndSettle();
}

Future<void> start(WidgetTester tester, String variant) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: GamePage(
        settings: SettingsController.defaults(),
        chess960Id: () => 3,
      ),
    ),
  );
  await tapGameAction(tester, 'Nuova');
  await tester.pumpAndSettle();
  await chooseTwoPlayers(tester);
  await tester.tap(find.text(variant));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Senza tempo'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('RF-120 Chess960: posizione nel titolo e arrocco sulla torre', (
    tester,
  ) async {
    await start(tester, 'Chess960');
    expect(find.text('Chess960 n. 3'), findsOneWidget);
    // BQNNRKRB: il re in f1 arrocca toccando la torre in g1.
    await tapMove(tester, 'f1g1');
    expect(find.text('1. O-O'), findsOneWidget);
    expect(find.text('Muove il Nero.'), findsOneWidget);
  });

  testWidgets('RF-121 Re della collina: il re al centro vince', (tester) async {
    await start(tester, 'Re della collina');
    expect(find.text('Re della collina'), findsOneWidget);
    for (final uci in ['e2e4', 'a7a6', 'e1e2', 'a6a5', 'e2e3', 'a5a4']) {
      await tapMove(tester, uci);
    }
    await tapMove(tester, 'e3d4');
    expect(find.text('Re al centro. Vince il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-121 Tre scacchi: conteggio nel titolo e vittoria', (
    tester,
  ) async {
    await start(tester, 'Tre scacchi');
    expect(find.text('Scacchi dati: Bianco 0, Nero 0'), findsOneWidget);
    for (final uci in ['e2e4', 'e7e5', 'd1h5', 'b8c6', 'h5f7', 'e8f7']) {
      await tapMove(tester, uci);
    }
    expect(find.text('Scacchi dati: Bianco 1, Nero 0'), findsOneWidget);
    for (final uci in ['f1c4', 'd7d5', 'c4d5']) {
      await tapMove(tester, uci);
    }
    expect(find.text('Terzo scacco. Vince il Bianco.'), findsOneWidget);
  });
}
