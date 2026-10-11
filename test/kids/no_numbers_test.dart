import 'dart:async';
import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/analysis/analysis_page.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/profile_page.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_feedback.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/progress/progress_tracker.dart';
import 'package:scacchi/progress/xp.dart';
import 'package:scacchi/puzzles/puzzle_hub_page.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_page.dart';
import 'package:scacchi/puzzles/puzzle_run.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/review/review_page.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../puzzles/fixtures.dart';
import '../puzzles/puzzle_page_test.dart' show tapMove;
import '../review/fake_engine.dart';

final _digit = RegExp(r'\d');

/// App localizzata in italiano con il profilo bambino acceso o spento.
Widget kidApp(Widget home, {bool kid = true}) => SettingsScope(
  controller: SettingsController.defaults()..value = AppSettings(kidMode: kid),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('it'),
    home: home,
  ),
);

/// Testi visibili con cifre, esclusa la scacchiera (che ha le coordinate).
List<String> digitTexts(WidgetTester tester) => [
  for (final e in find.byType(RichText).evaluate())
    if (e.findAncestorWidgetOfExactType<Chessboard>() == null)
      if ((e.widget as RichText).text.toPlainText() case final t
          when _digit.hasMatch(t))
        t,
];

void setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 3400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('RP-06 feedback dei progressi', () {
    const update = ProgressUpdate(
      state: ProgressState.initial,
      xpGained: 20,
      newLevel: 2,
      goalReached: true,
    );

    Future<void> showFeedback(WidgetTester tester, {required bool kid}) async {
      await tester.pumpWidget(
        kidApp(
          kid: kid,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showProgressFeedback(context, update),
                child: const Text('vai'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('vai'));
      await tester.pump();
    }

    testWidgets('nel profilo bambino la notifica non ha numeri', (
      tester,
    ) async {
      await showFeedback(tester, kid: true);
      final text = tester.widget<Text>(
        find.descendant(of: find.byType(SnackBar), matching: find.byType(Text)),
      );
      expect(text.data, isNot(contains('XP')));
      expect(text.data, isNot(matches(_digit)));
      expect(text.data, contains('Bravo'));
      expect(text.data, contains('livello'));
    });

    testWidgets('fuori dal profilo bambino restano gli XP', (tester) async {
      await showFeedback(tester, kid: false);
      expect(find.textContaining('+20 XP'), findsOneWidget);
    });
  });

  group('RP-06 profilo', () {
    late Directory dir;
    late ProgressController controller;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('kidprofile');
      controller = ProgressController(
        ProgressStore(File('${dir.path}/p.json')),
        clock: () => DateTime(2026, 10, 5, 12),
      );
      await controller.load();
    });
    tearDown(() => dir.deleteSync(recursive: true));

    testWidgets('livello a stelle, barre senza cifre, niente record', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (var i = 0; i < 6; i++) {
          await controller.record(const GamePlayed(result: GameResult.win));
        }
      });
      setPhone(tester);
      await tester.pumpWidget(kidApp(ProfilePage(controller: controller)));
      await tester.pumpAndSettle();
      final level = levelForXp(controller.state.xp);
      expect(level, greaterThan(1));
      expect(find.byKey(const Key('kid-level-stars')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('kid-level-stars')),
          matching: find.byIcon(Icons.star),
        ),
        findsNWidgets(level),
      );
      expect(find.text('Livello $level'), findsNothing);
      expect(find.textContaining('XP'), findsNothing);
      // I traguardi restano coi loro nomi; sparisce il conteggio dei giorni.
      expect(find.textContaining(RegExp(r'^\d+ giorn')), findsNothing);
      expect(find.textContaining('Record'), findsNothing);
      expect(find.textContaining('protezion'), findsNothing);
      expect(find.textContaining(RegExp(r'\d+ ?/ ?\d+')), findsNothing);
      for (final bar in tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      )) {
        expect(bar.semanticsLabel ?? '', isNot(matches(_digit)));
      }
      expect(find.byKey(const Key('kid-streak')), findsOneWidget);
    });
  });

  group('RP-06 puzzle', () {
    Future<PuzzleTrainer> trainer() =>
        PuzzleTrainer.load(PuzzleLibrary([backRank, castle]), MemoryStore());

    testWidgets('l\'hub non mostra punteggio, conteggi né modalità a tempo', (
      tester,
    ) async {
      setPhone(tester);
      final t = await trainer();
      await tester.pumpWidget(kidApp(PuzzleHubPage(trainer: Future.value(t))));
      await tester.pumpAndSettle();
      expect(find.text('Allenamento'), findsOneWidget);
      expect(find.text(PuzzleRunMode.storm.label), findsNothing);
      expect(digitTexts(tester), isEmpty);

      await tester.tap(find.text('Per tema'));
      await tester.pumpAndSettle();
      // I nomi dei temi restano (es. «Matto in 1»), spariscono i conteggi.
      expect(find.textContaining(RegExp(r'^\d+$')), findsNothing);
    });

    testWidgets('la pagina del puzzle non mostra punteggi', (tester) async {
      setPhone(tester);
      final t = await trainer();
      await tester.pumpWidget(kidApp(PuzzlePage(trainer: t, puzzle: backRank)));
      await tester.pumpAndSettle();
      expect(digitTexts(tester), isEmpty);
      await tapMove(tester, 'a1a8');
      await tester.pump();
      expect(find.textContaining('Punteggio'), findsNothing);
      expect(find.textContaining('punteggio'), findsNothing);
      expect(find.textContaining('${backRank.rating}'), findsNothing);
      expect(find.textContaining('Risolto'), findsOneWidget);
    });
  });

  group('RP-06 revisione e analisi', () {
    setUp(ReviewCache.clear);

    testWidgets('la revisione mostra stelle e parole, non cifre', (
      tester,
    ) async {
      setPhone(tester);
      await tester.pumpWidget(
        kidApp(
          ReviewPage(
            initial: Chess.initial,
            moves: moves(scholar),
            evaluate: fakeEngine(scholar, overrides: scholarOverrides),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('accuracy-white')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('accuracy-white')),
          matching: find.byIcon(Icons.star),
        ),
        findsWidgets,
      );
      expect(find.textContaining(RegExp(r'^\d+\.\d$')), findsNothing);
      expect(find.textContaining('Elo'), findsNothing);
      expect(find.text('Mosse per categoria'), findsNothing);
      final eval = tester.widget<Text>(find.byKey(const ValueKey('eval-text')));
      expect(eval.data, isEmpty);
      // Le classificazioni delle mosse restano, a parole e simboli.
      expect(find.textContaining('??'), findsWidgets);
    });

    testWidgets('l\'analisi non mostra valutazioni né profondità', (
      tester,
    ) async {
      setPhone(tester);
      final lines = StreamController<List<InfoLine>>();
      addTearDown(lines.close);
      await tester.pumpWidget(
        kidApp(
          AnalysisPage(initial: Chess.initial, analyse: (_, _) => lines.stream),
        ),
      );
      await tester.pump();
      lines.add(const [
        InfoLine(
          multipv: 1,
          depth: 18,
          pv: ['e2e4', 'e7e5', 'g1f3'],
          score: EngineScore.cp(34),
        ),
      ]);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('e4 e5 Nf3'), findsOneWidget);
      expect(find.text('+0.3'), findsNothing);
      expect(find.textContaining('Profondità'), findsNothing);
      final eval = tester.widget<Text>(find.byKey(const ValueKey('eval-text')));
      expect(eval.data, isEmpty);
    });
  });
}
