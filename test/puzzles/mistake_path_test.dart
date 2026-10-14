import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/puzzles/mistake_path.dart';
import 'package:rokko/puzzles/mistake_path_page.dart';
import 'package:rokko/puzzles/puzzle.dart';
import 'package:rokko/puzzles/puzzle_hub_page.dart';
import 'package:rokko/puzzles/puzzle_library.dart';
import 'package:rokko/puzzles/puzzle_page.dart';
import 'package:rokko/puzzles/puzzle_trainer.dart';
import 'package:rokko/storage/key_value_store.dart';

import '../kids/no_numbers_test.dart' show kidApp, setPhone;
import '../localized_app.dart';
import 'fixtures.dart';

/// A-27: capitoli personali dai temi tattici sbagliati più spesso.

Puzzle mine(String id, String themes) => Puzzle.parseCsv(
  'mio-$id,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,900,$themes',
);

final day = DateTime(2026, 10, 14, 9);

/// L'ora del test, spostabile per far scadere i ripassi.
var today = day;

Future<PuzzleTrainer> trainerWith(List<Puzzle> personal) async {
  final t = await PuzzleTrainer.load(
    PuzzleLibrary([backRank]),
    MemoryStore(),
    now: () => today,
  );
  await t.addPersonal(personal);
  return t;
}

void main() {
  setUp(() => today = day);

  group('capitoli', () {
    test('un capitolo per tema tattico, dal più sbagliato', () async {
      final t = await trainerWith([
        mine('a', 'fork middlegame'),
        mine('b', 'hangingPiece endgame'),
        mine('c', 'hangingPiece opening'),
        mine('d', 'hangingPiece middlegame'),
        mine('e', 'fork endgame'),
      ]);
      final chapters = mistakeChapters(t);
      expect([for (final c in chapters) c.theme], ['hangingPiece', 'fork']);
      expect([for (final c in chapters) c.total], [3, 2]);
    });

    test('le fasi della partita non sono temi', () async {
      final t = await trainerWith([
        mine('a', 'opening'),
        mine('b', 'opening'),
        mine('c', 'middlegame endgame'),
      ]);
      expect(mistakeChapters(t), isEmpty);
    });

    test('un tema sbagliato una volta sola non fa un capitolo', () async {
      final t = await trainerWith([
        mine('a', 'fork middlegame'),
        mine('b', 'pin middlegame'),
      ]);
      expect(mistakeChapters(t), isEmpty);
    });

    test('i capitoli sono al massimo $mistakeChaptersMax', () async {
      const themes = [
        'fork',
        'hangingPiece',
        'defensiveMove',
        'discoveredAttack',
        'mateIn1',
        'mateIn2',
      ];
      final t = await trainerWith([
        for (final theme in themes)
          for (var i = 0; i < 2; i++) mine('$theme$i', theme),
      ]);
      expect(mistakeChapters(t), hasLength(mistakeChaptersMax));
    });

    test(
      'a parità di errori l\'ordine è quello dei temi, sempre uguale',
      () async {
        final t = await trainerWith([
          mine('a', 'pin'),
          mine('b', 'pin'),
          mine('c', 'fork'),
          mine('d', 'fork'),
        ]);
        expect([for (final c in mistakeChapters(t)) c.theme], ['fork', 'pin']);
      },
    );

    test('avanzamento: provati e imparati', () async {
      final t = await trainerWith([
        mine('a', 'fork'),
        mine('b', 'fork'),
        mine('c', 'fork'),
      ]);
      var c = mistakeChapters(t).single;
      expect((c.practiced, c.learned, c.done), (0, 0, false));
      // Un puzzle ripassato esce dalle carte nuove.
      await t.reviews.reviewed('mio-a', solved: true, now: day);
      c = mistakeChapters(t).single;
      expect((c.practiced, c.learned), (1, 0));
      // Uscire dalla coda vuol dire averlo imparato.
      await t.reviews.remove(['mio-a']);
      c = mistakeChapters(t).single;
      expect((c.practiced, c.learned), (1, 1));
      await t.reviews.remove(['mio-b', 'mio-c']);
      expect(mistakeChapters(t).single.done, isTrue);
    });
  });

  group('da fare adesso', () {
    test('i nuovi e quelli in scadenza, non gli altri', () async {
      final t = await trainerWith([
        mine('a', 'fork'),
        mine('b', 'fork'),
        mine('c', 'fork'),
      ]);
      expect(mistakeChapters(t).single.available, 3);
      await t.reviews.reviewed('mio-a', solved: true, now: day);
      expect(mistakeChapters(t).single.available, 2);
      await t.reviews.reviewed('mio-b', solved: false, now: day);
      await t.reviews.reviewed('mio-c', solved: true, now: day);
      expect(mistakeChapters(t).single.available, 0);
      today = day.add(const Duration(days: 1));
      expect(mistakeChapters(t).single.available, 3);
    });
  });

  group('puzzle del capitolo', () {
    test('si propongono i nuovi prima, una volta sola', () async {
      final t = await trainerWith([
        mine('a', 'fork'),
        mine('b', 'fork'),
        mine('c', 'fork'),
        mine('x', 'pin'),
      ]);
      final feed = MistakeChapterFeed(t, 'fork');
      final served = <String>[];
      while (feed.hasNext) {
        served.add(feed.next()!.id);
      }
      expect(served.toSet(), {'mio-a', 'mio-b', 'mio-c'});
      expect(served, hasLength(3));
      expect(feed.next(), isNull);
    });

    test('i puzzle già fatti aspettano il loro giorno', () async {
      final t = await trainerWith([
        mine('a', 'fork'),
        mine('b', 'fork'),
        mine('c', 'fork'),
      ]);
      await t.reviews.reviewed('mio-a', solved: true, now: day);
      var feed = MistakeChapterFeed(t, 'fork');
      final first = <String>[];
      while (feed.hasNext) {
        first.add(feed.next()!.id);
      }
      expect(first.toSet(), {'mio-b', 'mio-c'});
      // Il giorno dopo il ripasso di «a» è in scadenza.
      today = day.add(const Duration(days: 1));
      feed = MistakeChapterFeed(t, 'fork');
      expect(feed.next()!.id, anyOf('mio-b', 'mio-c'));
      expect(feed.next()!.id, anyOf('mio-b', 'mio-c'));
      expect(feed.next()!.id, 'mio-a');
    });

    test('tra i ripassi viene prima il più in ritardo', () async {
      final t = await trainerWith([mine('a', 'fork'), mine('b', 'fork')]);
      await t.reviews.reviewed('mio-b', solved: true, now: day);
      await t.reviews.reviewed(
        'mio-a',
        solved: true,
        now: day.add(const Duration(days: 1)),
      );
      today = day.add(const Duration(days: 5));
      final feed = MistakeChapterFeed(t, 'fork');
      expect(feed.next()!.id, 'mio-b');
      expect(feed.next()!.id, 'mio-a');
    });

    test('i già imparati non tornano', () async {
      final t = await trainerWith([mine('a', 'fork'), mine('b', 'fork')]);
      await t.reviews.remove(['mio-a']);
      final feed = MistakeChapterFeed(t, 'fork');
      expect(feed.next()!.id, 'mio-b');
      expect(feed.hasNext, isFalse);
    });

    test('l\'esito entra nel ripasso e non sposta il punteggio', () async {
      final t = await trainerWith([mine('a', 'fork'), mine('b', 'fork')]);
      final feed = MistakeChapterFeed(t, 'fork');
      final first = feed.next()!;
      final outcome = await feed.finished(first, solved: true);
      expect(outcome.ratingDelta, isNull);
      expect(outcome.awardXp, isTrue);
      expect(t.reviews.isNew(first.id), isFalse);
      expect(t.rating.rating, 1500);
      final second = feed.next()!;
      await feed.finished(second, solved: false);
      expect(t.reviews.contains(second.id), isTrue);
      expect(t.reviews.isNew(second.id), isFalse);
    });
  });

  group('schermata', () {
    testWidgets('elenca i capitoli con il tema e l\'avanzamento', (
      tester,
    ) async {
      setPhone(tester);
      final t = await trainerWith([
        mine('a', 'fork'),
        mine('b', 'fork'),
        mine('c', 'fork'),
        mine('d', 'hangingPiece'),
        mine('e', 'hangingPiece'),
      ]);
      await t.reviews.reviewed('mio-a', solved: true, now: day);
      await tester.pumpWidget(localizedApp(home: MistakePathPage(trainer: t)));
      await tester.pumpAndSettle();
      expect(find.text('Dai miei errori'), findsWidgets);
      expect(find.text('Capitolo 1'), findsOneWidget);
      expect(find.text('Forchetta'), findsOneWidget);
      expect(find.text('3 puzzle dai tuoi errori'), findsOneWidget);
      expect(find.text('1 di 3 provati'), findsOneWidget);
      expect(find.text('Capitolo 2'), findsOneWidget);
      expect(find.text('In corso'), findsOneWidget);
      expect(find.text('Da iniziare'), findsOneWidget);
    });

    testWidgets('un capitolo fatto per oggi non si apre', (tester) async {
      setPhone(tester);
      final t = await trainerWith([mine('a', 'fork'), mine('b', 'fork')]);
      await t.reviews.reviewed('mio-a', solved: true, now: day);
      await t.reviews.reviewed('mio-b', solved: true, now: day);
      await tester.pumpWidget(localizedApp(home: MistakePathPage(trainer: t)));
      await tester.pumpAndSettle();
      expect(find.text('Fatto per oggi'), findsOneWidget);
      await tester.tap(find.text('Forchetta'));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzlePage), findsNothing);
    });

    testWidgets('senza capitoli spiega come nascono', (tester) async {
      setPhone(tester);
      final t = await trainerWith([mine('a', 'fork')]);
      await tester.pumpWidget(localizedApp(home: MistakePathPage(trainer: t)));
      await tester.pumpAndSettle();
      expect(find.textContaining('almeno due volte'), findsOneWidget);
      expect(find.text('Capitolo 1'), findsNothing);
    });

    testWidgets('col testo ingrandito al 130% niente overflow', (tester) async {
      setPhone(tester);
      final t = await trainerWith([
        mine('a', 'fork'),
        mine('b', 'fork'),
        mine('c', 'discoveredAttack'),
        mine('d', 'discoveredAttack'),
      ]);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: localizedApp(home: MistakePathPage(trainer: t)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Attacco di scoperta'), findsOneWidget);
    });

    testWidgets('toccare un capitolo apre i suoi puzzle', (tester) async {
      setPhone(tester);
      final t = await trainerWith([mine('a', 'fork'), mine('b', 'fork')]);
      await tester.pumpWidget(localizedApp(home: MistakePathPage(trainer: t)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forchetta'));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzlePage), findsOneWidget);
    });

    testWidgets('il comando è nel menu dei puzzle, non nel profilo bambino', (
      tester,
    ) async {
      setPhone(tester);
      final t = await trainerWith([mine('a', 'fork'), mine('b', 'fork')]);
      await tester.pumpWidget(
        localizedApp(home: PuzzleHubPage(trainer: Future.value(t))),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Dai miei errori'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Dai miei errori'));
      await tester.pumpAndSettle();
      expect(find.byType(MistakePathPage), findsOneWidget);

      await tester.pumpWidget(kidApp(PuzzleHubPage(trainer: Future.value(t))));
      await tester.pumpAndSettle();
      expect(find.text('Dai miei errori', skipOffstage: false), findsNothing);
    });
  });
}
