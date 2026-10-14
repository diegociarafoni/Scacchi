import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/endgames/drills.dart';
import 'package:rokko/endgames/endgame_controller.dart';
import 'package:rokko/endgames/endgames_page.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/home/home_shell.dart';
import 'package:rokko/progress/progress_controller.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/settings/settings.dart';

import '../computer_fakes.dart';
import '../localized_app.dart';

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

  Future<void> openHome(WidgetTester tester, {required bool computer}) async {
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
          endgames: () async => endgames,
          reminderScheduler: () => null,
          computerAvailable: computer,
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RF-86 senza motore la voce Finali non compare', (tester) async {
    await openHome(tester, computer: false);
    expect(find.text('Finali'), findsNothing);
  });

  testWidgets('RF-86 dalla Home si aprono i finali', (tester) async {
    await openHome(tester, computer: true);
    await tester.scrollUntilVisible(
      find.text('Finali'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Finali'));
    await tester.pumpAndSettle();
    expect(find.byType(EndgamesPage), findsOneWidget);
    expect(find.text(endgameDrills.first.title), findsOneWidget);
  });
}
