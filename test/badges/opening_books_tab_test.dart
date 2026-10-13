import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/badges/badges_page.dart';
import 'package:scacchi/badges/opening_books_tab.dart';
import 'package:scacchi/badges/opening_volumes.dart';
import 'package:scacchi/badges/recent_badges.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_store.dart';

import '../localized_app.dart';

void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('books');
    progress = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => DateTime(2026, 10, 5, 12),
    );
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester, Widget home, {Locale? locale}) async {
    tester.view.physicalSize = const Size(1080, 12000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(locale: locale ?? const Locale('it'), home: home),
    );
    await tester.pumpAndSettle();
  }

  group('libri delle aperture', () {
    testWidgets('a zero libri sono tutti da sbloccare', (tester) async {
      await show(
        tester,
        Scaffold(body: OpeningBooksTab(state: progress.state)),
      );
      expect(
        find.text('0 su ${openingVolumes.length} raggiunti'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp('Difesa siciliana, libro da sbloccare')),
        findsOneWidget,
      );
    });

    testWidgets('giocare un\'apertura sblocca il suo libro', (tester) async {
      await tester.runAsync(
        () => progress.record(
          const GamePlayed(result: GameResult.loss, openingBook: 'sicilian'),
        ),
      );
      await show(tester, BadgesPage(controller: progress));
      await tester.tap(find.text('Libri'));
      await tester.pumpAndSettle();
      expect(
        find.text('1 su ${openingVolumes.length} raggiunti'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Difesa siciliana, libro sbloccato')),
        findsOneWidget,
      );
      await tester.tap(find.text('Difesa siciliana'));
      await tester.pumpAndSettle();
      expect(find.textContaining('L\'hai giocata una volta'), findsOneWidget);
    });

    testWidgets('un libro bloccato spiega come ottenerlo', (tester) async {
      await show(
        tester,
        Scaffold(body: OpeningBooksTab(state: progress.state)),
      );
      await tester.tap(find.text('Gambetto di donna'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gioca una partita'), findsOneWidget);
    });

    testWidgets('in inglese i nomi restano quelli originali', (tester) async {
      await show(
        tester,
        Scaffold(body: OpeningBooksTab(state: progress.state)),
        locale: const Locale('en'),
      );
      expect(
        find.text('0 of ${openingVolumes.length} reached'),
        findsOneWidget,
      );
      expect(find.text('Sicilian Defense'), findsOneWidget);
    });
  });

  group('badge recenti', () {
    test('i più recenti per primi', () {
      final r = recentBadges({
        'en_passant': 10,
        'stalemate': 12,
        'podium': 11,
      }, 2);
      expect(r.map((b) => b.id), ['stalemate', 'podium']);
    });

    testWidgets('senza badge la fascia non occupa spazio', (tester) async {
      await show(tester, Scaffold(body: RecentBadges(controller: progress)));
      expect(tester.getSize(find.byType(RecentBadges)).height, 0);
    });

    testWidgets('mostra i badge ottenuti', (tester) async {
      await tester.runAsync(
        () => progress.record(
          const GamePlayed(
            result: GameResult.win,
            highlights: {GameHighlight.enPassant},
          ),
        ),
      );
      await show(tester, Scaffold(body: RecentBadges(controller: progress)));
      expect(
        find.bySemanticsLabel(RegExp('Badge recenti: Alla francese')),
        findsOneWidget,
      );
    });
  });

  test('ProgressState senza contatori non sblocca libri', () {
    expect(unlockedVolumes(ProgressState.initial), isEmpty);
  });
}
