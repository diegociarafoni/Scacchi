import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart';
import '../computer_game_test.dart' show square;

Future<void> _tap(WidgetTester tester, String from, String to) async {
  await tester.tapAt(square(tester, from));
  await tester.pump();
  await tester.tapAt(square(tester, to));
  await tester.pump();
}

/// Partita col Bianco: e2e4 e il computer risponde e7e5 dopo tre secondi.
Future<void> _thinkingAfterE4(
  WidgetTester tester, {
  bool premove = true,
}) async {
  final settings = SettingsController.defaults();
  await settings.update(settings.value.copyWith(premove: premove));
  await tester.pumpWidget(
    MaterialApp(
      home: GamePage(
        settings: settings,
        computerAvailable: true,
        now: () => TestWidgetsFlutterBinding.instance.clock.now(),
        createComputer: () => ComputerPlayer(
          connect: () async => FirstLegalMoveEngine(
            script: ['e7e5'],
            delay: const Duration(seconds: 3),
          ),
        ),
      ),
    ),
  );
  await startComputerGame(tester, side: 'Bianco');
  await tester.pumpAndSettle(const Duration(seconds: 1));
  await _tap(tester, 'e2', 'e4');
  await tester.pump(const Duration(milliseconds: 100));
  expect(find.text('Il computer sta pensando…'), findsOneWidget);
}

Move? _premove(WidgetTester tester) =>
    tester.widget<Chessboard>(find.byType(Chessboard)).controller.premove;

void main() {
  testWidgets(
    'RF-08 la premossa fatta mentre il computer pensa viene giocata',
    (tester) async {
      await _thinkingAfterE4(tester);
      await _tap(tester, 'g1', 'f3');
      expect(_premove(tester), isNotNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.textContaining('2. '), findsOneWidget);
      expect(_premove(tester), isNull);
      // Dopo la premossa il computer pensa di nuovo.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('RF-08 toccando una casa vuota la premossa si annulla', (
    tester,
  ) async {
    await _thinkingAfterE4(tester);
    await _tap(tester, 'g1', 'f3');
    expect(_premove(tester), isNotNull);
    await tester.tapAt(square(tester, 'a5'));
    await tester.pump();
    expect(_premove(tester), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.textContaining('2. '), findsNothing);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-08 una premossa diventata illegale viene scartata', (
    tester,
  ) async {
    await _thinkingAfterE4(tester);
    await _tap(tester, 'e4', 'e5');
    expect(_premove(tester), isNotNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.textContaining('2. '), findsNothing);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(_premove(tester), isNull);
  });

  testWidgets('RF-08 con la premossa spenta la scacchiera resta ferma', (
    tester,
  ) async {
    await _thinkingAfterE4(tester, premove: false);
    await _tap(tester, 'g1', 'f3');
    expect(_premove(tester), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.textContaining('2. '), findsNothing);
  });
}
