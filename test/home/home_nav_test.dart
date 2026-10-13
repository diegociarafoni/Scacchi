import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/home/home_page.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/home/learn_page.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/story/story_controller.dart';

import '../localized_app.dart';

void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('home_nav');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  Future<void> show(
    WidgetTester tester, {
    SettingsController? settings,
    bool computer = true,
  }) async {
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: settings ?? SettingsController.defaults(),
          progress: () async => progress,
          path: () async => PathController(File('${dir.path}/path.json')),
          story: () async => StoryController(File('${dir.path}/story.json')),
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          reminderScheduler: () => null,
          computerAvailable: computer,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la barra ha Home, Puzzle, Impara e Tu, e si parte dalla Home', (
    tester,
  ) async {
    await show(tester);
    for (final label in ['Home', 'Puzzle', 'Impara', 'Tu']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
    expect(find.text('Aperture'), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(Chessboard), findsNothing);
  });

  testWidgets('«Nuova partita» apre la scacchiera con la scelta già aperta', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.byKey(const Key('home-play')));
    await tester.pumpAndSettle();
    expect(find.byType(Chessboard), findsOneWidget);
    expect(find.text('Senza tempo'), findsOneWidget);
  });

  testWidgets(
    'Impara raccoglie Storia, Aperture, Finali, Maestri e Minigiochi',
    (tester) async {
      await show(tester);
      await tester.tap(tab('Impara'));
      await tester.pumpAndSettle();
      expect(find.byType(LearnPage), findsOneWidget);
      for (final id in [
        'story',
        'openings',
        'endgames',
        'masters',
        'minigames',
      ]) {
        expect(find.byKey(Key('learn-$id')), findsOneWidget, reason: id);
      }
      expect(find.byKey(const Key('learn-hero')), findsOneWidget);
    },
  );

  testWidgets('senza motore mancano finali e tornei', (tester) async {
    await show(tester, computer: false);
    expect(find.byKey(const Key('home-feature-endgames')), findsNothing);
    expect(find.byKey(const Key('home-feature-tournaments')), findsNothing);
    expect(find.byKey(const Key('home-recommended')), findsNothing);
  });

  testWidgets('profilo bambino: niente aperture né ricerca', (tester) async {
    final settings = SettingsController.defaults();
    await settings.update(settings.value.copyWith(kidMode: true));
    await show(tester, settings: settings);
    expect(find.byKey(const Key('home-search')), findsNothing);
    expect(find.byKey(const Key('home-feature-openings')), findsNothing);
    await tester.tap(tab('Impara'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('learn-openings')), findsNothing);
    expect(find.byKey(const Key('learn-story')), findsOneWidget);
  });

  testWidgets('«Puzzle» dalla Home porta alla scheda Puzzle', (tester) async {
    await show(tester);
    final tile = find.byKey(const Key('home-feature-puzzles'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find
          .descendant(
            of: find.byType(HomePage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(tile);
    // La scheda Puzzle carica la raccolta: qui basta vedere il cambio scheda.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });
}
