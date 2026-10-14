import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/tournament/tournament.dart';
import 'package:scacchi/tournament/tournament_controller.dart';
import 'package:scacchi/tournament/tournament_page.dart';

import '../localized_app.dart';
import 'tournament_test.dart' show bots;

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  late Directory dir;
  late TournamentController controller;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('tornei');
    controller = TournamentController(
      File('${dir.path}/tornei.json'),
      clock: () => DateTime(2026, 10, 11, 18),
      random: Random(1),
    );
    await controller.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester, {PlayTournamentGame? play}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: TournamentPage(
          controller: controller,
          bots: bots,
          userElo: 1000,
          play: play,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RG-09 scelta della formula e degli avversari', (tester) async {
    await show(tester);
    expect(find.text('Girone all\'italiana'), findsOneWidget);
    expect(find.text('Eliminazione diretta'), findsOneWidget);
    await tester.tap(find.text('4 giocatori'));
    await tester.pump();
    // I tre bot più vicini a 1000 Elo.
    expect(find.text('Esordiente · 900'), findsOneWidget);
    expect(find.text('Dilettante · 1100'), findsOneWidget);
    expect(find.text('Giocatore di circolo · 1350'), findsOneWidget);
    await tester.tap(find.text('Eliminazione diretta'));
    await tester.pump();
    expect(find.text('6 giocatori'), findsNothing);
  });

  testWidgets('RG-09 girone: classifica e prossima partita', (tester) async {
    final played = <UserGame>[];
    await show(
      tester,
      play: (context, game) async {
        played.add(game);
        return 1;
      },
    );
    await tester.tap(find.text('4 giocatori'));
    await tester.pump();
    await tester.tap(find.text('Inizia il torneo'));
    await settle(tester);
    expect(find.text('Classifica'), findsOneWidget);
    expect(find.textContaining('Turno 1 di 3'), findsOneWidget);
    await tester.tap(find.text('Gioca'));
    await settle(tester);
    expect(played, hasLength(1));
    expect(find.textContaining('Turno 2 di 3'), findsOneWidget);
    await tester.tap(find.text('Gioca'));
    await settle(tester);
    await tester.tap(find.text('Gioca'));
    await settle(tester);
    expect(find.text('Hai vinto il torneo!'), findsOneWidget);
    await tester.tap(find.text('Nuovo torneo'));
    await settle(tester);
    expect(find.text('Bacheca'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('1° posto'), 200);
    expect(find.textContaining('1° posto'), findsOneWidget);
  });

  testWidgets('RG-09 eliminazione diretta: tabellone per turni', (
    tester,
  ) async {
    await show(tester, play: (context, game) async => 0);
    await tester.tap(find.text('Eliminazione diretta'));
    await tester.pump();
    await tester.tap(find.text('8 giocatori'));
    await tester.pump();
    await tester.tap(find.text('Inizia il torneo'));
    await settle(tester);
    expect(find.text('Quarti di finale'), findsOneWidget);
    await tester.tap(find.text('Gioca'));
    await settle(tester);
    expect(find.text('Finale'), findsOneWidget);
    expect(find.textContaining('5° posto'), findsOneWidget);
  });

  testWidgets('senza motore la partita non parte e lo dice', (tester) async {
    await show(tester);
    await tester.tap(find.text('Inizia il torneo'));
    await settle(tester);
    await tester.tap(find.text('Gioca'));
    await tester.pump();
    expect(
      find.text(
        'Le partite del torneo non sono disponibili su '
        'questo dispositivo.',
      ),
      findsOneWidget,
    );
    expect(controller.current!.currentRound, 0);
  });

  testWidgets('abbandono con conferma', (tester) async {
    await show(tester);
    await tester.tap(find.text('Inizia il torneo'));
    await settle(tester);
    await tester.tap(find.byTooltip('Abbandona il torneo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbandona'));
    await settle(tester);
    expect(controller.current, isNull);
    expect(find.text('Inizia il torneo'), findsOneWidget);
  });

  testWidgets('la partita dell\'Armageddon è indicata', (tester) async {
    await show(tester, play: (context, game) async => 0.5);
    await tester.tap(find.text('Eliminazione diretta'));
    await tester.pump();
    await tester.tap(find.text('Inizia il torneo'));
    await settle(tester);
    await tester.tap(find.text('Gioca'));
    await settle(tester);
    expect(find.textContaining('Armageddon'), findsWidgets);
    final game = controller.current!.userGame!;
    expect(game.armageddon, isTrue);
    expect(Side.values, contains(game.color));
  });

  testWidgets('mentre il motore gioca tra i bot compare l\'avviso', (
    tester,
  ) async {
    final gate = Completer<double?>();
    controller = TournamentController(
      File('${dir.path}/altri.json'),
      clock: () => DateTime(2026, 10, 11, 18),
      random: Random(1),
      playBotGame: (w, b, seed) => gate.future,
    );
    await tester.runAsync(controller.load);
    await show(tester, play: (context, game) async => 1);
    await tester.tap(find.text('4 giocatori'));
    await tester.pump();
    await tester.tap(find.text('Inizia il torneo'));
    await settle(tester);
    expect(find.text('Si giocano le partite tra i bot…'), findsNothing);
    await tester.tap(find.text('Gioca'));
    // La barra di avanzamento è animata: niente pumpAndSettle.
    for (var i = 0; i < 100 && !controller.playingBots; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.playingBots, isTrue);
    expect(find.text('Si giocano le partite tra i bot…'), findsOneWidget);
    gate.complete(1);
    for (var i = 0; i < 100 && controller.playingBots; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await settle(tester);
    expect(find.text('Si giocano le partite tra i bot…'), findsNothing);
    expect(controller.current!.currentRound, greaterThan(0));
  });
}
