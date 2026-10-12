import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/openings/explorer_page.dart';
import 'package:scacchi/openings/opening_book.dart';
import 'package:scacchi/openings/opening_name.dart';
import 'package:scacchi/openings/opening_stats.dart';
import 'package:scacchi/settings/notation.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localized_app.dart';

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
  await tester.pumpWidget(localizedApp(home: home));
  await tester.pumpAndSettle();
}

final stats = OpeningStats.parseTsv(
  'chiave\tmosse\n'
  '${keyAfter('')}\te4:1000:450:350,d4:800:400:280\n'
  '${keyAfter('e2e4')}\tc5:600:240:210,e5:400:180:120\n',
);

String keyAfter(String uci) {
  Position pos = Chess.initial;
  for (final m in uci.split(' ').where((s) => s.isNotEmpty)) {
    pos = pos.play(Move.parse(m)!);
  }
  return OpeningStats.keyOf(pos);
}

Future<void> withStats(WidgetTester tester, {List<Move> moves = const []}) =>
    phone(
      tester,
      ExplorerPage(
        book: Future.value(book),
        stats: Future.value(stats),
        initialMoves: moves,
      ),
    );

Side orientation(WidgetTester tester) =>
    tester.widget<Chessboard>(find.byType(Chessboard)).orientation;

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
    expect(find.text('Difesa siciliana'), findsOneWidget);
    await tester.tap(find.text('e5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('♞f3'));
    await tester.pumpAndSettle();
    expect(opening(tester), 'C40 Apertura del cavallo di re');
    expect(find.text('1. e4 e5 2. ♞f3'), findsOneWidget);
    await tester.tap(find.text('Indietro'));
    await tester.pumpAndSettle();
    expect(find.text('1. e4 e5'), findsOneWidget);
  });

  testWidgets('RF-76 le continuazioni seguono la notazione scelta', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    await settings.update(
      settings.value.copyWith(notation: MoveNotation.italian),
    );
    await phone(
      tester,
      SettingsScope(
        controller: settings,
        child: ExplorerPage(book: Future.value(book)),
      ),
    );
    await tester.tap(find.text('e4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('e5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cf3'));
    await tester.pumpAndSettle();
    expect(find.text('1. e4 e5 2. Cf3'), findsOneWidget);
  });

  testWidgets('la schermata è in italiano', (tester) async {
    await phone(tester, ExplorerPage(book: Future.value(book)));
    expect(find.text('Esplora aperture'), findsOneWidget);
    expect(find.text('Explorer'), findsNothing);
  });

  testWidgets('RF-92 le mosse iniziali illegali vengono scartate', (
    tester,
  ) async {
    await phone(
      tester,
      ExplorerPage(
        book: Future.value(book),
        initialMoves: [Move.parse('e2e4')!, Move.parse('e2e5')!],
      ),
    );
    expect(find.text('1. e4'), findsOneWidget);
    await tester.tap(find.text('c5'));
    await tester.pumpAndSettle();
    expect(opening(tester), 'B20 Difesa siciliana');
  });

  testWidgets('RF-92 un errore di caricamento non lascia la rotella', (
    tester,
  ) async {
    final failing = Future<OpeningBook>.error(StateError('x'))..ignore();
    await phone(tester, ExplorerPage(book: failing));
    expect(find.text('Impossibile caricare le aperture.'), findsOneWidget);
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
    expect(opening(tester), 'Apertura senza nome');
    expect(find.byType(Chessboard), findsOneWidget);
  });

  testWidgets('RF-90 il nome dell\'apertura sostituisce il titolo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OpeningName(
          positions: OpeningBook.replay([
            Move.parse('e2e4')!,
            Move.parse('c7c5')!,
          ]),
          fallback: 'Scacchi',
          book: Future.value(book),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Il codice ECO non compare nel titolo: tagliava il nome in inglese.
    expect(find.text('Difesa siciliana'), findsOneWidget);
    expect(find.textContaining('B20'), findsNothing);
    expect(
      find.bySemanticsLabel('Apertura: Difesa siciliana (B20)'),
      findsOneWidget,
    );
  });

  group('statistiche delle partite', () {
    testWidgets('RF-92 ogni mossa mostra partite e percentuali', (
      tester,
    ) async {
      await withStats(tester);
      expect(find.text('1.000'), findsOneWidget);
      expect(find.text('800'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('35%'), findsNWidgets(2));
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('e4.*1.000.*45%.*20%.*35%')),
        findsOneWidget,
      );
    });

    testWidgets('RF-92 il numero di partite è formattato per la lingua', (
      tester,
    ) async {
      final big = OpeningStats.parseTsv(
        'chiave\tmosse\n${keyAfter('')}\te4:925249:350000:300000\n',
      );
      await phone(
        tester,
        ExplorerPage(book: Future.value(book), stats: Future.value(big)),
      );
      expect(find.text('925.249'), findsOneWidget);
    });

    testWidgets('RF-92 si scende toccando una mossa con statistiche', (
      tester,
    ) async {
      await withStats(tester);
      await tester.tap(find.text('e4'));
      await tester.pumpAndSettle();
      expect(find.text('600'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('d4'), findsNothing);
      expect(find.text('1. e4'), findsOneWidget);
    });

    testWidgets('RF-92 il nome dell\'apertura raggiunta è sotto la mossa', (
      tester,
    ) async {
      await withStats(tester, moves: [Move.parse('e2e4')!]);
      expect(find.text('Difesa siciliana'), findsOneWidget);
    });

    testWidgets('RF-92 fuori dalle statistiche resta il libro', (tester) async {
      await withStats(
        tester,
        moves: [Move.parse('e2e4')!, Move.parse('c7c5')!],
      );
      expect(find.text('Fuori dal libro delle aperture'), findsOneWidget);
      await tester.tap(find.text('Indietro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Indietro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();
      expect(find.text('1. e4'), findsOneWidget);
    });

    testWidgets('RF-92 se le statistiche mancano si usa il libro', (
      tester,
    ) async {
      final failing = Future<OpeningStats>.error(StateError('x'))..ignore();
      await phone(
        tester,
        ExplorerPage(book: Future.value(book), stats: failing),
      );
      expect(find.text('e4'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Impossibile caricare le aperture.'), findsNothing);
    });

    testWidgets('RF-92 Avanti rifà le mosse tolte con Indietro', (
      tester,
    ) async {
      await withStats(tester);
      Future<void> tap(String label) async {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await tap('e4');
      await tap('e5');
      await tap('Indietro');
      await tap('Indietro');
      expect(find.text('1. e4'), findsNothing);
      await tap('Avanti');
      expect(find.text('1. e4'), findsOneWidget);
      await tap('Avanti');
      expect(find.text('1. e4 e5'), findsOneWidget);
    });

    testWidgets('RF-92 una mossa diversa azzera Avanti', (tester) async {
      await withStats(tester);
      await tester.tap(find.text('e4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Indietro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('d4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();
      expect(find.text('1. d4'), findsOneWidget);
    });

    testWidgets('RF-92 Ricomincia torna alla posizione iniziale', (
      tester,
    ) async {
      await withStats(tester, moves: [Move.parse('e2e4')!]);
      await tester.tap(find.text('Ricomincia'));
      await tester.pumpAndSettle();
      expect(opening(tester), 'Posizione iniziale');
      // Dopo Ricomincia si può tornare avanti con Avanti.
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();
      expect(find.text('1. e4'), findsOneWidget);
    });

    testWidgets('RF-92 Ruota scacchiera gira la scacchiera', (tester) async {
      await withStats(tester);
      expect(orientation(tester), Side.white);
      await tester.tap(find.text('Ruota scacchiera'));
      await tester.pumpAndSettle();
      expect(orientation(tester), Side.black);
    });

    testWidgets('RF-92 Indietro, Ricomincia e Avanti sono spenti quando '
        'non servono', (tester) async {
      await withStats(tester);
      bool enabled(String label) =>
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, label))
              .onPressed !=
          null;
      expect(enabled('Indietro'), isFalse);
      expect(enabled('Ricomincia'), isFalse);
      expect(enabled('Avanti'), isFalse);
      expect(enabled('Ruota scacchiera'), isTrue);
    });
  });
}
