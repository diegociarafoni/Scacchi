@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/story/story.dart';
import 'package:scacchi/story/story_controller.dart';
import 'package:scacchi/story/story_page.dart';
import 'package:scacchi/theme/rokko_theme.dart';

import '../support/devices.dart';

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

/// Tema e testi reali dell'app; [textScale] 1,3 simula il testo ingrandito.
Future<void> _pump(
  WidgetTester tester,
  Device device,
  Widget home, {
  Brightness brightness = Brightness.light,
  bool kid = false,
  double textScale = 1,
}) async {
  device.apply(tester);
  await tester.pumpWidget(
    SettingsScope(
      controller: SettingsController.defaults()
        ..value = AppSettings(kidMode: kid),
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? RokkoTheme.dark()
            : RokkoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _golden(WidgetTester tester, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/$name.png'),
);

void main() {
  late Directory dir;
  late PathController path;
  late StoryController story;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('golden-screens');
    path = PathController(File('${dir.path}/path.json'));
    story = StoryController(File('${dir.path}/story.json'));
    await path.load();
    await story.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> tu(
    WidgetTester tester,
    Device device, {
    Brightness brightness = Brightness.light,
    bool kid = false,
    double textScale = 1,
  }) async {
    final progress = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
    );
    await tester.runAsync(progress.load);
    await _pump(
      tester,
      device,
      HomeShell(
        settings: SettingsController.defaults()
          ..value = AppSettings(kidMode: kid),
        progress: () async => progress,
        path: () async => path,
        archive: () async => GameArchive(File('${dir.path}/games.json')),
      ),
      brightness: brightness,
      kid: kid,
      textScale: textScale,
    );
    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
  }

  testWidgets('scheda Tu', skip: _skip != null, (tester) async {
    await tu(tester, Device.phoneMedium);
    await _golden(tester, 'tu-telefono-medio');
  });

  testWidgets('scheda Tu in tema scuro', skip: _skip != null, (tester) async {
    await tu(tester, Device.phoneSmall, brightness: Brightness.dark);
    await _golden(tester, 'tu-scuro-telefono-piccolo');
  });

  testWidgets('scheda Tu col testo al 130%', skip: _skip != null, (
    tester,
  ) async {
    await tu(tester, Device.phoneSmall, textScale: 1.3);
    await _golden(tester, 'tu-testo-130-telefono-piccolo');
  });

  testWidgets('scheda Tu, profilo bambino', skip: _skip != null, (
    tester,
  ) async {
    await tu(tester, Device.phoneMedium, kid: true);
    await _golden(tester, 'tu-bambino-telefono-medio');
  });

  testWidgets('Storia', skip: _skip != null, (tester) async {
    await _pump(
      tester,
      Device.phoneMedium,
      StoryPage(path: path, story: story),
      brightness: Brightness.dark,
    );
    await _golden(tester, 'storia-scuro-telefono-medio');
  });

  testWidgets('Storia: foglio di passaggio', skip: _skip != null, (
    tester,
  ) async {
    final lessons = storyChapters.first.pathChapter.stages
        .where((s) => !s.isGuardian)
        .toList();
    await tester.runAsync(() async {
      for (final s in lessons.take(lessons.length - 1)) {
        await path.complete(s, 3, Duration.zero);
      }
    });
    await _pump(
      tester,
      Device.phoneMedium,
      StoryPage(
        path: path,
        story: story,
        playLesson: (context, stage) async {
          await path.complete(stage, 3, Duration.zero);
          return 3;
        },
        playPuzzles: (c, ch, r) async => 0,
      ),
      brightness: Brightness.dark,
    );
    final f = find.textContaining(
      'Lezioni: ${lessons.length - 1} su ${lessons.length}',
    );
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('story-passage')), findsOneWidget);
    await _golden(tester, 'storia-passaggio-scuro-telefono-medio');
  });
}
