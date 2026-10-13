import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/masters/master_games.dart';
import 'package:scacchi/masters/masters_controller.dart';
import 'package:scacchi/masters/masters_page.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';

import '../localized_app.dart';

void main() {
  late Directory dir;
  late ProgressController progress;
  late MastersController masters;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('home-maestri');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
    masters = MastersController(File('${dir.path}/m.json'));
    await masters.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> openHome(WidgetTester tester, {bool computer = false}) async {
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
          masters: () async => masters,
          reminderScheduler: () => null,
          computerAvailable: computer,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RF-87 la voce Grandi maestri c\'è anche senza motore', (
    tester,
  ) async {
    await openHome(tester);
    await tester.tap(find.text('Grandi maestri'));
    await tester.pumpAndSettle();
    expect(find.byType(MastersPage), findsOneWidget);
    expect(find.textContaining(masterGames.first.white), findsWidgets);
  });
}
