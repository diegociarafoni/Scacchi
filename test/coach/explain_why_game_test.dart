import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart';
import '../computer_game_test.dart' show tapMove;

Widget app({required bool explainWhy}) {
  final settings = SettingsController.defaults();
  settings.value = settings.value.copyWith(explainWhy: explainWhy);
  return MaterialApp(
    home: GamePage(
      settings: settings,
      computerAvailable: true,
      now: () => TestWidgetsFlutterBinding.instance.clock.now(),
      createComputer: () => ComputerPlayer(
        connect: () async => FirstLegalMoveEngine(forcedMove: 'g8f6'),
      ),
    ),
  );
}

void main() {
  testWidgets('RF-122 dopo la mossa del computer compare la spiegazione', (
    tester,
  ) async {
    await tester.pumpWidget(app(explainWhy: true));
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Sviluppa il cavallo: entra in gioco.'), findsOneWidget);
  });

  testWidgets('RF-122 spenta (predefinito) non compare nulla', (tester) async {
    await tester.pumpWidget(app(explainWhy: false));
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('Sviluppa'), findsNothing);
  });
}
