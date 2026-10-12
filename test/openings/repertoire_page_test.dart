import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/openings/explorer_page.dart';
import 'package:scacchi/openings/opening_book.dart';
import 'package:scacchi/openings/opening_game.dart';
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
    expect(find.text('1 linea · 1 mossa da ripassare'), findsOneWidget);
    expect(find.text('0 linee · 0 mosse da ripassare'), findsOneWidget);
  });

  testWidgets('RF-93 l\'hub segnala un repertorio non caricabile', (
    tester,
  ) async {
    final failing = Future<RepertoireTrainer>.error(StateError('x'))..ignore();
    await phone(tester, OpeningsHubPage(repertoire: failing));
    expect(find.text('Repertorio non disponibile'), findsNWidgets(2));
  });
  testWidgets('RF-94 dal repertorio si gioca la linea contro il computer', (
    tester,
  ) async {
    final t = await trainer();
    await t.addLine(Side.black, 'Siciliana', uci('e2e4 c7c5'));
    OpeningGameRequest? request;
    await phone(
      tester,
      RepertoirePage(
        trainer: t,
        side: Side.black,
        onPlay: (context, r) async => request = r,
      ),
    );
    await tester.tap(find.byTooltip('Gioca la linea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gioca'));
    await tester.pumpAndSettle();
    expect(request?.side, Side.black);
    expect(request?.line, uci('e2e4 c7c5'));
    expect(request?.startMoves, isEmpty);
  });

  testWidgets('RF-94 senza motore non c\'è il pulsante per giocare', (
    tester,
  ) async {
    final t = await trainer();
    await t.addLine(Side.black, 'Siciliana', uci('e2e4 c7c5'));
    await phone(tester, RepertoirePage(trainer: t, side: Side.black));
    expect(find.byTooltip('Gioca la linea'), findsNothing);
  });

  testWidgets('RF-94 dall\'explorer si gioca l\'apertura raggiunta', (
    tester,
  ) async {
    OpeningGameRequest? request;
    await phone(
      tester,
      ExplorerPage(
        book: Future.value(book),
        initialMoves: uci('e2e4 e7e5 g1f3'),
        onPlay: (context, r) async => request = r,
      ),
    );
    await tester.tap(find.byTooltip('Gioca questa apertura'));
    await tester.pumpAndSettle();
    // Dopo tre semimosse tocca al Nero: il colore proposto è il Nero.
    await tester.tap(find.text('Gioca'));
    await tester.pumpAndSettle();
    expect(request?.side, Side.black);
    expect(request?.startMoves, uci('e2e4 e7e5 g1f3'));
    expect(request?.line, isNull);
    expect(request?.title, 'Apertura del cavallo di re');
  });

  testWidgets('RF-94 nella posizione iniziale non si può giocare', (
    tester,
  ) async {
    await phone(
      tester,
      ExplorerPage(book: Future.value(book), onPlay: (context, r) async {}),
    );
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.play_arrow),
    );
    expect(button.onPressed, isNull);
  });
}
