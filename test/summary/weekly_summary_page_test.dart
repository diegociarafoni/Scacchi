import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/path/curriculum.dart';
import 'package:rokko/progress/activity.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/summary/week_log.dart';
import 'package:rokko/summary/weekly_summary_page.dart';

import '../localized_app.dart';

void main() {
  final now = DateTime(2026, 10, 12, 9);
  DateTime ago(int d) => now.subtract(Duration(days: d));

  WeekLog log(List<(Activity, int)> items) =>
      items.fold(const WeekLog(), (l, e) => l.record(e.$1, ago(e.$2)));

  final full = log([
    (const GamePlayed(result: GameResult.win), 1),
    (const GamePlayed(result: GameResult.loss), 2),
    (const PuzzleSolved(duration: Duration(minutes: 4)), 2),
    (
      const ReviewCompleted(
        gameId: 'a',
        accuracy: 80,
        errorThemes: {'hangingPiece': 3},
      ),
      1,
    ),
    (const ReviewCompleted(gameId: 'b', accuracy: 60), 9),
  ]);

  Future<void> show(
    WidgetTester tester,
    WeekLog log, {
    bool kid = false,
    void Function(Stage)? onLesson,
    void Function(String, String)? onPuzzles,
    Locale locale = const Locale('it'),
  }) async {
    final settings = SettingsController.defaults();
    if (kid) await settings.update(settings.value.copyWith(kidMode: true));
    await tester.pumpWidget(
      SettingsScope(
        controller: settings,
        child: localizedApp(
          locale: locale,
          home: WeeklySummaryPage(
            log: log,
            now: () => now,
            openLesson: onLesson == null ? null : (_, s) => onLesson(s),
            openPuzzles: onPuzzles == null
                ? null
                : (_, theme, title) => onPuzzles(theme, title),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('RG-16 scheda', () {
    testWidgets('senza attività spiega come riempirla', (tester) async {
      await show(tester, const WeekLog());
      expect(
        find.textContaining('il riepilogo si riempie da solo'),
        findsOneWidget,
      );
      expect(find.text('Il consiglio'), findsNothing);
    });

    testWidgets('mostra progressi, errore e consiglio', (tester) async {
      await show(tester, full);
      expect(find.text('2 partite'), findsOneWidget);
      expect(find.text('1 vinte, 0 patte, 1 perse'), findsOneWidget);
      expect(find.text('1 puzzle risolto'), findsOneWidget);
      expect(find.text('1 partita rivista'), findsOneWidget);
      expect(find.text('4 minuti di allenamento'), findsOneWidget);
      expect(find.text('Precisione media 80%'), findsOneWidget);
      expect(
        find.text('20 punti in più della settimana scorsa'),
        findsOneWidget,
      );
      expect(find.text('pezzi lasciati in presa: 3 volte'), findsOneWidget);
      expect(
        find.text('Ripassa la lezione «Pezzi indifesi» della Storia.'),
        findsOneWidget,
      );
    });

    testWidgets('le righe a zero non compaiono', (tester) async {
      await show(tester, log([(const PuzzleSolved(), 1)]));
      expect(find.textContaining('partit'), findsNothing);
      expect(find.textContaining('lezion'), findsNothing);
      expect(
        find.text('Nessun errore si è ripetuto: ottimo lavoro.'),
        findsOneWidget,
      );
    });

    testWidgets('il pulsante apre la lezione consigliata', (tester) async {
      Stage? opened;
      await show(tester, full, onLesson: (s) => opened = s);
      await tester.tap(find.text('Apri la lezione'));
      expect(opened?.id, 'tactics.hanging');
    });

    testWidgets('per i puzzle il pulsante apre il tema', (tester) async {
      String? theme;
      await show(
        tester,
        log([
          (
            const ReviewCompleted(
              gameId: 'a',
              errorThemes: {'missedCapture': 2},
            ),
            1,
          ),
        ]),
        onPuzzles: (t, _) => theme = t,
      );
      await tester.tap(find.text('Apri i puzzle'));
      expect(theme, 'hangingPiece');
    });

    testWidgets('senza i collegamenti il pulsante non c\'è', (tester) async {
      await show(tester, full);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('le sezioni sono intestazioni per i lettori di schermo', (
      tester,
    ) async {
      await show(tester, full);
      for (final title in [
        'I tuoi progressi',
        'Errore più frequente',
        'Il consiglio',
      ]) {
        final header = find.ancestor(
          of: find.text(title),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.header == true,
          ),
        );
        expect(header, findsOneWidget, reason: title);
      }
    });

    testWidgets('il pulsante ha un\'area di tocco di almeno 48 punti', (
      tester,
    ) async {
      await show(tester, full, onLesson: (_) {});
      final size = tester.getSize(find.byType(FilledButton));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('è tradotta in inglese', (tester) async {
      await show(tester, full, locale: const Locale('en'));
      expect(find.text('2 games'), findsOneWidget);
      expect(find.text('Your tip'), findsOneWidget);
    });
  });

  group('RP-06 profilo bambino', () {
    testWidgets('nessun numero in tutta la scheda', (tester) async {
      await show(tester, full, kid: true, onLesson: (_) {});
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');
      for (final text in texts) {
        expect(text, isNot(matches(RegExp(r'\d'))), reason: text);
      }
      expect(
        find.text('Questa settimana ti sei allenato. Bravo!'),
        findsOneWidget,
      );
      expect(
        find.text('Fai più attenzione a: pezzi lasciati in presa.'),
        findsOneWidget,
      );
    });

    testWidgets('i giorni sono stelle con un\'etichetta senza cifre', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await show(tester, full, kid: true);
      expect(find.byIcon(Icons.star), findsNWidgets(2));
      expect(
        find.bySemanticsLabel(
          RegExp('Le stelle sono i giorni in cui ti sei allenato'),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('senza revisioni non consiglia di rivedere', (tester) async {
      await show(
        tester,
        log([(const GamePlayed(result: GameResult.win), 1)]),
        kid: true,
      );
      expect(find.textContaining('Rivedi'), findsNothing);
      expect(find.textContaining('puzzle'), findsOneWidget);
    });
  });
}
