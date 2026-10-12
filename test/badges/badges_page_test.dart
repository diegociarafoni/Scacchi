import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/badges/badge_def.dart';
import 'package:scacchi/badges/badge_sources.dart';
import 'package:scacchi/badges/badges_page.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/progress/progress_tracker.dart';

import '../localized_app.dart';

void main() {
  late Directory dir;
  late ProgressController progress;
  final now = DateTime(2026, 10, 5, 12);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('badges');
    progress = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => now,
    );
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester, {Locale? locale}) async {
    tester.view.physicalSize = const Size(1080, 12000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        locale: locale ?? const Locale('it'),
        home: BadgesPage(controller: progress),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('RG-17 controller', () {
    test('lo sblocco di un badge viene annunciato una sola volta', () async {
      final events = <List<String>>[];
      final sub = progress.badgeUnlocks.listen(
        (b) => events.add([for (final d in b) d.id]),
      );
      const enPassant = GamePlayed(
        result: GameResult.win,
        highlights: {GameHighlight.enPassant},
      );
      await progress.record(enPassant);
      await progress.record(enPassant);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(events, [
        ['en_passant'],
      ]);
      expect(progress.badges, {'en_passant': dayNumber(now)});
    });

    test('le fonti dei salvataggi sbloccano i badge già meritati', () async {
      final events = <List<String>>[];
      final sub = progress.badgeUnlocks.listen(
        (b) => events.add([for (final d in b) d.id]),
      );
      await progress.updateBadgeSources(const BadgeSources(guardiansBeaten: 3));
      await progress.updateBadgeSources(const BadgeSources(guardiansBeaten: 3));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(events, [
        ['guardians_3'],
      ]);
      expect(progress.badgeSources.guardiansBeaten, 3);
    });

    test('lo sblocco resta dopo il riavvio', () async {
      await progress.record(
        const GamePlayed(
          result: GameResult.win,
          highlights: {GameHighlight.marathon},
        ),
      );
      final reopened = ProgressController(
        ProgressStore(File('${dir.path}/p.json')),
      );
      await reopened.load();
      expect(reopened.badges.keys, contains('marathon'));
    });
  });

  group('RG-17 scheda dei badge', () {
    testWidgets('mostra il totale e le famiglie', (tester) async {
      await show(tester);
      expect(find.text('Badge'), findsOneWidget);
      expect(find.text('0 di ${badges.length} badge'), findsOneWidget);
      for (final title in [
        'Imparare',
        'Puzzle',
        'Partite',
        'Storia',
        'Costanza',
      ]) {
        expect(find.textContaining(title), findsOneWidget, reason: title);
      }
    });

    testWidgets('un badge ottenuto conta nel totale', (tester) async {
      await tester.runAsync(
        () => progress.record(
          const GamePlayed(
            result: GameResult.win,
            highlights: {GameHighlight.enPassant},
          ),
        ),
      );
      await show(tester);
      expect(find.text('1 di ${badges.length} badge'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Alla francese', skipOffstage: false),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.bySemanticsLabel(RegExp('Alla francese, ottenuto')),
        findsOneWidget,
      );
    });

    testWidgets(
      'toccare un badge bloccato mostra come ottenerlo e l\'avanzamento',
      (tester) async {
        await tester.runAsync(() => progress.record(const PuzzleSolved()));
        await show(tester);
        await tester.scrollUntilVisible(
          find.text('Collezionista di soluzioni'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Collezionista di soluzioni'));
        await tester.pumpAndSettle();
        expect(find.text('Risolvi 500 puzzle.'), findsOneWidget);
        expect(find.text('1 / 500'), findsWidgets);
        expect(find.textContaining('Ottenuto'), findsNothing);
      },
    );

    testWidgets('toccare un badge ottenuto mostra la data', (tester) async {
      await tester.runAsync(
        () => progress.record(
          const GamePlayed(
            result: GameResult.win,
            highlights: {GameHighlight.enPassant},
          ),
        ),
      );
      await show(tester);
      await tester.scrollUntilVisible(
        find.text('Alla francese'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Alla francese'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ottenuto il 5 ott 2026'), findsOneWidget);
    });

    testWidgets('in inglese', (tester) async {
      await show(tester, locale: const Locale('en'));
      expect(find.text('0 of ${badges.length} badges'), findsOneWidget);
      expect(find.textContaining('Learn'), findsOneWidget);
    });

    testWidgets('i riquadri hanno un tocco di almeno 48 dp', (tester) async {
      await show(tester);
      final tiles = find.byType(BadgeTile);
      expect(tiles, findsWidgets);
      for (final e in tiles.evaluate().take(6)) {
        final size = tester.getSize(find.byWidget(e.widget));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });
  });
}
