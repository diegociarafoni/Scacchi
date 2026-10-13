import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/puzzles/puzzle_hub_page.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_page.dart';
import 'package:scacchi/puzzles/puzzle_run.dart';
import 'package:scacchi/puzzles/puzzle_run_page.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';
import 'package:scacchi/theme/rokko_theme.dart';

import 'fixtures.dart';
import 'puzzle_page_test.dart' show TwoPuzzles, tapMove;

Future<PuzzleTrainer> _trainer() =>
    PuzzleTrainer.load(PuzzleLibrary([backRank, castle]), MemoryStore());

void _phone(WidgetTester tester, {double width = 390, double height = 844}) {
  tester.view
    ..physicalSize = Size(width * 2, height * 2)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _themed(
  Widget home, {
  Locale locale = const Locale('it'),
  bool kid = false,
}) => SettingsScope(
  controller: SettingsController.defaults()..value = AppSettings(kidMode: kid),
  child: MaterialApp(
    theme: RokkoTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: home,
  ),
);

void main() {
  group('Puzzle: obiettivo e riuscita', () {
    testWidgets('obiettivo in una scheda in evidenza, sopra la scacchiera', (
      tester,
    ) async {
      _phone(tester);
      final trainer = await _trainer();
      await tester.pumpWidget(
        _themed(PuzzlePage(trainer: trainer, puzzle: backRank)),
      );
      final goal = find.byKey(const Key('puzzle-message'));
      expect(goal, findsOneWidget);
      expect(find.byKey(const Key('puzzle-feedback')), findsOneWidget);
      expect(
        tester.getTopLeft(goal).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('puzzle-board'))).dy),
      );
    });

    testWidgets('errore e riuscita hanno icona, testo e colore diversi', (
      tester,
    ) async {
      _phone(tester);
      final trainer = await _trainer();
      await tester.pumpWidget(
        _themed(PuzzlePage(trainer: trainer, puzzle: backRank)),
      );
      Color banner() =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.byKey(const Key('puzzle-feedback')),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .color!;
      final neutral = banner();
      await tapMove(tester, 'a1a7');
      expect(find.byKey(const Key('puzzle-wrong-icon')), findsOneWidget);
      final wrong = banner();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _themed(PuzzlePage(trainer: trainer, puzzle: backRank)),
      );
      await tapMove(tester, 'a1a8');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('puzzle-solved-icon')), findsOneWidget);
      final solved = banner();
      expect({neutral, wrong, solved}, hasLength(3));
    });

    testWidgets('esito letto dai lettori di schermo come regione viva', (
      tester,
    ) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      final trainer = await _trainer();
      await tester.pumpWidget(
        _themed(PuzzlePage(trainer: trainer, puzzle: backRank)),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('puzzle-message'))),
        matchesSemantics(
          label: 'Matto in 1 · Muove il Bianco',
          isLiveRegion: true,
          isHeader: true,
        ),
      );
      handle.dispose();
    });
  });

  group('Puzzle: tocco e testo grande', () {
    for (final kid in [false, true]) {
      testWidgets('pulsanti da 48 dp (56 nel profilo bambino), kid=$kid', (
        tester,
      ) async {
        _phone(tester);
        final trainer = await _trainer();
        await tester.pumpWidget(
          _themed(
            PuzzlePage(
              trainer: trainer,
              feed: TwoPuzzles(trainer, backRank, castle),
            ),
            kid: kid,
          ),
        );
        final min = kid ? 56.0 : 48.0;
        await tapMove(tester, 'a1a7');
        for (final label in ['Suggerimento', 'Soluzione', 'Prossimo']) {
          final size = tester.getSize(
            find.ancestor(
              of: find.text(label),
              matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
            ),
          );
          expect(size.height, greaterThanOrEqualTo(min), reason: label);
          expect(size.width, greaterThanOrEqualTo(min), reason: label);
        }
      });
    }

    testWidgets('testo al 130% su telefono piccolo senza overflow', (
      tester,
    ) async {
      _phone(tester);
      final trainer = await _trainer();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: _themed(PuzzlePage(trainer: trainer, puzzle: backRank)),
        ),
      );
      await tapMove(tester, 'a1a7');
      expect(tester.takeException(), isNull);
    });

    testWidgets('scheda Puzzle al 130% senza overflow', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: _themed(PuzzleHubPage(trainer: _trainer())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Puzzle: testi tradotti', () {
    const en = Locale('en');
    testWidgets('schermata del puzzle in inglese', (tester) async {
      _phone(tester);
      final trainer = await _trainer();
      await tester.pumpWidget(
        _themed(
          PuzzlePage(
            trainer: trainer,
            feed: TwoPuzzles(trainer, backRank, castle),
          ),
          locale: en,
        ),
      );
      await tapMove(tester, 'a1a7');
      for (final it in ['Suggerimento', 'Soluzione', 'Prossimo', 'Trova']) {
        expect(find.textContaining(it), findsNothing, reason: it);
      }
      expect(find.text('Hint'), findsOneWidget);
      expect(find.text('Solution'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('scheda Puzzle in inglese', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _themed(PuzzleHubPage(trainer: _trainer()), locale: en),
      );
      await tester.pumpAndSettle();
      for (final it in ['Allenamento', 'Punteggio', 'Ripasso', 'Per tema']) {
        expect(find.textContaining(it), findsNothing, reason: it);
      }
      expect(find.text('Daily puzzle'), findsOneWidget);
      expect(find.text('Training'), findsOneWidget);
    });

    testWidgets('serie in inglese', (tester) async {
      _phone(tester);
      final trainer = await _trainer();
      await tester.pumpWidget(
        _themed(
          PuzzleRunPage(trainer: trainer, mode: PuzzleRunMode.streak),
          locale: en,
        ),
      );
      expect(find.text('Inizia'), findsNothing);
      expect(find.text('Start'), findsOneWidget);
    });
  });

  group('Scheda Puzzle: gerarchia', () {
    testWidgets('il puzzle del giorno è la scheda principale', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_themed(PuzzleHubPage(trainer: _trainer())));
      await tester.pumpAndSettle();
      final daily = find.byKey(const Key('puzzle-hub-daily'));
      expect(daily, findsOneWidget);
      expect(
        tester.getTopLeft(daily).dy,
        lessThan(tester.getTopLeft(find.text('Allenamento')).dy),
      );
    });

    testWidgets('il profilo bambino non mostra cifre nella scheda', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        _themed(PuzzleHubPage(trainer: _trainer()), kid: true),
      );
      await tester.pumpAndSettle();
      final digits = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .where((s) => RegExp(r'\d').hasMatch(s));
      expect(digits, isEmpty);
    });
  });
}
