import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/openings/explorer_page.dart';
import 'package:scacchi/openings/opening_book.dart';
import 'package:scacchi/openings/opening_name.dart';

final book = OpeningBook.parseTsv(
  'eco\tname\tuci\n'
  'C40\tKing\'s Knight Opening\te2e4 e7e5 g1f3\n'
  'C60\tRuy Lopez\te2e4 e7e5 g1f3 b8c6 f1b5\n'
  'B20\tSicilian Defense\te2e4 c7c5\n',
);

Future<void> phone(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: home));
  await tester.pumpAndSettle();
}

String opening(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('explorer-opening'))).data!;

void main() {
  testWidgets('RF-92 si naviga nel libro toccando le continuazioni', (
    tester,
  ) async {
    await phone(tester, ExplorerPage(book: Future.value(book)));
    expect(opening(tester), 'Posizione iniziale');
    await tester.tap(find.text('e4'));
    await tester.pumpAndSettle();
    expect(find.text('Sicilian Defense'), findsOneWidget);
    await tester.tap(find.text('e5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nf3'));
    await tester.pumpAndSettle();
    expect(opening(tester), 'C40 King\'s Knight Opening');
    expect(find.text('1. e4 e5 2. Nf3'), findsOneWidget);
    await tester.tap(find.text('Indietro'));
    await tester.pumpAndSettle();
    expect(find.text('1. e4 e5'), findsOneWidget);
  });

  testWidgets('RF-92 fuori dal libro lo dice', (tester) async {
    await phone(
      tester,
      ExplorerPage(
        book: Future.value(book),
        initialMoves: [Move.parse('a2a3')!],
      ),
    );
    expect(find.text('Fuori dal libro delle aperture'), findsOneWidget);
    expect(find.byType(Chessboard), findsOneWidget);
  });

  testWidgets('RF-90 il nome dell\'apertura sostituisce il titolo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OpeningName(
          moves: [Move.parse('e2e4')!, Move.parse('c7c5')!],
          fallback: 'Scacchi',
          book: Future.value(book),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('B20 Sicilian Defense'), findsOneWidget);
  });
}
