import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/openings/explorer_page.dart';
import 'package:scacchi/openings/opening_book.dart';
import 'package:scacchi/openings/openings_hub_page.dart';
import 'package:scacchi/openings/repertoire.dart';
import 'package:scacchi/openings/repertoire_page.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../puzzles/puzzle_page_test.dart' show tapMove;

final book = OpeningBook.parseTsv(
  'eco\tname\tuci\n'
  'C40\tKing\'s Knight Opening\te2e4 e7e5 g1f3\n',
);

List<Move> uci(String moves) =>
    moves.split(' ').map((m) => Move.parse(m)!).toList();

Future<void> phone(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: home));
  await tester.pumpAndSettle();
}

String message(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('drill-message'))).data!;

void main() {
  final day0 = DateTime(2026, 10, 10, 9);
  Future<RepertoireTrainer> trainer() =>
      RepertoireTrainer.load(MemoryStore(), now: () => day0);

  testWidgets('RF-93 il ripasso guida le mosse nuove e corregge gli errori', (
    tester,
  ) async {
    final t = await trainer();
    await t.addLine(Side.white, 'Italiana', uci('e2e4 e7e5 g1f3'));
    await phone(tester, RepertoirePage(trainer: t, side: Side.white));
    expect(find.text('Italiana'), findsOneWidget);
    expect(find.text('Ripassa 2 mosse'), findsOneWidget);

    await tester.tap(find.text('Ripassa 2 mosse'));
    await tester.pumpAndSettle();
    expect(message(tester), startsWith('Nuova mossa'));
    await tapMove(tester, 'e2e4');
    await tapMove(tester, 'b1c3');
    expect(message(tester), startsWith('Non è la mossa'));
    await tapMove(tester, 'g1f3');
    expect(message(tester), 'Ripasso completato: 2 mosse.');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Nessuna mossa da ripassare'), findsOneWidget);
  });

  testWidgets('RF-93 importa le varianti di un PGN come linee', (tester) async {
    final t = await trainer();
    await phone(tester, RepertoirePage(trainer: t, side: Side.black));
    expect(find.textContaining('Nessuna linea'), findsOneWidget);
    await tester.tap(find.byTooltip('Importa PGN'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      '1. e4 (1. d4 d5) 1... c5 *',
    );
    await tester.tap(find.text('Importa'));
    await tester.pumpAndSettle();
    expect(find.text('Linee aggiunte: 2'), findsOneWidget);
    expect(t.lines(Side.black), hasLength(2));

    await tester.tap(find.byTooltip('Elimina la linea').first);
    await tester.pumpAndSettle();
    expect(t.lines(Side.black), hasLength(1));
  });

  testWidgets('RF-93 dall\'explorer la linea va nel repertorio', (
    tester,
  ) async {
    final t = await trainer();
    await phone(
      tester,
      ExplorerPage(
        book: Future.value(book),
        initialMoves: uci('e2e4 e7e5 g1f3'),
        repertoire: t,
      ),
    );
    await tester.tap(find.byTooltip('Aggiungi al repertorio'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Apertura del cavallo di re',
    );
    await tester.tap(find.text('Aggiungi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Linea aggiunta al repertorio del Bianco.'),
      findsOneWidget,
    );
    expect(t.lines(Side.white).single.name, 'Apertura del cavallo di re');
  });

  testWidgets('RF-93 l\'hub mostra linee e mosse da ripassare', (tester) async {
    final t = await trainer();
    await t.addLine(Side.black, 'Siciliana', uci('e2e4 c7c5'));
    await phone(tester, OpeningsHubPage(repertoire: Future.value(t)));
    expect(find.text('Esplora aperture'), findsOneWidget);
    expect(find.text('Explorer'), findsNothing);
    expect(find.text('1 linee · 1 mosse da ripassare'), findsOneWidget);
    expect(find.text('0 linee · 0 mosse da ripassare'), findsOneWidget);
  });

  testWidgets('RF-93 l\'hub segnala un repertorio non caricabile', (
    tester,
  ) async {
    final failing = Future<RepertoireTrainer>.error(StateError('x'))..ignore();
    await phone(tester, OpeningsHubPage(repertoire: failing));
    expect(find.text('Repertorio non disponibile'), findsNWidgets(2));
  });
}
