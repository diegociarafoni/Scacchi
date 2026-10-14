import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/review/autoplay.dart';
import 'package:rokko/review/review_page.dart';

import 'review_page_test.dart' show pumpReview;

const play = 'Riproduci fino al prossimo commento';
const pause = 'Pausa';

Future<void> toStart(WidgetTester tester) async {
  await pumpReview(tester);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Inizio'));
  await tester.pump();
}

void main() {
  setUp(ReviewCache.clear);

  group('A-35 riproduzione fino al prossimo commento', () {
    testWidgets('avanza da sola e si ferma sull\'errore', (tester) async {
      await toStart(tester);
      await tester.tap(find.byTooltip(play));
      await tester.pump();
      expect(find.byTooltip(pause), findsOneWidget);
      await tester.pump(playbackStep);
      expect(find.textContaining('è un errore grave'), findsNothing);
      // L'errore è la sesta mossa: dopo altre cinque pause si trova lì.
      for (var i = 0; i < 5; i++) {
        await tester.pump(playbackStep);
      }
      expect(find.textContaining('è un errore grave'), findsWidgets);
      expect(find.byTooltip(play), findsOneWidget);
      await tester.pump(playbackStep * 3);
      expect(find.textContaining('è la mossa migliore'), findsNothing);
    });

    testWidgets('con le animazioni ridotte salta subito al commento', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await toStart(tester);
      await tester.tap(find.byTooltip(play));
      await tester.pump();
      expect(find.textContaining('è un errore grave'), findsWidgets);
      expect(find.byTooltip(play), findsOneWidget);
    });

    testWidgets('la pausa ferma la riproduzione', (tester) async {
      await toStart(tester);
      await tester.tap(find.byTooltip(play));
      await tester.pump(playbackStep);
      await tester.tap(find.byTooltip(pause));
      await tester.pump();
      expect(find.byTooltip(play), findsOneWidget);
      await tester.pump(playbackStep * 10);
      expect(find.textContaining('è un errore grave'), findsNothing);
    });

    testWidgets('una mossa scelta a mano interrompe la riproduzione', (
      tester,
    ) async {
      await toStart(tester);
      await tester.tap(find.byTooltip(play));
      await tester.pump(playbackStep);
      await tester.tap(find.byTooltip('Mossa successiva'));
      await tester.pump();
      expect(find.byTooltip(play), findsOneWidget);
    });

    testWidgets('alla fine della partita il pulsante è spento', (tester) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(play),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });
}
