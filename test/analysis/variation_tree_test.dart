import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/analysis/variation_tree.dart';

Move m(String uci) => Move.parse(uci)!;

void main() {
  group('RF-52 albero delle varianti', () {
    test('parte dalla posizione iniziale senza mosse', () {
      final tree = VariationTree(Chess.initial);
      expect(tree.current, same(tree.root));
      expect(tree.current.position.fen, Chess.initial.fen);
      expect(tree.canBack, isFalse);
      expect(tree.canForward, isFalse);
    });

    test('giocare una mossa legale la aggiunge e la seleziona', () {
      final tree = VariationTree(Chess.initial);
      final node = tree.play(m('e2e4'));
      expect(node, isNotNull);
      expect(tree.current, same(node));
      expect(node!.san, 'e4');
      expect(node.parent, same(tree.root));
      expect(tree.root.children, [node]);
    });

    test('una mossa illegale viene ignorata', () {
      final tree = VariationTree(Chess.initial);
      expect(tree.play(m('e2e5')), isNull);
      expect(tree.current, same(tree.root));
      expect(tree.root.children, isEmpty);
    });

    test('indietro e avanti seguono la linea principale', () {
      final tree = VariationTree(Chess.initial)
        ..play(m('e2e4'))
        ..play(m('e7e5'));
      tree.back();
      expect(tree.current.san, 'e4');
      tree.forward();
      expect(tree.current.san, 'e5');
      expect(tree.canForward, isFalse);
    });

    test('una mossa diversa da una posizione precedente crea una variante', () {
      final tree = VariationTree(Chess.initial)
        ..play(m('e2e4'))
        ..play(m('e7e5'))
        ..back()
        ..play(m('c7c5'));
      final e4 = tree.root.children.single;
      expect(e4.children.map((n) => n.san), ['e5', 'c5']);
      expect(tree.current.san, 'c5');
      expect(tree.isMainLine(tree.current), isFalse);
      expect(tree.isMainLine(e4.children.first), isTrue);
    });

    test('rigiocare una mossa già presente non duplica il ramo', () {
      final tree = VariationTree(Chess.initial)
        ..play(m('e2e4'))
        ..play(m('e7e5'))
        ..back();
      final again = tree.play(m('e7e5'));
      expect(tree.root.children.single.children, hasLength(1));
      expect(tree.current, same(again));
    });

    test('avanti dopo un ritorno segue la prima variante', () {
      final tree = VariationTree(Chess.initial)
        ..play(m('e2e4'))
        ..play(m('e7e5'))
        ..back()
        ..play(m('c7c5'))
        ..back()
        ..back();
      tree.forward();
      tree.forward();
      expect(tree.current.san, 'e5');
    });

    test('promuovere una variante la porta a linea principale', () {
      final tree = VariationTree(Chess.initial)
        ..play(m('e2e4'))
        ..play(m('e7e5'))
        ..back()
        ..play(m('c7c5'))
        ..play(m('g1f3'));
      tree.promote(tree.current);
      final e4 = tree.root.children.single;
      expect(e4.children.map((n) => n.san), ['c5', 'e5']);
      expect(tree.isMainLine(tree.current), isTrue);
      expect(tree.mainLine.map((n) => n.san), ['e4', 'c5', 'Nf3']);
    });

    test('promuovere la linea principale non cambia nulla', () {
      final tree = VariationTree(Chess.initial)
        ..play(m('e2e4'))
        ..play(m('e7e5'));
      tree.promote(tree.current);
      expect(tree.mainLine.map((n) => n.san), ['e4', 'e5']);
    });

    test('eliminare una variante toglie il ramo e torna alla mossa prima', () {
      final tree = VariationTree(Chess.initial)
        ..play(m('e2e4'))
        ..play(m('e7e5'))
        ..back()
        ..play(m('c7c5'))
        ..play(m('g1f3'));
      final c5 = tree.current.parent!;
      tree.delete(c5);
      expect(tree.root.children.single.children.map((n) => n.san), ['e5']);
      expect(tree.current.san, 'e4');
    });

    test('eliminare una mossa fuori dal ramo corrente lascia la posizione', () {
      final tree = VariationTree(Chess.initial)
        ..play(m('e2e4'))
        ..play(m('e7e5'))
        ..back()
        ..play(m('c7c5'));
      final e5 = tree.root.children.single.children.first;
      tree.delete(e5);
      expect(tree.current.san, 'c5');
    });

    test('la radice non si elimina', () {
      final tree = VariationTree(Chess.initial)..play(m('e2e4'));
      tree.delete(tree.root);
      expect(tree.root.children, hasLength(1));
    });

    test('select porta in una posizione qualsiasi dell\'albero', () {
      final tree = VariationTree(Chess.initial)
        ..play(m('e2e4'))
        ..play(m('e7e5'));
      final e4 = tree.root.children.single;
      tree.select(e4);
      expect(tree.current, same(e4));
    });
  });
}
