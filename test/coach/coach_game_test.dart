import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart';
import '../computer_game_test.dart' show tapMove;

/// Il Bianco vale 0, il Nero +900: ogni mossa del Bianco è un errore grave.
int _blunderScore(String fen) =>
    Setup.parseFen(fen).turn == Side.white ? 0 : 900;

Widget app() => MaterialApp(
  home: GamePage(
    settings: SettingsController.defaults(),
    computerAvailable: true,
    now: () => TestWidgetsFlutterBinding.instance.clock.now(),
    createComputer: () => ComputerPlayer(
      connect: () async => FirstLegalMoveEngine(scoreByFen: _blunderScore),
    ),
  ),
);

Future<void> startWithCoach(WidgetTester tester) async {
  await tester.pumpWidget(app());
  await startComputerGame(tester, side: 'Bianco');
  await tester.pumpAndSettle(const Duration(seconds: 1));
  await tester.tap(find.text('Allenatore'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('RF-73 senza allenatore l\'errore non viene segnalato', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Riprova'), findsNothing);
    expect(find.textContaining('1. '), findsOneWidget);
  });

  testWidgets('RF-73 l\'errore avverte e Riprova rimette la mossa', (
    tester,
  ) async {
    await startWithCoach(tester);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Riprova'), findsOneWidget);
    expect(find.text('Continua'), findsOneWidget);
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.textContaining('1. '), findsNothing);
  });

  testWidgets('RF-73 Continua lascia la mossa e risponde il computer', (
    tester,
  ) async {
    await startWithCoach(tester);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Riprova'), findsNothing);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.textContaining('1. '), findsOneWidget);
  });

  testWidgets('RF-74 Aiuto indica prima il pezzo, poi la mossa', (
    tester,
  ) async {
    await startWithCoach(tester);
    await tester.tap(find.text('Aiuto'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pezzo in'), findsOneWidget);
    await tester.tap(find.text('Aiuto'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Prova'), findsOneWidget);
  });

  Map<Square, Annotation> badges(WidgetTester tester) =>
      tester.widget<Chessboard>(find.byType(Chessboard)).annotations;

  testWidgets('RF-72 il giudizio compare sulla casa della mossa', (
    tester,
  ) async {
    await startWithCoach(tester);
    expect(badges(tester), isEmpty);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(badges(tester).keys, [Square.e4]);
    expect(badges(tester)[Square.e4]!.symbol, '??');
  });

  testWidgets('RF-72 Riprova toglie il giudizio con la mossa', (tester) async {
    await startWithCoach(tester);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(badges(tester), isEmpty);
  });

  testWidgets('RF-72 senza allenatore nessun giudizio sulla scacchiera', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(badges(tester), isEmpty);
  });
}
