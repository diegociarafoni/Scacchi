import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';

import '../board_marks_helpers.dart';
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

  testWidgets('RF-74 Suggerisci indica prima il pezzo, poi la mossa', (
    tester,
  ) async {
    await startWithCoach(tester);
    await tester.tap(find.text('Suggerisci'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Muovi'), findsOneWidget);
    await tester.tap(find.text('Suggerisci'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sposta'), findsOneWidget);
  });

  testWidgets('RF-56 Minaccia c\'è solo con l\'allenatore acceso', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Minaccia'), findsNothing);
    await tester.tap(find.text('Allenatore'));
    await tester.pumpAndSettle();
    expect(find.text('Minaccia'), findsOneWidget);
  });

  testWidgets('RF-56 Minaccia disegna la freccia rossa e sparisce alla mossa', (
    tester,
  ) async {
    await startWithCoach(tester);
    await tester.tap(find.text('Minaccia'));
    await tester.pumpAndSettle();
    final shapes = tester.widget<Chessboard>(find.byType(Chessboard)).shapes;
    expect(markArrows(shapes), hasLength(1));
    expect(find.textContaining('giocherebbe'), findsOneWidget);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(tester.widget<Chessboard>(find.byType(Chessboard)).shapes, isEmpty);
  });

  Map<Square, Annotation> badges(WidgetTester tester) =>
      tester.widget<Chessboard>(find.byType(Chessboard)).annotations;

  testWidgets('RF-74 Suggerisci c\'è anche con l\'allenatore spento', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Suggerisci'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Muovi'), findsOneWidget);
    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
  });

  testWidgets('RF-74 il suggerimento si vede sulla scacchiera', (tester) async {
    await startWithCoach(tester);
    Set<Shape> shapes() =>
        tester.widget<Chessboard>(find.byType(Chessboard)).shapes;
    expect(shapes(), isEmpty);
    await tester.tap(find.text('Suggerisci'));
    await tester.pumpAndSettle();
    expect(markCircles(shapes()), hasLength(1));
    expect(markArrows(shapes()), isEmpty);
    await tester.tap(find.text('Suggerisci'));
    await tester.pumpAndSettle();
    expect(markArrows(shapes()), hasLength(1));
    expect(markCircles(shapes()), hasLength(2));
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(shapes(), isEmpty);
  });

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

  testWidgets('RF-72 spegnendo l\'allenatore il giudizio sparisce', (
    tester,
  ) async {
    await startWithCoach(tester);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(badges(tester), isNotEmpty);
    await tester.tap(find.text('Allenatore'));
    await tester.pumpAndSettle();
    expect(badges(tester), isEmpty);
  });

  testWidgets('RF-73 il primo tocco spiega a cosa serve l\'allenatore', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Allenatore'));
    await tester.pump();
    expect(
      find.textContaining('Allenatore attivo: ti avviso se sbagli una mossa'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.school), findsOneWidget);
    await tester.tap(find.text('Allenatore'));
    await tester.pump();
    expect(find.text('Allenatore disattivato.'), findsOneWidget);
    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('le etichette dei comandi non si toccano a $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await startWithCoach(tester);
      final labels = [
        for (final t in [
          'Nuova',
          'Annulla',
          'Gira',
          'Patta',
          'Abbandona',
          'Allenatore',
          'Suggerisci',
        ])
          tester.getRect(find.text(t)),
      ];
      for (var i = 0; i + 1 < labels.length; i++) {
        expect(
          labels[i + 1].left - labels[i].right,
          greaterThanOrEqualTo(4),
          reason: 'etichette ${i + 1} e ${i + 2}',
        );
      }
    });
  }
}
