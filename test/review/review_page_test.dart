import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/analysis/analysis_page.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/game/clock.dart';
import 'package:scacchi/review/game_review.dart';
import 'package:scacchi/review/personal_puzzles.dart';
import 'package:scacchi/review/review_page.dart';

import 'fake_engine.dart';

Future<void> pumpReview(
  WidgetTester tester, {
  PositionEvaluator? evaluate,
  VoidCallback? onCancel,
  ValueChanged<GameReview>? onReviewed,
  List<Duration?> clocks = const [],
  TimeControl? control,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ReviewPage(
        initial: Chess.initial,
        moves: moves(scholar),
        evaluate: evaluate ?? fakeEngine(scholar, overrides: scholarOverrides),
        onCancel: onCancel,
        onReviewed: onReviewed,
        clocks: clocks,
        timeControl: control,
      ),
    ),
  );
}

void main() {
  setUp(ReviewCache.clear);

  testWidgets('RF-50 dalla revisione si analizza la posizione mostrata', (
    tester,
  ) async {
    final fens = <String>[];
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          initial: Chess.initial,
          moves: moves(scholar),
          evaluate: fakeEngine(scholar, overrides: scholarOverrides),
          analyseLive: (fen, _) {
            fens.add(fen);
            return const Stream.empty();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mossa precedente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Analizza la posizione'));
    await tester.pumpAndSettle();
    expect(find.byType(AnalysisPage), findsOneWidget);
    expect(fens.single, startsWith('r1bqkb1r/pppp1ppp/2n2n2/4p2Q/'));
  });

  testWidgets('l\'analisi della posizione aspetta la fine della revisione', (
    tester,
  ) async {
    final pending = Completer<List<InfoLine>>();
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          initial: Chess.initial,
          moves: moves(scholar),
          evaluate: (_) => pending.future,
          analyseLive: (_, _) => const Stream.empty(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byTooltip('Analizza la posizione'), findsNothing);
    pending.complete(const []);
  });

  testWidgets('durante Riprova si analizza la posizione sulla scacchiera', (
    tester,
  ) async {
    final fens = <String>[];
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          initial: Chess.initial,
          moves: moves(scholar),
          evaluate: fakeEngine(scholar, overrides: scholarOverrides),
          analyseLive: (fen, _) {
            fens.add(fen);
            return const Stream.empty();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('♞f6 ??'));
    await tester.tap(find.text('♞f6 ??'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Analizza la posizione'));
    await tester.pumpAndSettle();
    // Posizione prima di Cf6, non dopo.
    expect(fens.single, startsWith('r1bqkbnr/pppp1ppp/2n5/4p2Q/'));
  });

  testWidgets('numeri di mossa da una posizione con il Nero al tratto', (
    tester,
  ) async {
    final initial = Chess.fromSetup(
      Setup.parseFen(
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          initial: initial,
          moves: moves(['e7e5', 'g1f3']),
          evaluate: (_) async => [
            const InfoLine(multipv: 1, pv: ['a2a3'], score: EngineScore.cp(0)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1…'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.textContaining('2. ♞f3 è'), findsOneWidget);
  });

  testWidgets('RF-54 la freccia dell\'arrocco punta alla casa del re', (
    tester,
  ) async {
    // Il Bianco può arroccare corto; il motore lo indica come mossa migliore.
    final initial = Chess.fromSetup(
      Setup.parseFen('4k3/8/8/8/8/8/5PPP/4K2R w K - 0 1'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewPage(
          initial: initial,
          moves: moves(['h2h3']),
          evaluate: (fen) async => [
            InfoLine(
              multipv: 1,
              pv: [fen.contains(' w ') ? 'e1g1' : 'e8d8'],
              score: const EngineScore.cp(0),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final board = tester.widget<Chessboard>(find.byType(Chessboard));
    final arrow = board.shapes.whereType<Arrow>().single;
    expect(arrow.orig, Square.e1);
    expect(arrow.dest, Square.g1);
  });

  group('RF-60 schermata di revisione', () {
    testWidgets('mostra l\'avanzamento e permette di interrompere', (
      tester,
    ) async {
      final pending = Completer<List<InfoLine>>();
      var cancelled = false;
      await pumpReview(
        tester,
        evaluate: (_) => pending.future,
        onCancel: () => cancelled = true,
      );
      await tester.pump();
      expect(find.text('Analisi in corso: 0 di 8'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Interrompi'));
      await tester.pump();
      expect(cancelled, isTrue);
      expect(find.text('Revisione interrotta.'), findsOneWidget);
      pending.complete(const []);
    });

    testWidgets('RF-63 riepilogo con precisione e stima della forza', (
      tester,
    ) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('Precisione'), findsWidgets);
      expect(find.byKey(const ValueKey('accuracy-white')), findsOneWidget);
      expect(find.byKey(const ValueKey('accuracy-black')), findsOneWidget);
      expect(find.textContaining('Elo stimato'), findsWidgets);
    });

    testWidgets('il tempo per mossa compare solo con i tempi registrati', (
      tester,
    ) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      expect(find.text('Tempo per mossa'), findsNothing);

      ReviewCache.clear();
      await pumpReview(
        tester,
        control: const TimeControl(minutes: 5),
        clocks: [
          for (var i = 0; i < scholar.length; i++)
            Duration(seconds: 300 - 10 * (i + 1)),
        ],
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tempo per mossa'));
      await tester.tap(find.text('Tempo per mossa'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(r'Tempo per mossa\. ')),
        findsOneWidget,
      );
    });

    testWidgets('la precisione si divide per fase della partita', (
      tester,
    ) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Precisione per fase'));
      await tester.tap(find.text('Precisione per fase'));
      await tester.pumpAndSettle();
      // La partita del barbiere finisce in apertura: le altre fasi sono vuote.
      expect(find.text('Apertura'), findsOneWidget);
      expect(find.text('Mediogioco'), findsOneWidget);
      expect(find.text('Finale'), findsOneWidget);
      // I valori dicono di chi sono.
      expect(find.text('Bianco — · Nero —'), findsNWidgets(2));
      expect(
        find.bySemanticsLabel(RegExp(r'Apertura: Bianco \d+, Nero \d+')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Mediogioco: Bianco —, Nero —'),
        findsOneWidget,
      );
    });

    testWidgets('RF-61 la lista mostra la categoria di ogni mossa', (
      tester,
    ) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('♞f6 ??'));
      await tester.tap(find.text('♞f6 ??'));
      await tester.pumpAndSettle();
      expect(find.text('3… ♞f6 è un errore grave'), findsOneWidget);
      expect(find.text('Migliore: g6'), findsOneWidget);
    });

    testWidgets('RF-70 il coach spiega l\'errore', (tester) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('♞f6 ??'));
      await tester.tap(find.text('♞f6 ??'));
      await tester.pumpAndSettle();
      expect(
        find.text('Dopo ♞f6 il Bianco dà matto in 1 con ♛xf7#.'),
        findsOneWidget,
      );
    });

    testWidgets('RF-50 barra di valutazione con valore numerico', (
      tester,
    ) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      // Si apre sull'ultima mossa: il Bianco ha dato matto.
      expect(find.byKey(const ValueKey('eval-text')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('eval-text'))).data,
        '1-0',
      );
      expect(
        find.bySemanticsLabel('Scacco matto: vince il Bianco'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Mossa precedente'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('eval-text'))).data,
        'M1',
      );
    });

    testWidgets('RF-54 freccia della mossa migliore sulla scacchiera', (
      tester,
    ) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mossa precedente'));
      await tester.pumpAndSettle();
      final board = tester.widget<Chessboard>(find.byType(Chessboard));
      final arrows = board.shapes.whereType<Arrow>();
      expect(arrows.single.orig, Square.g7);
      expect(arrows.single.dest, Square.g6);
      // La categoria compare sulla casa d'arrivo della mossa giocata.
      expect(board.annotations[Square.f6]?.symbol, '??');
    });

    testWidgets('RF-64 il grafico porta alla mossa toccata', (tester) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      final graph = find.byKey(const ValueKey('eval-graph'));
      expect(graph, findsOneWidget);
      final box = tester.getRect(graph);
      // Ottava posizione su otto: l'ultima mossa; prima posizione: l'inizio.
      await tester.tapAt(Offset(box.left + 1, box.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Posizione iniziale'), findsOneWidget);
    });

    testWidgets('RF-65 Riprova: si cerca la mossa migliore', (tester) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('♞f6 ??'));
      await tester.tap(find.text('♞f6 ??'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();
      expect(find.text('Trova una mossa migliore di ♞f6'), findsOneWidget);

      Chessboard board() => tester.widget<Chessboard>(find.byType(Chessboard));
      board().onMove!(NormalMove.fromUci('a7a6'));
      await tester.pumpAndSettle();
      expect(find.text('a6 non è la mossa migliore. Riprova.'), findsOneWidget);

      board().onMove!(NormalMove.fromUci('g7g6'));
      await tester.pumpAndSettle();
      expect(find.text('Esatto: g6 è la mossa migliore.'), findsOneWidget);
      // La mossa giusta resta sulla scacchiera, che non accetta altre mosse.
      final solved = board().controller.game;
      expect(solved.playerSide, PlayerSide.none);
      expect(solved.fen, startsWith('r1bqkbnr/pppp1p1p/2n3p1/4p2Q/'));
    });

    testWidgets('RF-65 durante Riprova la barra valuta la posizione critica', (
      tester,
    ) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('♞f6 ??'));
      await tester.tap(find.text('♞f6 ??'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();
      // Prima di Cf6 il motore vede +0.3 per il Bianco, non il matto.
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('eval-text'))).data,
        '+0.3',
      );
    });

    testWidgets('RF-65 Riprova: si può vedere la soluzione', (tester) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('♞f6 ??'));
      await tester.tap(find.text('♞f6 ??'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Soluzione'));
      await tester.pumpAndSettle();
      expect(find.text('La mossa migliore era g6.'), findsOneWidget);
    });

    testWidgets('RF-66 la seconda apertura usa il risultato in memoria', (
      tester,
    ) async {
      final calls = <String>[];
      final engine = fakeEngine(
        scholar,
        overrides: scholarOverrides,
        calls: calls,
      );
      var reviewed = 0;
      await pumpReview(tester, evaluate: engine, onReviewed: (_) => reviewed++);
      await tester.pumpAndSettle();
      expect(calls, hasLength(7));
      expect(reviewed, 1, reason: 'una revisione completata dà XP una volta');
      await tester.pumpWidget(const SizedBox());
      await pumpReview(tester, evaluate: engine, onReviewed: (_) => reviewed++);
      await tester.pump();
      expect(calls, hasLength(7));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(reviewed, 1);
    });
  });

  group('RF-80 salvataggio degli errori come puzzle', () {
    Future<void> pumpWith(
      WidgetTester tester, {
      Future<int> Function(List<MistakePuzzle>)? save,
      Set<Side> players = const {Side.white, Side.black},
    }) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            initial: Chess.initial,
            moves: moves(scholar),
            evaluate: fakeEngine(scholar, overrides: scholarOverrides),
            onSavePuzzles: save,
            puzzlePlayers: players,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('il pulsante salva i puzzle e conferma', (tester) async {
      final saved = <MistakePuzzle>[];
      await pumpWith(
        tester,
        save: (puzzles) async {
          saved.addAll(puzzles);
          return puzzles.length;
        },
      );
      expect(find.text('Salva gli errori come puzzle (1)'), findsOneWidget);
      await tester.tap(find.text('Salva gli errori come puzzle (1)'));
      await tester.pumpAndSettle();
      expect(saved.single.id, startsWith('mio-'));
      expect(saved.single.id, endsWith('-5'));
      expect(
        find.text(
          'Puzzle salvati: 1. Li trovi in Puzzle › Ripasso degli errori.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Salva gli errori'), findsNothing);
    });

    testWidgets('senza errori dei giocatori scelti non c\'è il pulsante', (
      tester,
    ) async {
      await pumpWith(
        tester,
        save: (p) async => p.length,
        players: {Side.white},
      );
      expect(find.textContaining('Salva gli errori'), findsNothing);
    });

    testWidgets('senza salvataggio disponibile non c\'è il pulsante', (
      tester,
    ) async {
      await pumpWith(tester);
      expect(find.textContaining('Salva gli errori'), findsNothing);
    });

    testWidgets('già salvati: lo dice invece di duplicare', (tester) async {
      await pumpWith(tester, save: (_) async => 0);
      await tester.tap(find.text('Salva gli errori come puzzle (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Questi puzzle sono già salvati.'), findsOneWidget);
    });

    testWidgets('un errore di salvataggio si può riprovare', (tester) async {
      var attempts = 0;
      await pumpWith(
        tester,
        save: (p) async {
          if (attempts++ == 0) throw StateError('disco pieno');
          return p.length;
        },
      );
      await tester.tap(find.text('Salva gli errori come puzzle (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Salvataggio non riuscito. Riprova.'), findsOneWidget);
      await tester.tap(find.text('Salva gli errori come puzzle (1)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Puzzle salvati: 1'), findsOneWidget);
    });
  });
}
