import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/analysis/analysis_page.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/settings/board_marks.dart';
import 'package:scacchi/settings/settings.dart';

/// Motore finto: ogni richiesta apre un flusso controllato dal test.
class FakeLive {
  final requests = <({String fen, int multiPv})>[];
  final controllers = <StreamController<List<InfoLine>>>[];
  var cancelled = 0;

  Stream<List<InfoLine>> call(String fen, int multiPv) {
    requests.add((fen: fen, multiPv: multiPv));
    final c = StreamController<List<InfoLine>>(onCancel: () => cancelled++);
    controllers.add(c);
    return c.stream;
  }

  void emit(List<InfoLine> lines) => controllers.last.add(lines);
}

const e4 = InfoLine(
  multipv: 1,
  depth: 18,
  pv: ['e2e4', 'e7e5', 'g1f3'],
  score: EngineScore.cp(34),
);
const d4 = InfoLine(
  multipv: 2,
  depth: 18,
  pv: ['d2d4', 'd7d5'],
  score: EngineScore.cp(28),
);

Future<FakeLive> pumpAnalysis(
  WidgetTester tester, {
  Position? initial,
  Side orientation = Side.white,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final live = FakeLive();
  await tester.pumpWidget(
    MaterialApp(
      home: AnalysisPage(
        initial: initial ?? Chess.initial,
        analyse: live.call,
        orientation: orientation,
      ),
    ),
  );
  await tester.pump();
  return live;
}

Chessboard board(WidgetTester tester) =>
    tester.widget<Chessboard>(find.byType(Chessboard));

Future<void> settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 300));

void main() {
  group('RF-50 RF-51 schermata di analisi', () {
    testWidgets(
      'mostra le linee del motore in SAN con valutazione e profondità',
      (tester) async {
        final live = await pumpAnalysis(tester);
        expect(live.requests.single.fen, Chess.initial.fen);
        live.emit([e4, d4]);
        await settle(tester);
        expect(find.text('e4 e5 ♞f3'), findsOneWidget);
        expect(find.text('d4 d5'), findsOneWidget);
        expect(find.text('+0.3'), findsWidgets);
        expect(find.text('Profondità 18'), findsOneWidget);
      },
    );

    testWidgets(
      'la barra mostra la valutazione dal punto di vista del Bianco',
      (tester) async {
        final afterE4 = Chess.initial.play(Move.parse('e2e4')!);
        final live = await pumpAnalysis(tester, initial: afterE4);
        // Il Nero al tratto vede -0.5: per il Bianco è +0.5.
        live.emit([
          const InfoLine(
            multipv: 1,
            depth: 10,
            pv: ['e7e5'],
            score: EngineScore.cp(-50),
          ),
        ]);
        await settle(tester);
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('eval-text'))).data,
          '+0.5',
        );
      },
    );

    testWidgets('si sceglie il numero di linee da 1 a 3', (tester) async {
      final live = await pumpAnalysis(tester);
      expect(live.requests.single.multiPv, 1);
      await tester.tap(find.text('3 linee'));
      await settle(tester);
      expect(live.requests.last.multiPv, 3);
      expect(live.cancelled, 1);
    });

    testWidgets('RF-52 si esplora muovendo e si torna indietro', (
      tester,
    ) async {
      final live = await pumpAnalysis(tester);
      board(tester).onMove!(NormalMove.fromUci('e2e4'));
      await settle(tester);
      final afterE4 = Chess.initial.play(Move.parse('e2e4')!);
      expect(live.requests.last.fen, afterE4.fen);
      expect(find.text('1. e4'), findsOneWidget);

      await tester.tap(find.byTooltip('Indietro'));
      await settle(tester);
      expect(live.requests.last.fen, Chess.initial.fen);
      await tester.tap(find.byTooltip('Avanti'));
      await settle(tester);
      expect(live.requests.last.fen, afterE4.fen);
    });

    testWidgets('RF-52 una mossa diversa crea una variante senza perdere il '
        'seguito', (tester) async {
      final live = await pumpAnalysis(tester);
      board(tester).onMove!(NormalMove.fromUci('e2e4'));
      await settle(tester);
      board(tester).onMove!(NormalMove.fromUci('e7e5'));
      await settle(tester);
      await tester.tap(find.byTooltip('Indietro'));
      await settle(tester);
      board(tester).onMove!(NormalMove.fromUci('c7c5'));
      await settle(tester);
      // La linea principale resta e la variante compare tra parentesi.
      expect(find.text('1. e4'), findsOneWidget);
      expect(find.text('e5'), findsOneWidget);
      expect(find.text('1… c5'), findsOneWidget);
      expect(live.requests.last.fen, contains('2p5'));
    });

    testWidgets('RF-52 toccare una mossa dell\'albero porta in quella '
        'posizione', (tester) async {
      final live = await pumpAnalysis(tester);
      board(tester).onMove!(NormalMove.fromUci('e2e4'));
      await settle(tester);
      board(tester).onMove!(NormalMove.fromUci('e7e5'));
      await settle(tester);
      board(tester).onMove!(NormalMove.fromUci('g1f3'));
      await settle(tester);
      await tester.tap(find.text('e5'));
      await settle(tester);
      final afterE5 = Chess.initial
          .play(Move.parse('e2e4')!)
          .play(Move.parse('e7e5')!);
      expect(live.requests.last.fen, afterE5.fen);
    });

    testWidgets('RF-52 una variante si promuove a linea principale', (
      tester,
    ) async {
      await pumpAnalysis(tester);
      board(tester).onMove!(NormalMove.fromUci('e2e4'));
      await settle(tester);
      board(tester).onMove!(NormalMove.fromUci('e7e5'));
      await settle(tester);
      await tester.tap(find.byTooltip('Indietro'));
      await settle(tester);
      board(tester).onMove!(NormalMove.fromUci('c7c5'));
      await settle(tester);
      await tester.tap(find.byTooltip('Promuovi a linea principale'));
      await settle(tester);
      // Dopo la promozione la linea principale è 1. e4 c5 e il pulsante si
      // disattiva.
      expect(find.text('1. e4'), findsOneWidget);
      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.upgrade),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('RF-52 una variante si elimina', (tester) async {
      final live = await pumpAnalysis(tester);
      board(tester).onMove!(NormalMove.fromUci('e2e4'));
      await settle(tester);
      board(tester).onMove!(NormalMove.fromUci('e7e5'));
      await settle(tester);
      await tester.tap(find.byTooltip('Indietro'));
      await settle(tester);
      board(tester).onMove!(NormalMove.fromUci('c7c5'));
      await settle(tester);
      await tester.tap(find.byTooltip('Elimina la mossa e il seguito'));
      await settle(tester);
      expect(find.text('1… c5'), findsNothing);
      expect(find.text('e5'), findsOneWidget);
      final afterE4 = Chess.initial.play(Move.parse('e2e4')!);
      expect(live.requests.last.fen, afterE4.fen);
    });

    testWidgets('RF-52 dalla posizione iniziale non ci sono mosse da gestire', (
      tester,
    ) async {
      await pumpAnalysis(tester);
      expect(find.byTooltip('Promuovi a linea principale'), findsNothing);
      expect(find.byTooltip('Elimina la mossa e il seguito'), findsNothing);
    });

    testWidgets('RF-56 la minaccia analizza la posizione a mossa nulla', (
      tester,
    ) async {
      final live = await pumpAnalysis(tester);
      await tester.tap(find.byTooltip('Minaccia dell\'avversario'));
      await settle(tester);
      // Il motore ha una coda sola: prima la minaccia, con il turno passato
      // al Nero, poi l'analisi principale.
      expect(live.requests.last.fen.split(' ')[1], 'b');
      expect(live.requests.last.multiPv, 1);
      live.emit(const [
        InfoLine(
          multipv: 1,
          depth: 14,
          pv: ['e7e5'],
          score: EngineScore.cp(20),
        ),
      ]);
      await settle(tester);
      expect(live.requests.last.fen, Chess.initial.fen);
      final arrows = board(tester).shapes.whereType<Arrow>().toList();
      expect(arrows, hasLength(1));
      expect(arrows.single.orig, Square.e7);
      expect(arrows.single.dest, Square.e5);
      // Diversa dalla freccia verde della mossa migliore.
      expect(arrows.single.color, BoardMarks.of(BoardTheme.green).threat);
    });

    testWidgets('RF-56 la minaccia di una posizione non resta sulla seguente', (
      tester,
    ) async {
      final live = await pumpAnalysis(tester);
      await tester.tap(find.byTooltip('Minaccia dell\'avversario'));
      await settle(tester);
      live.emit(const [
        InfoLine(multipv: 1, depth: 14, pv: ['e7e5'], score: EngineScore.cp(0)),
      ]);
      await settle(tester);
      board(tester).onMove!(NormalMove.fromUci('e2e4'));
      await settle(tester);
      expect(board(tester).shapes.whereType<Arrow>(), isEmpty);
    });

    testWidgets('RF-56 spenta, l\'analisi torna una sola', (tester) async {
      final live = await pumpAnalysis(tester);
      await tester.tap(find.byTooltip('Minaccia dell\'avversario'));
      await settle(tester);
      await tester.tap(find.byTooltip('Minaccia dell\'avversario'));
      await settle(tester);
      expect(live.requests.last.fen, Chess.initial.fen);
      expect(board(tester).shapes.whereType<Arrow>(), isEmpty);
    });

    testWidgets('RF-56 in pausa il pulsante non avvia nessun motore', (
      tester,
    ) async {
      final live = await pumpAnalysis(tester);
      await tester.tap(find.byTooltip('Ferma l\'analisi'));
      await settle(tester);
      final before = live.requests.length;
      await tester.tap(find.byTooltip('Minaccia dell\'avversario'));
      await settle(tester);
      expect(live.requests, hasLength(before));
    });

    testWidgets('RF-56 non è disponibile sotto scacco', (tester) async {
      final check = Chess.fromSetup(
        Setup.parseFen('4k3/8/8/8/8/8/4r3/4K3 w - - 0 1'),
      );
      await pumpAnalysis(tester, initial: check);
      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.warning_amber),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('toccare una linea ne gioca la prima mossa', (tester) async {
      final live = await pumpAnalysis(tester);
      live.emit([e4, d4]);
      await settle(tester);
      await tester.tap(find.text('d4 d5'));
      await settle(tester);
      expect(
        live.requests.last.fen,
        Chess.initial.play(Move.parse('d2d4')!).fen,
      );
    });

    testWidgets('l\'analisi si mette in pausa e riprende', (tester) async {
      final live = await pumpAnalysis(tester);
      await tester.tap(find.byTooltip('Ferma l\'analisi'));
      await settle(tester);
      expect(live.cancelled, 1);
      expect(find.text('Analisi in pausa'), findsOneWidget);
      await tester.tap(find.byTooltip('Riprendi l\'analisi'));
      await settle(tester);
      expect(live.requests, hasLength(2));
    });

    testWidgets('RF-54 freccia della mossa migliore attivabile', (
      tester,
    ) async {
      final live = await pumpAnalysis(tester);
      live.emit([e4]);
      await settle(tester);
      final arrow = board(tester).shapes.whereType<Arrow>().single;
      expect(arrow.orig, Square.e2);
      expect(arrow.dest, Square.e4);
      await tester.tap(find.byTooltip('Freccia della mossa migliore'));
      await settle(tester);
      expect(board(tester).shapes, isEmpty);
    });

    testWidgets('un errore del motore viene mostrato', (tester) async {
      final live = await pumpAnalysis(tester);
      live.controllers.last.addError(StateError('Motore chiuso'));
      await settle(tester);
      expect(find.text('Motore non disponibile'), findsOneWidget);
    });

    testWidgets('la scacchiera è orientata dal lato del giocatore', (
      tester,
    ) async {
      await pumpAnalysis(tester, orientation: Side.black);
      expect(board(tester).orientation, Side.black);
    });

    testWidgets('chiudere la pagina ferma il motore', (tester) async {
      final live = await pumpAnalysis(tester);
      await tester.pumpWidget(const SizedBox());
      expect(live.cancelled, 1);
    });
  });

  testWidgets('RNF-05 in secondo piano il motore si ferma e poi riparte', (
    tester,
  ) async {
    final live = await pumpAnalysis(tester);
    expect(live.requests, hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(live.cancelled, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(live.requests, hasLength(2));
  });
}
