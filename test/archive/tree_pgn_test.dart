import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/analysis/variation_tree.dart';
import 'package:scacchi/archive/tree_pgn.dart';
import 'package:scacchi/game/move_note.dart';

Move m(String uci) => Move.parse(uci)!;

VariationTree sample() {
  final tree = VariationTree(Chess.initial)
    ..play(m('e2e4'))
    ..play(m('e7e5'))
    ..play(m('g1f3'))
    ..back()
    ..play(m('f2f4'))
    ..back()
    ..back()
    ..play(m('c7c5'));
  return tree;
}

void main() {
  group('RF-52 varianti in PGN', () {
    test('l\'esportazione scrive le varianti tra parentesi', () {
      final pgn = exportTreePgn(sample());
      expect(pgn, contains('1. e4 e5 ( 1... c5 )'));
      expect(pgn, contains('2. Nf3 ( 2. f4 )'));
    });

    test('le varianti annidate si riconoscono', () {
      final tree = VariationTree(Chess.initial)
        ..play(m('e2e4'))
        ..play(m('e7e5'))
        ..back()
        ..play(m('c7c5'))
        ..play(m('g1f3'))
        ..back()
        ..play(m('b1c3'));
      final back = treeFromPgn(exportTreePgn(tree))!;
      final c5 = back.root.children.first.children[1];
      expect(c5.san, 'c5');
      expect([for (final n in c5.children) n.san], ['Nf3', 'Nc3']);
    });

    test('esportare e reimportare dà lo stesso albero', () {
      final tree = sample();
      final back = treeFromPgn(exportTreePgn(tree))!;
      expect(exportTreePgn(back), exportTreePgn(tree));
      expect(back.hasVariations, isTrue);
      expect([for (final n in back.mainLine) n.san], ['e4', 'e5', 'Nf3']);
    });

    test('senza varianti l\'albero non ne ha', () {
      final tree = VariationTree(Chess.initial)..play(m('d2d4'));
      expect(tree.hasVariations, isFalse);
      expect(treeFromPgn(exportTreePgn(tree))!.hasVariations, isFalse);
    });

    test('la posizione di partenza non standard va nella FEN', () {
      const fen = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
      final tree = VariationTree(Chess.fromSetup(Setup.parseFen(fen)))
        ..play(m('e2e4'))
        ..back()
        ..play(m('e2e3'));
      final pgn = exportTreePgn(tree);
      expect(pgn, contains('[FEN "$fen"]'));
      expect(pgn, contains('[SetUp "1"]'));
      final back = treeFromPgn(pgn)!;
      expect(back.root.position.fen, tree.root.position.fen);
      expect(back.root.children.map((n) => n.san), ['e4', 'e3']);
    });

    test('le intestazioni date si aggiungono alle standard', () {
      final pgn = exportTreePgn(
        VariationTree(Chess.initial)..play(m('e2e4')),
        headers: {'Event': 'Difesa siciliana'},
      );
      expect(pgn, contains('[Event "Difesa siciliana"]'));
      expect(pgn, contains('[Result "*"]'));
    });

    test('RF-55 note e tempo di ogni mossa e variante si conservano', () {
      final tree = sample();
      final e4 = tree.root.children.single;
      e4.note = MoveNote.of(symbol: MoveSymbol.good, comment: 'Centro');
      e4.clock = const Duration(minutes: 4, seconds: 59);
      tree.root.children.single.children[1].note = MoveNote.of(
        comment: 'Siciliana',
        symbol: MoveSymbol.interesting,
      );
      final back = treeFromPgn(exportTreePgn(tree))!;
      final e4b = back.root.children.single;
      expect(e4b.note, MoveNote.of(symbol: MoveSymbol.good, comment: 'Centro'));
      expect(e4b.clock, const Duration(minutes: 4, seconds: 59));
      expect(
        e4b.children[1].note,
        MoveNote.of(comment: 'Siciliana', symbol: MoveSymbol.interesting),
      );
    });

    test(
      'una variante con una mossa illegale si scarta dal punto illegale',
      () {
        const pgn = '1. e4 e5 (1... c5 2. Ke3 Nc6) (1... e6 2. d4) 2. Nf3 *';
        final tree = treeFromPgn(pgn)!;
        final e4 = tree.root.children.single;
        expect([for (final n in e4.children) n.san], ['e5', 'c5', 'e6']);
        expect(e4.children[1].children, isEmpty);
        expect(e4.children[2].children.single.san, 'd4');
      },
    );

    test(
      'una mossa illegale sulla linea principale rende il PGN inutilizzabile',
      () {
        expect(treeFromPgn('1. e4 e5 2. Ke3 *'), isNull);
      },
    );

    test('una variante che ripete una mossa già presente si fonde', () {
      final tree = treeFromPgn('1. e4 e5 (1... e5 2. Nf3) 2. Nc3 *')!;
      final e5 = tree.root.children.single.children.single;
      expect([for (final n in e5.children) n.san], ['Nc3', 'Nf3']);
    });

    test('le varianti di gioco non standard non diventano un albero', () {
      expect(treeFromPgn('[Variant "Chess960"]\n\n1. e4 *'), isNull);
    });

    test('un testo vuoto non è un albero', () {
      expect(treeFromPgn(''), isNull);
    });
  });
}
