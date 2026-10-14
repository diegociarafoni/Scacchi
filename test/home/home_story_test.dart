import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/home/home_shell.dart';
import 'package:rokko/path/path_controller.dart';
import 'package:rokko/progress/progress_controller.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/story/story_controller.dart';

import '../localized_app.dart';

void main() {
  late Directory dir;
  late ProgressController progress;
  late PathController path;
  late StoryController story;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('home_story');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
    path = PathController(File('${dir.path}/path.json'));
    await path.load();
    story = StoryController(File('${dir.path}/story.json'));
    await story.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('RG-13 dalla Home si apre la storia', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: SettingsController.defaults(),
          progress: () async => progress,
          path: () async => path,
          story: () async => story,
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          reminderScheduler: () => null,
          computerAvailable: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storia'));
    await tester.pumpAndSettle();
    expect(find.text('Il sentiero dei primi passi'), findsOneWidget);
    expect(find.text('Continua'), findsOneWidget);
  });
}
