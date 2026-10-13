import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/analysis/analysis_page.dart';
import 'package:scacchi/analysis/variation_tree.dart';
import 'package:scacchi/archive/saved_game.dart';

import '../localized_app.dart';
import 'analysis_page_test.dart' show FakeLive;

Chessboard board(WidgetTester tester) =>
    tester.widget<Chessboard>(find.byType(Chessboard));

Future<void> move(WidgetTester tester, String uci) async {
  board(tester).onMove!(NormalMove.fromUci(uci));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> pump(
  WidgetTester tester, {
  VariationTree? tree,
  SavedGame? saved,
  Future<void> Function(SavedGame)? onSave,
  Future<void> Function(String)? share,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    localizedApp(
      home: AnalysisPage(
        initial: tree?.root.position ?? Chess.initial,
        analyse: FakeLive().call,
        tree: tree,
        saved: saved,
        onSave: onSave ?? (_) async {},
        share: share,
      ),
    ),
  );
  await tester.pump();
}

Future<void> menu(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip('Altre azioni'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

void main() {
  group('RF-52 analisi salvata e condivisa', () {
    testWidgets('salva l\'analisi con le varianti e il nome scelto', (
      tester,
    ) async {
      final saved = <SavedGame>[];
      await pump(tester, onSave: (g) async => saved.add(g));
      await move(tester, 'e2e4');
      await move(tester, 'e7e5');
      await tester.tap(find.byTooltip('Indietro'));
      await tester.pump(const Duration(milliseconds: 300));
      await move(tester, 'c7c5');

      await menu(tester, 'Salva nell\'archivio');
      expect(find.text('Nome dell\'analisi'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Siciliana');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      expect(saved.single.title, 'Siciliana');
      expect(saved.single.mode, SavedGame.analysis);
      expect(saved.single.pgn, contains('( 1... c5 )'));
      expect(find.text('Analisi salvata nell\'archivio'), findsOneWidget);
    });

    testWidgets('un secondo salvataggio aggiorna la stessa analisi', (
      tester,
    ) async {
      final saved = <SavedGame>[];
      await pump(tester, onSave: (g) async => saved.add(g));
      await move(tester, 'e2e4');
      await menu(tester, 'Salva nell\'archivio');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      await move(tester, 'e7e5');
      await menu(tester, 'Salva nell\'archivio');
      expect(find.text('Nome dell\'analisi'), findsNothing);
      expect(saved, hasLength(2));
      expect(saved.last.id, saved.first.id);
      expect(saved.last.title, saved.first.title);
      expect(saved.last.pgn, contains('e5'));
    });

    testWidgets('riaperta dall\'archivio mostra le varianti salvate', (
      tester,
    ) async {
      final tree = VariationTree(Chess.initial)
        ..play(Move.parse('e2e4')!)
        ..play(Move.parse('e7e5')!)
        ..back()
        ..play(Move.parse('c7c5')!);
      final saved = SavedGame.fromTree(
        tree,
        id: 'a1',
        name: 'Aperture',
        createdAt: DateTime(2026, 10, 13),
        updatedAt: DateTime(2026, 10, 13),
      );
      final again = <SavedGame>[];
      await pump(
        tester,
        tree: saved.toTree(),
        saved: saved,
        onSave: (g) async => again.add(g),
      );
      expect(find.text('1. e4'), findsOneWidget);
      expect(find.text('1… c5'), findsOneWidget);
      await menu(tester, 'Salva nell\'archivio');
      expect(again.single.id, 'a1');
      expect(again.single.title, 'Aperture');
    });

    testWidgets('condivide il PGN con le varianti', (tester) async {
      final shared = <String>[];
      await pump(tester, share: (t) async => shared.add(t));
      await move(tester, 'd2d4');
      await tester.tap(find.byTooltip('Indietro'));
      await tester.pump(const Duration(milliseconds: 300));
      await move(tester, 'c2c4');
      await menu(tester, 'Condividi il PGN');
      expect(shared.single, contains('1. d4 ( 1. c4 )'));
    });
  });
}
