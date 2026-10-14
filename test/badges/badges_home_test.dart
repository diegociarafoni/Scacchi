import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/badges/badges_page.dart';
import 'package:rokko/endgames/endgame_controller.dart';
import 'package:rokko/home/home_shell.dart';
import 'package:rokko/masters/masters_controller.dart';
import 'package:rokko/path/curriculum.dart';
import 'package:rokko/path/path_controller.dart';
import 'package:rokko/progress/activity.dart';
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
  late EndgameController endgames;
  late MastersController masters;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('badges_home');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
    path = PathController(File('${dir.path}/path.json'));
    await path.load();
    story = StoryController(File('${dir.path}/story.json'));
    await story.load();
    endgames = EndgameController(File('${dir.path}/endgames.json'));
    await endgames.load();
    masters = MastersController(File('${dir.path}/masters.json'));
    await masters.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester, {SettingsController? settings}) async {
    tester.view.physicalSize = const Size(1170, 5000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: settings ?? SettingsController.defaults(),
          progress: () async => progress,
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          path: () async => path,
          story: () async => story,
          endgames: () async => endgames,
          masters: () async => masters,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
  }

  testWidgets('RG-17 la scheda Tu ha la voce Badge che apre la raccolta', (
    tester,
  ) async {
    await show(tester);
    await tester.scrollUntilVisible(
      find.text('Badge'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Badge'));
    await tester.pumpAndSettle();
    expect(find.byType(BadgesPage), findsOneWidget);
  });

  testWidgets('RG-17 il profilo bambino non ha i badge', (tester) async {
    final settings = SettingsController.defaults();
    await settings.update(settings.value.copyWith(kidMode: true));
    await show(tester, settings: settings);
    expect(find.text('Badge', skipOffstage: false), findsNothing);
  });

  testWidgets('RG-17 uno sblocco mostra un avviso con il pulsante Vedi', (
    tester,
  ) async {
    await show(tester);
    await tester.runAsync(
      () => progress.record(
        const GamePlayed(
          result: GameResult.win,
          highlights: {GameHighlight.enPassant},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Alla francese'), findsOneWidget);
    await tester.tap(find.text('Vedi'));
    await tester.pumpAndSettle();
    expect(find.byType(BadgesPage), findsOneWidget);
  });

  testWidgets('RG-17 nel profilo bambino lo sblocco non disturba', (
    tester,
  ) async {
    final settings = SettingsController.defaults();
    await settings.update(settings.value.copyWith(kidMode: true));
    await show(tester, settings: settings);
    await tester.runAsync(
      () => progress.record(
        const GamePlayed(
          result: GameResult.win,
          highlights: {GameHighlight.enPassant},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SnackBar), findsNothing);
    expect(progress.badges.keys, contains('en_passant'));
  });

  testWidgets('RG-17 le lezioni già fatte sbloccano il capitolo all\'avvio', (
    tester,
  ) async {
    final chapter = curriculum.first;
    await tester.runAsync(() async {
      for (final s in chapter.stages.where((s) => !s.isGuardian)) {
        await path.complete(s, 2, Duration.zero);
      }
    });
    await show(tester);
    expect(progress.badges.keys, contains('chapter_${chapter.id}'));
  });
}
