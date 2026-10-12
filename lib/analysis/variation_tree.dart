import 'package:dartchess/dartchess.dart';

/// Posizione dell'albero: la mossa che ci arriva dal [parent] e le mosse che
/// seguono. Il primo figlio è la continuazione principale, gli altri sono
/// varianti.
class VariationNode {
  VariationNode._(this.parent, this.move, this.san, this.position);

  VariationNode._root(this.position) : parent = null, move = null, san = '';

  final VariationNode? parent;
  final Move? move;
  final String san;

  /// Posizione dopo [move].
  final Position position;
  final List<VariationNode> children = [];

  bool get isRoot => parent == null;
}

/// Albero delle varianti dell'analisi (RF-52): la linea principale e le
/// varianti esplorate, con una posizione corrente.
class VariationTree {
  VariationTree(Position initial) : root = VariationNode._root(initial) {
    current = root;
  }

  final VariationNode root;
  late VariationNode current;

  bool get canBack => !current.isRoot;
  bool get canForward => current.children.isNotEmpty;

  /// Gioca [move] dalla posizione corrente. Se la mossa c'è già tra i figli la
  /// seleziona, altrimenti la aggiunge come variante. `null` se è illegale.
  VariationNode? play(Move move) {
    final from = current.position;
    if (!from.isLegal(move)) return null;
    final existing = current.children.where((n) => n.move == move);
    if (existing.isNotEmpty) return current = existing.first;
    final (next, san) = from.makeSan(move);
    final node = VariationNode._(current, move, san, next);
    current.children.add(node);
    return current = node;
  }

  void back() {
    if (canBack) current = current.parent!;
  }

  void forward() {
    if (canForward) current = current.children.first;
  }

  void select(VariationNode node) => current = node;

  /// Vero se [node] sta sulla linea principale, cioè è sempre il primo figlio
  /// fino alla radice.
  bool isMainLine(VariationNode node) {
    for (var n = node; n.parent != null; n = n.parent!) {
      if (n.parent!.children.first != n) return false;
    }
    return true;
  }

  /// Mosse della linea principale, dalla prima.
  List<VariationNode> get mainLine {
    final out = <VariationNode>[];
    for (var n = root; n.children.isNotEmpty; n = n.children.first) {
      out.add(n.children.first);
    }
    return out;
  }

  /// Rende principale la linea che passa per [node], a ogni bivio fino alla
  /// radice.
  void promote(VariationNode node) {
    for (var n = node; n.parent != null; n = n.parent!) {
      final siblings = n.parent!.children;
      siblings
        ..remove(n)
        ..insert(0, n);
    }
  }

  /// Toglie [node] con tutto il seguito. Se la posizione corrente era lì
  /// sotto, si torna alla mossa precedente. La radice non si elimina.
  void delete(VariationNode node) {
    final parent = node.parent;
    if (parent == null) return;
    parent.children.remove(node);
    for (var n = current; ; n = n.parent!) {
      if (n == node) {
        current = parent;
        return;
      }
      if (n.parent == null) return;
    }
  }
}
