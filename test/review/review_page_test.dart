import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/review/game_review.dart';
import 'package:scacchi/review/review_page.dart';

import 'fake_engine.dart';

Future<void> pumpReview(
  WidgetTester tester, {
  PositionEvaluator? evaluate,
  VoidCallback? onCancel,
  ValueChanged<GameReview>? onReviewed,
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
      ),
    ),
  );
}

void main() {
  setUp(ReviewCache.clear);

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

    testWidgets('RF-61 la lista mostra la categoria di ogni mossa', (
      tester,
    ) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nf6 ??'));
      await tester.tap(find.text('Nf6 ??'));
      await tester.pumpAndSettle();
      expect(find.text('3… Nf6 è un errore grave'), findsOneWidget);
      expect(find.text('Migliore: g6'), findsOneWidget);
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
        '#',
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
      await tester.ensureVisible(find.text('Nf6 ??'));
      await tester.tap(find.text('Nf6 ??'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();
      expect(find.text('Trova una mossa migliore di Nf6'), findsOneWidget);

      Chessboard board() => tester.widget<Chessboard>(find.byType(Chessboard));
      board().onMove!(NormalMove.fromUci('a7a6'));
      await tester.pumpAndSettle();
      expect(find.text('a6 non è la mossa migliore. Riprova.'), findsOneWidget);

      board().onMove!(NormalMove.fromUci('g7g6'));
      await tester.pumpAndSettle();
      expect(find.text('Esatto: g6 è la mossa migliore.'), findsOneWidget);
    });

    testWidgets('RF-65 Riprova: si può vedere la soluzione', (tester) async {
      await pumpReview(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nf6 ??'));
      await tester.tap(find.text('Nf6 ??'));
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
}
