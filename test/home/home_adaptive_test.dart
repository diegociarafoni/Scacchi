import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/home/home_page.dart';
import 'package:rokko/home/home_shell.dart';
import 'package:rokko/home/learn_page.dart';
import 'package:rokko/path/path_controller.dart';
import 'package:rokko/progress/progress_controller.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/story/story_controller.dart';
import 'package:rokko/theme/adaptive.dart';

import '../localized_app.dart';

void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('home_adaptive');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester, Size logical) async {
    tester.view
      ..physicalSize = logical * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: SettingsController.defaults(),
          progress: () async => progress,
          path: () async => PathController(File('${dir.path}/path.json')),
          story: () async => StoryController(File('${dir.path}/story.json')),
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          reminderScheduler: () => null,
          computerAvailable: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('classi di larghezza', () {
    test('compatta sotto 600, media fino a 840, estesa da 840', () {
      expect(WindowSize.forWidth(360), WindowSize.compact);
      expect(WindowSize.forWidth(599.9), WindowSize.compact);
      expect(WindowSize.forWidth(600), WindowSize.medium);
      expect(WindowSize.forWidth(839.9), WindowSize.medium);
      expect(WindowSize.forWidth(840), WindowSize.expanded);
    });
  });

  testWidgets('telefono e schermo diviso stretto: barra in basso', (
    tester,
  ) async {
    await show(tester, const Size(393, 852));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('pieghevole chiuso o finestra media: barra in basso', (
    tester,
  ) async {
    await show(tester, const Size(700, 900));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('tablet in orizzontale: colonna laterale con le quattro schede', (
    tester,
  ) async {
    await show(tester, const Size(1180, 820));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    for (final label in ['Home', 'Puzzle', 'Impara', 'Tu']) {
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('la colonna laterale cambia scheda come la barra', (
    tester,
  ) async {
    await show(tester, const Size(1180, 820));
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Impara'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LearnPage), findsOneWidget);
  });

  testWidgets('su schermo largo il contenuto non supera la larghezza massima', (
    tester,
  ) async {
    await show(tester, const Size(1600, 900));
    final width = tester.getSize(find.byType(HomePage)).width;
    expect(width, lessThanOrEqualTo(contentMaxWidth));
  });
}
