import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/masters/guess_page.dart';
import 'package:scacchi/masters/master_game_page.dart';
import 'package:scacchi/masters/master_games.dart';
import 'package:scacchi/masters/masters_controller.dart';
import 'package:scacchi/masters/masters_page.dart';

Offset _square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> _tapMove(WidgetTester tester, String from, String to) async {
  await tester.tapAt(_square(tester, from));
  await tester.pump();
  await tester.tapAt(_square(tester, to));
  await tester.pumpAndSettle();
  // La risposta del maestro arriva dopo una breve pausa.
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  late Directory dir;
  late MastersController controller;
  final legal = masterGames.firstWhere((g) => g.id == 'legal-1750');

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('maestri-pagine');
    controller = MastersController(File('${dir.path}/masters.json'));
    await controller.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('RF-87 l\'elenco mostra le partite con giocatori e anno', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(home: MastersPage(controller: controller)),
    );
    expect(find.text('Grandi maestri'), findsOneWidget);
    expect(find.textContaining('Légal'), findsWidgets);
    expect(find.textContaining('1750'), findsWidgets);
  });

  testWidgets('RF-87 si sfoglia mossa per mossa con il commento', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MasterGamePage(game: legal, controller: controller),
      ),
    );
    expect(find.text(legal.intro), findsOneWidget);
    expect(find.byKey(const Key('master-ply')).evaluate().length, 1);
    expect(find.text('Posizione iniziale'), findsOneWidget);

    await tester.tap(find.byKey(const Key('master-next')));
    await tester.pumpAndSettle();
    expect(find.text('1. e4'), findsWidgets);

    await tester.tap(find.byKey(const Key('master-last')));
    await tester.pumpAndSettle();
    expect(find.textContaining('7. Nd5#'), findsWidgets);
    expect(find.text(legal.notes[legal.moves.length]!), findsOneWidget);

    await tester.tap(find.byKey(const Key('master-first')));
    await tester.pumpAndSettle();
    expect(find.text('Posizione iniziale'), findsOneWidget);
  });

  testWidgets('RF-88 si indovinano le mosse e si salva il punteggio', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: GuessPage(game: legal, side: Side.white, controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await _tapMove(tester, 'e2', 'e4');
    expect(find.textContaining('Come il maestro'), findsOneWidget);
    await _tapMove(tester, 'g1', 'f3');
    await _tapMove(tester, 'f1', 'c4');
    await _tapMove(tester, 'b1', 'c3');
    await _tapMove(tester, 'f3', 'e5');
    await _tapMove(tester, 'c4', 'f7');
    await _tapMove(tester, 'c3', 'd5');
    expect(find.text('Partita conclusa'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.bySemanticsLabel('3 stelle su 3'), findsOneWidget);
    expect(controller.progress.bestPercent('legal-1750'), 100);
  });

  testWidgets('RF-88 una mossa diversa mostra quella del maestro', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: GuessPage(game: legal, side: Side.white, controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await _tapMove(tester, 'd2', 'd4');
    expect(find.textContaining('Il maestro ha giocato 1. e4'), findsOneWidget);
    expect(find.textContaining('Risposta: 1… e5'), findsOneWidget);
  });

  testWidgets('RF-88 nel profilo bambino non compaiono percentuali', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: GuessPage(
          game: legal,
          side: Side.white,
          controller: controller,
          simple: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _tapMove(tester, 'd2', 'd4');
    expect(find.textContaining('%'), findsNothing);
  });
}
