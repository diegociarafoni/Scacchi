import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/story/story.dart';
import 'package:scacchi/story/story_controller.dart';
import 'package:scacchi/story/story_page.dart';
import 'package:scacchi/theme/rokko_theme.dart';

void main() {
  late Directory dir;
  late PathController path;
  late StoryController story;
  final first = storyChapters.first;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('storymap');
    path = PathController(File('${dir.path}/path.json'));
    story = StoryController(File('${dir.path}/story.json'));
    await path.load();
    await story.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    Locale locale = const Locale('it'),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          theme: RokkoTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: StoryPage(path: path, story: story),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> finishLessons() async {
    for (final s in first.pathChapter.stages.where((s) => !s.isGuardian)) {
      await path.complete(s, 3, Duration.zero);
    }
  }

  testWidgets('RG-13 il riepilogo ha una barra dei capitoli conclusi', (
    tester,
  ) async {
    await show(tester);
    final summary = find.byKey(const ValueKey('story-summary'));
    expect(summary, findsOneWidget);
    expect(
      find.descendant(
        of: summary,
        matching: find.text('0 capitoli su ${storyChapters.length}'),
      ),
      findsOneWidget,
    );
    final bar = find.descendant(
      of: summary,
      matching: find.byType(LinearProgressIndicator),
    );
    expect(tester.widget<LinearProgressIndicator>(bar).value, 0);
  });

  testWidgets('RG-13 il capitolo corrente è segnato «In corso»', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('In corso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(ValueKey('story-chapter-${first.id}')),
        matching: find.text('In corso'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'RG-13 il capitolo bloccato ha lucchetto e contorno tratteggiato',
    (tester) async {
      await show(tester);
      final second = storyChapters[1];
      final card = find.byKey(ValueKey('story-chapter-${second.id}'));
      await tester.scrollUntilVisible(card, 300);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('story-badge-${second.id}')),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('Si apre concludendo il capitolo precedente'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(ValueKey('story-dashed-${second.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('story-dashed-${first.id}')), findsNothing);
    },
  );

  testWidgets('RG-13 il badge del capitolo mostra il numero e poi la spunta', (
    tester,
  ) async {
    await show(tester);
    final badge = find.byKey(ValueKey('story-badge-${first.id}'));
    expect(
      find.descendant(of: badge, matching: find.text('1')),
      findsOneWidget,
    );
    await tester.runAsync(() async {
      await finishLessons();
      await story.bossBeaten(first);
      for (var i = 0; i < first.puzzleCount; i++) {
        await story.puzzlesSolved(first, 1);
      }
      for (final s in first.pathChapter.stages.where((s) => s.isGuardian)) {
        await path.complete(s, 3, Duration.zero);
      }
    });
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: badge, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
  });

  testWidgets('RG-13 i passi con un conteggio hanno la barra di avanzamento', (
    tester,
  ) async {
    await show(tester);
    final bar = find.byKey(ValueKey('story-step-progress-${first.id}-lessons'));
    expect(bar, findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(bar).value, 0);
    expect(
      find.byKey(ValueKey('story-step-progress-${first.id}-puzzles')),
      findsOneWidget,
    );
  });

  testWidgets('RG-13 i passi hanno un bersaglio di almeno 48 dp', (
    tester,
  ) async {
    await show(tester);
    await tester.runAsync(finishLessons);
    await tester.pumpAndSettle();
    final size = tester.getSize(
      find.ancestor(
        of: find.textContaining('Puzzle del capitolo'),
        matching: find.byType(InkWell),
      ),
    );
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('RG-13 con il testo al 130% non c\'è overflow', (tester) async {
    await show(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('testi del riepilogo in inglese', (tester) async {
    await show(tester, locale: const Locale('en'));
    expect(
      find.text('0 chapters out of ${storyChapters.length}'),
      findsOneWidget,
    );
    expect(find.text('In progress'), findsOneWidget);
  });
}
