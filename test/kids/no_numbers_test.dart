import 'dart:async';
import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/analysis/analysis_page.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/home/you_page.dart';
import 'package:scacchi/kids/kid_display.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/progress/achievements.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/avatar.dart';
import 'package:scacchi/progress/profile_page.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_feedback.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/progress/progress_tracker.dart';
import 'package:scacchi/progress/rewards.dart';
import 'package:scacchi/progress/xp.dart';
import 'package:scacchi/puzzles/puzzle_hub_page.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_page.dart';
import 'package:scacchi/puzzles/puzzle_run.dart';
import 'package:scacchi/puzzles/puzzle_trainer.dart';
import 'package:scacchi/review/coach.dart';
import 'package:scacchi/review/review_page.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/settings/settings_page.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../puzzles/fixtures.dart';
import '../puzzles/puzzle_page_test.dart' show tapMove;
import '../review/coach_test.dart' show line, reviewOne;
import '../review/fake_engine.dart';

final _digit = RegExp(r'\d');

SettingsController kidSettings({bool kid = true}) =>
    SettingsController.defaults()..value = AppSettings(kidMode: kid);

/// App localizzata (italiano di default) con il profilo bambino acceso o spento.
Widget kidApp(
  Widget home, {
  bool kid = true,
  Locale locale = const Locale('it'),
  SettingsController? settings,
}) => SettingsScope(
  controller: settings ?? kidSettings(kid: kid),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
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
  tester.view.physicalSize = const Size(1170, 3800);
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
      freezeEarned: true,
      rewards: [Avatar.bishop],
    );

    Future<void> showFeedback(
      WidgetTester tester, {
      required bool kid,
      Locale locale = const Locale('it'),
    }) async {
      await tester.pumpWidget(
        kidApp(
          kid: kid,
          locale: locale,
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
      // Lo scudo non si vede da nessuna parte nel profilo bambino.
      expect(text.data, isNot(contains('scudo')));
      expect(text.data, contains('ricompensa'));
    });

    testWidgets('in inglese la ricompensa non mescola le lingue', (
      tester,
    ) async {
      await showFeedback(tester, kid: true, locale: const Locale('en'));
      final text = tester.widget<Text>(
        find.descendant(of: find.byType(SnackBar), matching: find.byType(Text)),
      );
      expect(text.data, isNot(contains(rewardName(Avatar.bishop))));
      expect(text.data, contains('reward'));
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

      // Fino in fondo: niente impostazioni degli XP né altri numeri.
      await tester.scrollUntilVisible(find.text(achievements.last.title), 300);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text(achievements.last.title), findsOneWidget);
      expect(find.byKey(const Key('enabled')), findsNothing);
      expect(find.textContaining('XP'), findsNothing);
      expect(find.text('Obiettivo giornaliero'), findsNothing);
    });

    testWidgets('i requisiti bloccati non citano il livello', (tester) async {
      final semantics = tester.ensureSemantics();
      setPhone(tester);
      await tester.pumpWidget(kidApp(ProfilePage(controller: controller)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('avatar')));
      await tester.pumpAndSettle();
      // Dietro il foglio restano i traguardi «Livello 5» e «Livello 10»: sono
      // nomi, non requisiti, quindi si guarda solo il foglio.
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.textContaining('Livello')),
        findsNothing,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Si sblocca giocando')),
        findsWidgets,
      );
      expect(find.bySemanticsLabel(RegExp('si sblocca con')), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('si sblocca giocando')),
        findsWidgets,
      );
      semantics.dispose();
    });

    testWidgets('nelle impostazioni i temi bloccati non citano il livello', (
      tester,
    ) async {
      setPhone(tester);
      final settings = kidSettings();
      await tester.pumpWidget(
        kidApp(
          settings: settings,
          SettingsPage(controller: settings, progress: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Sabbia'), 200);
      final semantics = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp('Sabbia, bloccato. Si sblocca giocando')),
        findsOneWidget,
      );
      semantics.dispose();
      await tester.ensureVisible(find.text('Sabbia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sabbia'));
      await tester.pump();
      expect(find.textContaining('Livello'), findsNothing);
      expect(find.text('Sabbia: si sblocca giocando'), findsOneWidget);
    });

    testWidgets('la scheda Tu mostra stelle e fiamma, non livello e giorni', (
      tester,
    ) async {
      await tester.runAsync(
        () => controller.record(const GamePlayed(result: GameResult.win)),
      );
      setPhone(tester);
      await tester.pumpWidget(
        kidApp(
          YouPage(
            simple: true,
            progress: () async => controller,
            path: () => Completer<PathController>().future,
            archive: () => Completer<GameArchive>().future,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp(r'^Livello \d')), findsNothing);
      expect(find.textContaining('di fila'), findsNothing);
      expect(find.byType(KidStars), findsOneWidget);
      expect(find.byType(KidFlame), findsOneWidget);
    });

    testWidgets('la scheda Tu non mostra i Tornei, che hanno Elo e punti', (
      tester,
    ) async {
      setPhone(tester);
      await tester.pumpWidget(
        kidApp(
          YouPage(
            simple: true,
            progress: () async => controller,
            path: () => Completer<PathController>().future,
            archive: () => Completer<GameArchive>().future,
            tournamentPage: () async => const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tornei'), findsNothing);
      expect(find.text('Percorso'), findsOneWidget);
    });

    testWidgets('le stelle si fermano a dieci', (tester) async {
      await tester.pumpWidget(
        kidApp(const Scaffold(body: KidStars(count: 25, label: 'stelle'))),
      );
      expect(find.byIcon(Icons.star), findsNWidgets(kidMaxStars));
    });
  });

  group('RP-06 stelle della precisione', () {
    test('una stella ogni venti punti, da una a cinque', () {
      expect(kidAccuracyStars(0), 1);
      expect(kidAccuracyStars(19.9), 1);
      expect(kidAccuracyStars(20), 1);
      expect(kidAccuracyStars(39.9), 1);
      expect(kidAccuracyStars(40), 2);
      expect(kidAccuracyStars(80), 4);
      expect(kidAccuracyStars(80.5), 4);
      expect(kidAccuracyStars(99.9), 4);
      expect(kidAccuracyStars(100), 5);
    });
  });

  group('RP-06 coach senza numeri', () {
    final l = lookupAppLocalizations(const Locale('it'));

    test('perdita di materiale senza il conto dei pedoni', () async {
      final m = await reviewOne(
        '3qk3/8/8/8/8/8/8/4K2R w K - 0 1',
        'e1f2',
        best: line(['h1h8'], const EngineScore.cp(0)),
        reply: line(['e8f7', 'h1d1', 'd8d1'], const EngineScore.cp(500)),
      );
      final c = explainMove(m, kid: l)!;
      expect(c.theme, CoachTheme.materialLoss);
      expect(c.text, isNot(matches(_digit)));
      expect(c.text, isNot(contains('pedoni')));
    });

    test('matto concesso e mancato senza «matto in N»', () async {
      final allowed = await reviewOne(
        'r1bqkbnr/pppp1ppp/2n5/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 3 3',
        'g8f6',
        best: line(['g7g6'], const EngineScore.cp(-30)),
        reply: line(['h5f7'], const EngineScore.mate(1)),
      );
      final a = explainMove(allowed, kid: l)!;
      expect(a.theme, CoachTheme.allowedMate);
      expect(a.text, contains('Qxf7#'));
      expect(a.text, isNot(contains('matto in')));

      final missed = await reviewOne(
        'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
        'a2a3',
        best: line(['f3f7'], const EngineScore.mate(1)),
        reply: line(['g8f6'], const EngineScore.cp(-20)),
      );
      final b = explainMove(missed, kid: l)!;
      expect(b.theme, CoachTheme.missedMate);
      expect(b.text, contains('Qxf7#'));
      expect(b.text, isNot(contains('matto in')));
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
      // Su Cf6?? il coach spiega il matto concesso senza «matto in 1».
      await tester.tap(find.byTooltip('Mossa precedente'));
      await tester.pumpAndSettle();
      expect(find.textContaining('scacco matto'), findsWidgets);
      expect(find.textContaining('matto in'), findsNothing);
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
      expect(find.text('e4 e5 ♞f3'), findsOneWidget);
      expect(find.text('+0.3'), findsNothing);
      expect(find.textContaining('Profondità'), findsNothing);
      final eval = tester.widget<Text>(find.byKey(const ValueKey('eval-text')));
      expect(eval.data, isEmpty);
    });
  });
}
