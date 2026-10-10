import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';

import '../test/engine/process_transport.dart';

Offset _square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> _tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(_square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(_square(tester, uci.substring(2, 4)));
  await tester.pump();
}

/// Attende un widget che dipende dalla risposta del processo Stockfish.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
}

Future<void> _startComputerGame(
  WidgetTester tester, {
  required String side,
  int level = 1,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: GamePage(
        computerAvailable: true,
        createComputer: () => ComputerPlayer(connect: ProcessTransport.start),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Nuova'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Computer'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(side));
  final slider = tester.getRect(find.byType(Slider));
  final step = (slider.width - 48) / 7;
  await tester.tapAt(
    Offset(slider.left + 24 + step * (level - 1), slider.center.dy),
  );
  await tester.pumpAndSettle();
  expect(find.textContaining('Livello $level:'), findsOneWidget);
  await tester.tap(find.text('Gioca'));
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'contro il computer',
    skip: ProcessTransport.findBinary() == null
        ? 'Stockfish non installato (impostare STOCKFISH_PATH)'
        : null,
    () {
      testWidgets('RF-20 col Bianco, il computer risponde alla mossa', (
        tester,
      ) async {
        await _startComputerGame(tester, side: 'Bianco');
        expect(find.textContaining('Computer, livello 1'), findsOneWidget);
        await _tapMove(tester, 'e2e4');
        await _waitFor(tester, find.text('Muove il Bianco.'));
        expect(find.text('1. e4'), findsOneWidget);
      });

      testWidgets('RF-20 col Nero, il computer muove per primo', (
        tester,
      ) async {
        await _startComputerGame(tester, side: 'Nero');
        await _waitFor(tester, find.text('Muove il Nero.'));
        expect(find.textContaining('1. '), findsOneWidget);
      });

      testWidgets('RF-21 la scacchiera è bloccata mentre il computer pensa', (
        tester,
      ) async {
        await _startComputerGame(tester, side: 'Bianco', level: 8);
        await _tapMove(tester, 'e2e4');
        expect(find.text('Il computer sta pensando…'), findsOneWidget);
        await _tapMove(tester, 'd2d4');
        await _waitFor(tester, find.text('Muove il Bianco.'));
        expect(find.text('1. e4'), findsOneWidget);
        expect(find.textContaining('d4'), findsNothing);
      });

      testWidgets('annullare ritira la mossa e la risposta del computer', (
        tester,
      ) async {
        await _startComputerGame(tester, side: 'Bianco');
        await _tapMove(tester, 'e2e4');
        await _waitFor(tester, find.text('Muove il Bianco.'));
        await tester.tap(find.text('Annulla'));
        await tester.pumpAndSettle();
        expect(find.text('Muove il Bianco.'), findsOneWidget);
        expect(find.text('1. e4'), findsNothing);
      });

      testWidgets('RF-25 il computer rifiuta la patta in posizione pari', (
        tester,
      ) async {
        await _startComputerGame(tester, side: 'Bianco', level: 8);
        await _tapMove(tester, 'e2e4');
        await _waitFor(tester, find.text('Muove il Bianco.'));
        await tester.tap(find.text('Patta'));
        await _waitFor(tester, find.text('Il computer rifiuta la patta.'));
      });
    },
  );
}
