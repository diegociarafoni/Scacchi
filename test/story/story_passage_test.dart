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
  final lessons = first.pathChapter.stages.where((s) => !s.isGuardian).toList();

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('passage');
    path = PathController(File('${dir.path}/path.json'));
    story = StoryController(File('${dir.path}/story.json'));
    await path.load();
    await story.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    PlayStoryBoss? boss,
    PlayStoryPuzzles? puzzles,
    PlayStoryLesson? lesson,
    void Function(StoryChapter chapter)? onChapterDone,
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
          theme: RokkoTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: StoryPage(
            path: path,
            story: story,
            playBoss: boss,
            playPuzzles: puzzles,
            playLesson: lesson,
            onChapterDone: onChapterDone,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> doneLessons({int except = 0}) async {
    for (final s in lessons.take(lessons.length - except)) {
      await path.complete(s, 3, Duration.zero);
    }
  }

  /// Tocca [f] e aspetta il salvataggio su file, che è I/O vero: si attende
  /// finché [until] è vero (senza un tempo fisso, che sotto carico non basta).
  Future<void> save(
    WidgetTester tester,
    Finder f, {
    required bool Function() until,
  }) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    for (var i = 0; i < 400 && (i == 0 || !until()); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
  }

  bool shown(Finder f) => f.evaluate().isNotEmpty;
  final passage = find.byKey(const ValueKey('story-passage'));

  testWidgets('RG-13 concluse le lezioni il foglio annuncia i puzzle', (
    tester,
  ) async {
    await tester.runAsync(() => doneLessons(except: 1));
    var played = 0;
    var puzzlesOpened = false;
    await show(
      tester,
      lesson: (context, stage) async {
        played++;
        await path.complete(stage, 3, Duration.zero);
        return 3;
      },
      puzzles: (c, ch, r) async {
        puzzlesOpened = true;
        return 0;
      },
    );
    await save(
      tester,
      find.textContaining(
        'Lezioni: ${lessons.length - 1} su ${lessons.length}',
      ),
      until: () => shown(passage),
    );
    expect(played, 1);
    expect(find.byKey(const ValueKey('story-passage')), findsOneWidget);
    expect(find.text('Lezioni concluse!'), findsOneWidget);
    expect(find.text('Ai puzzle'), findsOneWidget);
    expect(
      find.textContaining('Tino dice: Ora conosci i pezzi'),
      findsOneWidget,
    );
    await save(tester, find.text('Ai puzzle'), until: () => puzzlesOpened);
    expect(puzzlesOpened, isTrue);
  });

  testWidgets('RG-13 risolti i puzzle il foglio annuncia la sfida a Tino', (
    tester,
  ) async {
    await tester.runAsync(doneLessons);
    var boss = 0;
    await show(
      tester,
      puzzles: (c, ch, r) async => r,
      boss: (c, bot) async {
        boss++;
        return false;
      },
    );
    await save(
      tester,
      find.textContaining('Puzzle del capitolo'),
      until: () => shown(find.text('Puzzle risolti!')),
    );
    expect(find.text('Puzzle risolti!'), findsOneWidget);
    expect(find.textContaining('Tino ti aspetta'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('story-passage-guardian')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Tino dice: Giochiamo una partita'),
      findsOneWidget,
    );
    await save(tester, find.text('Sfida Tino'), until: () => boss == 1);
    expect(boss, 1);
  });

  testWidgets('«Più tardi» chiude il foglio senza aprire altro', (
    tester,
  ) async {
    await tester.runAsync(doneLessons);
    var boss = 0;
    await show(
      tester,
      puzzles: (c, ch, r) async => r,
      boss: (c, bot) async {
        boss++;
        return false;
      },
    );
    await save(
      tester,
      find.textContaining('Puzzle del capitolo'),
      until: () => shown(passage),
    );
    await save(tester, find.text('Più tardi'), until: () => !shown(passage));
    expect(find.byKey(const ValueKey('story-passage')), findsNothing);
    expect(boss, 0);
  });

  testWidgets('RG-13 battuto il bot il foglio chiude il capitolo e apre il '
      'successivo', (tester) async {
    await tester.runAsync(() async {
      await doneLessons();
      for (final g in first.pathChapter.stages.where((s) => s.isGuardian)) {
        await path.complete(g, 3, Duration.zero);
      }
      await story.puzzlesSolved(first, first.puzzleCount);
    });
    await show(tester, boss: (c, bot) async => true);
    await save(
      tester,
      find.textContaining('Sfida a Tino'),
      until: () => shown(find.text('Sfida Tino')),
    );
    await save(
      tester,
      find.text('Sfida Tino'),
      until: () => shown(find.text('Hai battuto Tino!')),
    );
    expect(find.text('Hai battuto Tino!'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('story-passage-guardian')),
      findsOneWidget,
    );
    expect(find.textContaining('Tino dice: Che bella partita'), findsOneWidget);
    expect(find.text('Capitolo 0 concluso!'), findsOneWidget);
    expect(find.textContaining('Si apre il capitolo 1'), findsOneWidget);
    expect(find.text('Al prossimo capitolo'), findsOneWidget);
  });

  testWidgets(
    'RG-13 battuto il bot il capitolo concluso si registra una volta',
    (tester) async {
      await tester.runAsync(() async {
        await doneLessons();
        for (final g in first.pathChapter.stages.where((s) => s.isGuardian)) {
          await path.complete(g, 3, Duration.zero);
        }
        await story.puzzlesSolved(first, first.puzzleCount);
      });
      final done = <String>[];
      await show(
        tester,
        boss: (c, bot) async => true,
        onChapterDone: (c) => done.add(c.id),
      );
      await save(
        tester,
        find.textContaining('Sfida a Tino'),
        until: () => shown(find.text('Sfida Tino')),
      );
      await save(
        tester,
        find.text('Sfida Tino'),
        until: () => shown(find.text('Hai battuto Tino!')),
      );
      expect(done, [first.id]);
    },
  );

  testWidgets('RG-13 dalla mappa la sfida si presenta prima di partire', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await doneLessons();
      for (final g in first.pathChapter.stages.where((s) => s.isGuardian)) {
        await path.complete(g, 3, Duration.zero);
      }
      await story.puzzlesSolved(first, first.puzzleCount);
    });
    var played = 0;
    await show(
      tester,
      boss: (c, bot) async {
        played++;
        return false;
      },
    );
    await save(
      tester,
      find.textContaining('Sfida a Tino'),
      until: () => shown(find.text('Sfida Tino')),
    );
    expect(played, 0);
    expect(find.text('La sfida di Tino'), findsOneWidget);
    expect(
      find.textContaining('Tino dice: Giochiamo una partita'),
      findsOneWidget,
    );
    await save(tester, find.text('Più tardi'), until: () => !shown(passage));
    expect(played, 0);
  });

  testWidgets('una sfida persa resta un avviso, senza foglio', (tester) async {
    await tester.runAsync(() async {
      await doneLessons();
      for (final g in first.pathChapter.stages.where((s) => s.isGuardian)) {
        await path.complete(g, 3, Duration.zero);
      }
      await story.puzzlesSolved(first, first.puzzleCount);
    });
    await show(tester, boss: (c, bot) async => false);
    await save(
      tester,
      find.textContaining('Sfida a Tino'),
      until: () => shown(find.text('Sfida Tino')),
    );
    await save(
      tester,
      find.text('Sfida Tino'),
      until: () => shown(find.textContaining('Tino resiste ancora')),
    );
    expect(find.byKey(const ValueKey('story-passage')), findsNothing);
    expect(
      find.textContaining('Tino resiste ancora: riprova quando vuoi.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Tino dice: Non ti preoccupare'),
      findsOneWidget,
    );
  });

  testWidgets('il foglio regge il testo al 130% e l\'inglese', (tester) async {
    await tester.runAsync(doneLessons);
    await show(
      tester,
      locale: const Locale('en'),
      textScale: 1.3,
      puzzles: (c, ch, r) async => r,
    );
    await save(
      tester,
      find.textContaining('Chapter puzzles'),
      until: () => shown(find.text('Puzzles solved!')),
    );
    expect(find.text('Puzzles solved!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.text('Later'));
    expect(size.height, greaterThan(0));
  });
}
