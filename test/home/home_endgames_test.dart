import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/endgames/drills.dart';
import 'package:scacchi/endgames/endgame_controller.dart';
import 'package:scacchi/endgames/endgames_page.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart';

void main() {
  late Directory dir;
  late ProgressController progress;
  late EndgameController endgames;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('home-finali');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
    endgames = EndgameController(File('${dir.path}/e.json'));
    await endgames.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> openTu(WidgetTester tester, {required bool computer}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          settings: SettingsController.defaults()
            ..value = AppSettings(sound: false),
          progress: () async => progress,
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          endgames: () async => endgames,
          reminderScheduler: () => null,
          computerAvailable: computer,
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        ),
      ),
    );
    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
  }

  testWidgets('RF-86 senza motore la voce Finali non compare', (tester) async {
    await openTu(tester, computer: false);
    expect(find.text('Finali'), findsNothing);
  });

  testWidgets('RF-86 dalla scheda Tu si aprono i finali', (tester) async {
    await openTu(tester, computer: true);
    await tester.tap(find.text('Finali'));
    await tester.pumpAndSettle();
    expect(find.byType(EndgamesPage), findsOneWidget);
    expect(find.text(endgameDrills.first.title), findsOneWidget);
  });
}
