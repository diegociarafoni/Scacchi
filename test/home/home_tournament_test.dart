import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/home/home_shell.dart';
import 'package:rokko/progress/progress_controller.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/tournament/tournament_controller.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';
import '../localized_app.dart';

/// Lascia completare l'I/O su file, che nella zona finta dei test non avanza.
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
  late ProgressController progress;
  late TournamentController tournaments;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('home-tornei');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
    tournaments = TournamentController(
      File('${dir.path}/t.json'),
      random: Random(1),
    );
    await tournaments.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> openHome(WidgetTester tester, {bool computer = true}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: SettingsController.defaults()
            ..value = AppSettings(sound: false),
          progress: () async => progress,
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          tournaments: () async => tournaments,
          reminderScheduler: () => null,
          computerAvailable: computer,
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('senza motore la voce Tornei non compare', (tester) async {
    await openHome(tester, computer: false);
    expect(find.text('Tornei'), findsNothing);
  });

  testWidgets('la partita del torneo si gioca e l\'abbandono vale zero', (
    tester,
  ) async {
    await openHome(tester);
    await tester.tap(find.text('Tornei'));
    await settle(tester);
    await tester.tap(find.text('Inizia il torneo'));
    await settle(tester);
    await tester.tap(find.text('Gioca'));
    await settle(tester);
    expect(find.textContaining('Torneo ·'), findsOneWidget);
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbandona').last);
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(tournaments.current!.currentRound, 1);
  });

  testWidgets('uscire prima di muovere vale una sconfitta', (tester) async {
    await openHome(tester);
    await tester.tap(find.text('Tornei'));
    await settle(tester);
    await tester.tap(find.text('Inizia il torneo'));
    await settle(tester);
    await tester.tap(find.text('Gioca'));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(tournaments.current!.currentRound, 1);
  });
}
