import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/story/story.dart';
import 'package:scacchi/story/story_controller.dart';
import 'package:scacchi/story/story_page.dart';

import '../localized_app.dart';

void main() {
  late Directory dir;
  late PathController path;
  late StoryController story;
  final first = storyChapters.first;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('story');
    path = PathController(File('${dir.path}/path.json'));
    story = StoryController(File('${dir.path}/story.json'));
    await path.load();
    await story.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> finishLessons(WidgetTester tester) async {
    for (final s in first.pathChapter.stages.where((s) => !s.isGuardian)) {
      await tester.runAsync(() => path.complete(s, 3, Duration.zero));
    }
  }

  /// I salvataggi su file avvengono fuori dal tempo finto dei test.
  Future<void> tapAndSave(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    // Il salvataggio ha più passi su file: ognuno ha bisogno del tempo vero.
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> show(
    WidgetTester tester, {
    PlayStoryBoss? boss,
    PlayStoryPuzzles? puzzles,
    Locale locale = const Locale('it'),
  }) async {
    phone(tester);
    await tester.pumpWidget(
      localizedApp(
        locale: locale,
        home: StoryPage(
          path: path,
          story: story,
          playBoss: boss,
          playPuzzles: puzzles,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RG-13 mostra il racconto del primo capitolo e blocca il resto', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('Il villaggio dei pezzi'), findsOneWidget);
    expect(find.textContaining('Arrivi al villaggio'), findsOneWidget);
    expect(find.text('Le porte della città'), findsOneWidget);
    expect(
      find.text('Si apre concludendo il capitolo precedente'),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'^Lezioni: 0 su \d+, da fare')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('^Puzzle del capitolo: 0 su 3, bloccato')),
      findsOneWidget,
    );
  });

  testWidgets('RG-13 i testi seguono la lingua', (tester) async {
    await show(tester, locale: const Locale('en'));
    expect(find.text('The village of the pieces'), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
  });

  testWidgets('RG-13 i puzzle risolti si sommano e aprono la sfida', (
    tester,
  ) async {
    int? asked;
    await show(
      tester,
      puzzles: (context, chapter, remaining) async {
        asked = remaining;
        return 2;
      },
    );
    await finishLessons(tester);
    await tester.pumpAndSettle();
    await tapAndSave(tester, find.textContaining('Puzzle del capitolo'));
    expect(asked, first.puzzleCount);
    expect(story.state.puzzlesSolved(first.id), 2);
    expect(
      find.bySemanticsLabel(RegExp('^Puzzle del capitolo: 2 su 3, da fare')),
      findsOneWidget,
    );
    await tapAndSave(tester, find.textContaining('Puzzle del capitolo'));
    expect(asked, 1);
    expect(story.state.puzzlesSolved(first.id), 3);
    expect(
      find.bySemanticsLabel(RegExp('^Sfida a Pino, da fare')),
      findsOneWidget,
    );
  });

  testWidgets('RG-13 un passo bloccato non si apre', (tester) async {
    var called = false;
    await show(
      tester,
      puzzles: (context, chapter, remaining) async {
        called = true;
        return 1;
      },
    );
    await tester.tap(find.textContaining('Puzzle del capitolo'));
    await tester.pumpAndSettle();
    expect(called, isFalse);
  });

  testWidgets(
    'RG-13 battere il bot conclude il capitolo e apre il successivo',
    (tester) async {
      Bot? played;
      await show(
        tester,
        boss: (context, bot) async {
          played = bot;
          return true;
        },
      );
      await finishLessons(tester);
      await tester.runAsync(
        () => story.puzzlesSolved(first, first.puzzleCount),
      );
      await tester.pumpAndSettle();
      await tapAndSave(tester, find.textContaining('Sfida a Pino'));
      expect(played?.id, 'pino');
      expect(story.state.isBossBeaten(first.id), isTrue);
      expect(find.text('Hai battuto Pino!'), findsOneWidget);
      expect(find.textContaining('Il villaggio ti saluta'), findsOneWidget);
    },
  );

  testWidgets('RG-13 sconfitta: nessun avanzamento, si può riprovare', (
    tester,
  ) async {
    await show(tester, boss: (context, bot) async => false);
    await finishLessons(tester);
    await tester.runAsync(() => story.puzzlesSolved(first, first.puzzleCount));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Sfida a Pino'));
    await tester.pumpAndSettle();
    expect(story.state.isBossBeaten(first.id), isFalse);
    expect(find.textContaining('Pino resiste ancora'), findsOneWidget);
  });

  testWidgets('RG-13 senza motore la sfida mostra un avviso', (tester) async {
    await show(tester);
    await finishLessons(tester);
    await tester.runAsync(() => story.puzzlesSolved(first, first.puzzleCount));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Sfida a Pino'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Le sfide si giocano dove gira'),
      findsOneWidget,
    );
  });

  testWidgets('RG-13 Continua porta al primo passo da fare', (tester) async {
    var puzzlesOpened = false;
    await show(
      tester,
      puzzles: (context, chapter, remaining) async {
        puzzlesOpened = true;
        return 0;
      },
    );
    await finishLessons(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();
    expect(puzzlesOpened, isTrue);
  });

  testWidgets('RG-13 un passo già fatto non si riapre', (tester) async {
    var called = false;
    await show(
      tester,
      puzzles: (context, chapter, remaining) async {
        called = true;
        return 1;
      },
    );
    await finishLessons(tester);
    await tester.runAsync(() => story.puzzlesSolved(first, first.puzzleCount));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Puzzle del capitolo'));
    await tester.pumpAndSettle();
    expect(called, isFalse);
  });
}
