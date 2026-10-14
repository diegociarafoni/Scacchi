import 'package:dartchess/dartchess.dart';

import '../analysis/variation_tree.dart';
import '../game/variant.dart';
import 'pgn_data.dart';

/// PGN dell'albero di [tree] con le varianti tra parentesi (RF-52); [headers]
/// si aggiungono a quelle standard o le sostituiscono. Note e tempi (RF-55,
/// RF-67) di ogni mossa si conservano.
String exportTreePgn(
  VariationTree tree, {
  Map<String, String> headers = const {},
}) {
  final pgnHeaders = {...PgnGame.defaultHeaders(), ...headers};
  pgnHeaders.remove('Variant');
  final start = tree.root.position.fen;
  if (start != Chess.initial.fen) {
    pgnHeaders['FEN'] = start;
    pgnHeaders['SetUp'] = '1';
  } else {
    pgnHeaders.remove('FEN');
    pgnHeaders.remove('SetUp');
  }
  final root = PgnNode<PgnNodeData>();
  final pending = [(tree.root, root)];
  while (pending.isNotEmpty) {
    final (from, into) = pending.removeLast();
    for (final child in from.children) {
      final out = PgnChildNode(
        pgnNodeData(child.san, clock: child.clock, note: child.note),
      );
      into.children.add(out);
      pending.add((child, out));
    }
  }
  return PgnGame(
    headers: pgnHeaders,
    moves: root,
    comments: const [],
  ).makePgn();
}

/// Albero della prima partita di [text]. `null` se il PGN è vuoto, non è
/// scacchi classici, la posizione non è valida o la linea principale ha una
/// mossa illegale; una variante illegale si scarta dal punto in cui lo è.
VariationTree? treeFromPgn(String text) {
  if (text.trim().isEmpty) return null;
  final games = PgnGame.parseMultiGamePgn(text);
  return games.isEmpty ? null : treeFromPgnGame(games.first);
}

/// Come [treeFromPgn], da una partita già letta.
VariationTree? treeFromPgnGame(PgnGame<PgnNodeData> pgn) {
  if (Variant.fromPgn(pgn.headers['Variant']) != Variant.standard) return null;
  final Position initial;
  try {
    initial = PgnGame.startingPosition(pgn.headers);
  } on Exception {
    return null;
  }
  if (initial is! Chess) return null;
  final tree = VariationTree(initial);
  // In ampiezza, così la continuazione principale entra nell'albero prima
  // delle varianti che ripetono la sua mossa.
  final queue = [(tree.root, pgn.moves, true)];
  for (var i = 0; i < queue.length; i++) {
    final (at, source, onMain) = queue[i];
    for (final (index, child) in source.children.indexed) {
      final isMain = onMain && index == 0;
      final move = at.position.parseSan(child.data.san);
      final node = move == null ? null : tree.add(at, move);
      if (node == null) {
        // Una linea principale interrotta da una mossa illegale non è la
        // partita; una variante si scarta da lì.
        if (isMain) return null;
        continue;
      }
      node.note ??= pgnNote(child.data);
      node.clock ??= pgnClock(child.data.comments);
      queue.add((node, child, isMain));
    }
  }
  return tree;
}
