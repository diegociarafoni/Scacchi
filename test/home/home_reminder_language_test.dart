import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/app_language.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/story/story_controller.dart';

import '../reminders/reminder_test.dart' show FakeScheduler;

void main() {
  late Directory dir;
  late ProgressController progress;
  late PathController path;
  late StoryController story;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('home_reminder_language');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
    await progress.updateSettings(
      progress.settings.copyWith(reminder: () => 19 * 60),
    );
    path = PathController(File('${dir.path}/path.json'));
    await path.load();
    story = StoryController(File('${dir.path}/story.json'));
    await story.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('cambiando lingua il promemoria si riprogramma tradotto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final settings = SettingsController.defaults();
    final scheduler = FakeScheduler();
    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: settings,
        builder: (context, s, _) => MaterialApp(
          locale: s.language.locale ?? const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeShell(
            settings: settings,
            progress: () async => progress,
            path: () async => path,
            story: () async => story,
            archive: () async => GameArchive(File('${dir.path}/games.json')),
            reminderScheduler: () => scheduler,
            computerAvailable: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final italian = lookupAppLocalizations(const Locale('it'));
    final english = lookupAppLocalizations(const Locale('en'));
    expect(scheduler.scheduled.last.channelName, italian.progressReminder);
    await settings.update(
      settings.value.copyWith(language: AppLanguage.english),
    );
    await tester.pumpAndSettle();
    expect(scheduler.scheduled.last.channelName, english.progressReminder);
    expect(italian.progressReminder, isNot(english.progressReminder));
  });
}
