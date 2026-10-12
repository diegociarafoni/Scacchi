import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/puzzles/mode_guide.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_page.dart';
import 'package:scacchi/puzzles/puzzle_run.dart';
import 'package:scacchi/puzzles/puzzle_run_page.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/puzzles/review_queue.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../localized_app.dart';

import 'fixtures.dart';
import 'puzzle_page_test.dart' show tapMove;
import 'puzzle_run_page_test.dart' show begin, phone;

Future<PuzzleTrainer> load(KeyValueStore store) =>
    PuzzleTrainer.load(PuzzleLibrary([backRank, castle, hangingQueen]), store);

void main() {
  test('il testo del ripasso cita gli intervalli veri', () {
    expect(ReviewQueue.intervals, [1, 3, 7, 14, 30]);
    expect(PuzzleGuide.review.rules.join(' '), contains('1, 3, 7, 14 e 30'));
  });

  group('serie: spiegazione prima di iniziare', () {
    for (final mode in PuzzleRunMode.values) {
      testWidgets('${mode.label} mostra obiettivo e regole, poi parte', (
        tester,
      ) async {
        final trainer = await phone(tester);
        await tester.pumpWidget(
          localizedApp(
            home: PuzzleRunPage(
              trainer: trainer,
              mode: mode,
              clock: () => Duration.zero,
            ),
          ),
        );
        final guide = PuzzleGuide.forRun(mode);
        expect(find.text('Obiettivo'), findsOneWidget);
        expect(find.text(guide.goal), findsOneWidget);
        expect(find.text(guide.rules.first), findsOneWidget);
        expect(find.byKey(const Key('run-score')), findsNothing);
        await begin(tester);
        expect(find.text('Obiettivo'), findsNothing);
        expect(find.byKey(const Key('run-score')), findsOneWidget);
        // Dopo l'inizio il testo breve dell'obiettivo resta in vista.
        expect(find.byKey(const Key('run-goal')), findsOneWidget);
      });
    }

    testWidgets('il tempo non scorre durante la spiegazione', (tester) async {
      final trainer = await phone(tester);
      await tester.pumpWidget(
        localizedApp(
          home: PuzzleRunPage(
            trainer: trainer,
            mode: PuzzleRunMode.storm,
            clock: () => Duration.zero,
          ),
        ),
      );
      await tester.pump(const Duration(minutes: 4));
      expect(find.text('Obiettivo'), findsOneWidget);
      expect(find.text('Serie conclusa'), findsNothing);
      await begin(tester);
      expect(find.text('3:00'), findsOneWidget);
    });

    testWidgets('la guida si riapre dalla barra senza perdere la serie', (
      tester,
    ) async {
      final trainer = await phone(tester);
      await tester.pumpWidget(
        localizedApp(
          home: PuzzleRunPage(trainer: trainer, mode: PuzzleRunMode.streak),
        ),
      );
      await begin(tester);
      await tapMove(tester, 'a1a8');
      expect(find.text('Punti 1'), findsOneWidget);
      await tester.tap(find.byTooltip('Come funziona'));
      await tester.pumpAndSettle();
      expect(find.text('Obiettivo'), findsOneWidget);
      await tester.tap(find.text('Ho capito'));
      await tester.pumpAndSettle();
      expect(find.text('Punti 1'), findsOneWidget);
    });
  });

  group('serie: avanzamento verso l\'obiettivo', () {
    testWidgets('Corsa mostra le vite e le consuma agli errori', (
      tester,
    ) async {
      final trainer = await phone(tester);
      await tester.pumpWidget(
        localizedApp(
          home: PuzzleRunPage(trainer: trainer, mode: PuzzleRunMode.rush3),
        ),
      );
      await begin(tester);
      expect(find.bySemanticsLabel('Vite: 3 su 3'), findsOneWidget);
      await tapMove(tester, 'a1a7');
      expect(find.bySemanticsLabel('Vite: 2 su 3'), findsOneWidget);
    });

    testWidgets('le modalità a tempo mostrano una barra del tempo', (
      tester,
    ) async {
      final trainer = await phone(tester);
      await tester.pumpWidget(
        localizedApp(
          home: PuzzleRunPage(
            trainer: trainer,
            mode: PuzzleRunMode.storm,
            clock: () => Duration.zero,
          ),
        ),
      );
      await begin(tester);
      expect(find.bySemanticsLabel('Tempo rimasto: 3:00'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Serie e Sopravvivenza non hanno barra del tempo', (
      tester,
    ) async {
      final trainer = await phone(tester);
      await tester.pumpWidget(
        localizedApp(
          home: PuzzleRunPage(trainer: trainer, mode: PuzzleRunMode.streak),
        ),
      );
      await begin(tester);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('su uno schermo basso la serie non va in overflow', (
      tester,
    ) async {
      final trainer = await phone(tester);
      tester.view.physicalSize = const Size(960, 900);
      await tester.pumpWidget(
        localizedApp(
          home: PuzzleRunPage(
            trainer: trainer,
            mode: PuzzleRunMode.rush5,
            clock: () => Duration.zero,
          ),
        ),
      );
      await begin(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('riaprire le regole non ferma il tempo', (tester) async {
      final trainer = await phone(tester);
      var elapsed = Duration.zero;
      await tester.pumpWidget(
        localizedApp(
          home: PuzzleRunPage(
            trainer: trainer,
            mode: PuzzleRunMode.storm,
            clock: () => elapsed,
          ),
        ),
      );
      await begin(tester);
      await tester.tap(find.byTooltip('Come funziona'));
      await tester.pumpAndSettle();
      elapsed = const Duration(minutes: 3);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Ho capito'));
      await tester.pumpAndSettle();
      expect(find.text('Serie conclusa'), findsOneWidget);
    });

    testWidgets('il risultato dice com\'è finita la serie', (tester) async {
      final trainer = await phone(tester);
      await tester.pumpWidget(
        localizedApp(
          home: PuzzleRunPage(trainer: trainer, mode: PuzzleRunMode.streak),
        ),
      );
      await begin(tester);
      await tapMove(tester, 'a1a7');
      await tester.pumpAndSettle();
      expect(find.text('Serie conclusa'), findsOneWidget);
      expect(
        find.text('Hai sbagliato un puzzle: la serie è finita.'),
        findsOneWidget,
      );
    });
  });

  group('puzzle singoli: spiegazione e avanzamento', () {
    Future<void> open(
      WidgetTester tester,
      PuzzleTrainer trainer,
      PuzzleGuide? guide,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localizedApp(
          home: PuzzlePage(
            trainer: trainer,
            puzzle: hangingQueen,
            guide: guide,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('la prima volta la spiegazione si apre da sola', (
      tester,
    ) async {
      final store = MemoryStore();
      await open(tester, await load(store), PuzzleGuide.daily);
      expect(find.text(PuzzleGuide.daily.goal), findsOneWidget);
      await tester.tap(find.text('Ho capito'));
      await tester.pumpAndSettle();
      expect(find.text(PuzzleGuide.daily.goal), findsNothing);

      // La seconda volta non si ripresenta, ma resta nella barra.
      await tester.pumpWidget(localizedApp(home: const SizedBox()));
      await open(tester, await load(store), PuzzleGuide.daily);
      expect(find.text(PuzzleGuide.daily.goal), findsNothing);
      await tester.tap(find.byTooltip('Come funziona'));
      await tester.pumpAndSettle();
      expect(find.text(PuzzleGuide.daily.goal), findsOneWidget);
    });

    testWidgets('senza guida non compare nulla di nuovo', (tester) async {
      await open(tester, await load(MemoryStore()), null);
      expect(find.byTooltip('Come funziona'), findsNothing);
    });

    testWidgets('mostra le mosse trovate sul totale', (tester) async {
      await open(tester, await load(MemoryStore()), null);
      expect(find.text('Mosse trovate: 0 di 3'), findsOneWidget);
      await tapMove(tester, 'e6e7');
      await tester.pumpAndSettle();
      expect(find.text('Mosse trovate: 1 di 3'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
