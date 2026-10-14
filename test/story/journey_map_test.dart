import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/path/path_controller.dart';
import 'package:rokko/story/journey_map.dart';
import 'package:rokko/story/story.dart';
import 'package:rokko/story/story_controller.dart';
import 'package:rokko/story/story_page.dart';
import 'package:rokko/theme/rokko_mascot.dart';
import 'package:rokko/theme/rokko_theme.dart';

void main() {
  late Directory dir;
  late PathController path;
  late StoryController story;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('journeymap');
    path = PathController(File('${dir.path}/path.json'));
    story = StoryController(File('${dir.path}/story.json'));
    await path.load();
    await story.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: RokkoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: StoryPage(path: path, story: story),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder place(String id) => find.byKey(ValueKey('journey-$id'));

  test(
    'il sentiero va a serpentina: le righe dispari si percorrono a ritroso',
    () {
      expect(
        [for (var i = 0; i < 9; i++) JourneyMap.columnOf(i)],
        [
          0, 1, 2, //
          2, 1, 0,
          0, 1, 2,
        ],
      );
    },
  );

  testWidgets('la mappa ha un luogo per capitolo, con il nome', (tester) async {
    await show(tester);
    expect(find.byKey(const ValueKey('journey-map')), findsOneWidget);
    for (final c in storyChapters) {
      expect(place(c.id), findsOneWidget, reason: c.id);
    }
    expect(
      find.descendant(
        of: place('village'),
        matching: find.text('Il villaggio dei pezzi'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a inizio viaggio la torre è sul primo luogo, gli altri chiusi', (
    tester,
  ) async {
    await show(tester);
    expect(find.byType(RokkoMascot), findsOneWidget);
    expect(
      find.descendant(
        of: place('prologue'),
        matching: find.byType(RokkoMascot),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('journey-map')),
        matching: find.byIcon(Icons.lock_outline),
      ),
      findsNWidgets(storyChapters.length - 1),
    );
  });

  testWidgets('concluso un capitolo, il luogo ha la spunta e la torre avanza', (
    tester,
  ) async {
    await tester.runAsync(() => story.bossBeaten(storyChapters.first));
    await show(tester);
    expect(
      find.descendant(
        of: place('prologue'),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: place('village'), matching: find.byType(RokkoMascot)),
      findsOneWidget,
    );
  });

  testWidgets('i lettori di schermo sentono nome e stato del luogo', (
    tester,
  ) async {
    await show(tester);
    expect(
      tester.getSemantics(place('prologue')).label,
      'Il sentiero dei primi passi. In corso',
    );
    expect(
      tester.getSemantics(place('village')).label,
      'Il villaggio dei pezzi. Si apre concludendo il capitolo precedente',
    );
  });

  testWidgets('un tocco su un luogo porta al suo capitolo', (tester) async {
    await show(tester);
    final card = find.byKey(
      const ValueKey('story-chapter-castle'),
      skipOffstage: false,
    );
    expect(tester.getRect(card).top, greaterThan(2400 / 3));
    await tester.tap(place('castle'));
    await tester.pumpAndSettle();
    expect(tester.getRect(card).top, lessThan(2400 / 3));
  });

  test('con testi grandi le righe della mappa crescono', () {
    expect(
      JourneyMap.rowHeightFor(1.5),
      greaterThan(JourneyMap.rowHeightFor(1)),
    );
    expect(JourneyMap.rowHeightFor(0.8), JourneyMap.rowHeightFor(1));
  });
}
