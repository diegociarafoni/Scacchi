import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/analysis/analysis_page.dart';
import 'package:scacchi/analysis/variation_tree.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/game/move_note.dart';

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
      ),
    ),
  );
  await tester.pump();
}

Future<void> addNote(
  WidgetTester tester, {
  String? symbol,
  String? comment,
}) async {
  await tester.tap(find.byTooltip('Aggiungi nota'));
  await tester.pumpAndSettle();
  if (symbol != null) await tester.tap(find.text(symbol));
  if (comment != null) await tester.enterText(find.byType(TextField), comment);
  await tester.tap(find.text('Salva'));
  await tester.pumpAndSettle();
}

void main() {
  group('RF-55 note nell\'analisi', () {
    testWidgets('sulla posizione iniziale non c\'è nessuna mossa da annotare', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byTooltip('Aggiungi nota'), findsNothing);
    });

    testWidgets('simbolo e commento compaiono sulla mossa', (tester) async {
      await pump(tester);
      await move(tester, 'e2e4');
      await addNote(tester, symbol: '!', comment: 'Centro');
      expect(find.text('1. e4!'), findsOneWidget);
      expect(find.textContaining('Centro'), findsOneWidget);
      expect(find.byTooltip('Modifica nota'), findsOneWidget);
    });

    testWidgets('si annota anche una variante', (tester) async {
      await pump(tester);
      await move(tester, 'e2e4');
      await move(tester, 'e7e5');
      await tester.tap(find.byTooltip('Indietro'));
      await tester.pump(const Duration(milliseconds: 300));
      await move(tester, 'c7c5');
      await addNote(tester, symbol: '!?');
      expect(find.text('1… c5!?'), findsOneWidget);
      expect(find.text('e5'), findsOneWidget);
    });

    testWidgets('una nota vuota toglie quella esistente', (tester) async {
      await pump(tester);
      await move(tester, 'e2e4');
      await addNote(tester, symbol: '?', comment: 'No');
      await tester.tap(find.byTooltip('Modifica nota'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('?'));
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(find.text('1. e4'), findsOneWidget);
      expect(find.byTooltip('Aggiungi nota'), findsOneWidget);
    });

    testWidgets('le note finiscono nel PGN salvato', (tester) async {
      final saved = <SavedGame>[];
      await pump(tester, onSave: (g) async => saved.add(g));
      await move(tester, 'e2e4');
      await addNote(tester, symbol: '!!', comment: 'Bella');
      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva nell\'archivio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(saved.single.pgn, contains('1. e4 \$3 { Bella }'));
    });
  });

  group('RF-55 annotare dall\'archivio', () {
    SavedGame played() {
      final game = ChessGame()
        ..play(Move.parse('e2e4')!)
        ..play(Move.parse('e7e5')!);
      return SavedGame.fromGame(
        game,
        id: 'p1',
        white: 'Anna',
        black: 'Bruno',
        mode: SavedGame.local,
        createdAt: DateTime(2026, 10, 10),
        updatedAt: DateTime(2026, 10, 10),
      );
    }

    testWidgets('salvando si aggiorna la partita con i suoi dati', (
      tester,
    ) async {
      final game = played();
      final saved = <SavedGame>[];
      await pump(
        tester,
        tree: game.toTree(),
        saved: game,
        onSave: (g) async => saved.add(g),
      );
      await tester.tap(find.text('1. e4'));
      await tester.pump(const Duration(milliseconds: 300));
      await addNote(tester, comment: 'Apertura del re');
      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva nell\'archivio'));
      await tester.pumpAndSettle();
      expect(find.text('Nome dell\'analisi'), findsNothing);
      expect(saved.single.id, 'p1');
      expect(saved.single.mode, SavedGame.local);
      expect(saved.single.white, 'Anna');
      expect(saved.single.pgn, contains('[White "Anna"]'));
      expect(saved.single.pgn, contains('1. e4 { Apertura del re } e5'));
    });
  });

  test('RF-55 withTree conserva intestazioni e tipo della voce', () {
    final game = ChessGame()..play(Move.parse('d2d4')!);
    final saved = SavedGame.fromGame(
      game,
      id: 'x',
      white: 'Carla',
      black: 'Dario',
      mode: SavedGame.imported,
      createdAt: DateTime(2026, 10, 10),
      updatedAt: DateTime(2026, 10, 10),
    );
    final tree = saved.toTree()!;
    tree.root.children.single.note = MoveNote.of(symbol: MoveSymbol.good);
    final later = DateTime(2026, 10, 13);
    final back = saved.withTree(tree, updatedAt: later);
    expect(back.updatedAt, later);
    expect(back.mode, SavedGame.imported);
    expect(back.pgn, contains('[Black "Dario"]'));
    expect(back.pgn, contains('1. d4 \$1'));
  });

  test(
    'RF-55 cambiando la linea principale precisione e apertura si azzerano',
    () {
      final game = ChessGame()
        ..play(Move.parse('e2e4')!)
        ..play(Move.parse('e7e5')!);
      final saved = SavedGame.fromGame(
        game,
        id: 'y',
        white: 'A',
        black: 'B',
        mode: SavedGame.local,
        createdAt: DateTime(2026, 10, 10),
        updatedAt: DateTime(2026, 10, 10),
      ).copyWith(accuracy: () => 85, opening: () => 'Partita aperta');
      final same = saved.toTree()!;
      expect(saved.withTree(same).accuracy, 85);
      final other = saved.toTree()!;
      other
        ..select(other.root.children.single)
        ..play(Move.parse('c7c5')!)
        ..promote(other.current);
      final changed = saved.withTree(other);
      expect(changed.accuracy, isNull);
      expect(changed.opening, isNull);
    },
  );
}
