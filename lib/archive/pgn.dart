import 'package:dartchess/dartchess.dart';

import '../analysis/variation_tree.dart';
import '../game/chess_game.dart';
import '../game/move_note.dart';
import '../game/variant.dart';
import 'pgn_data.dart';
import 'tree_pgn.dart';

/// Partita letta da un PGN, con le sue intestazioni.
class PgnRecord {
  const PgnRecord(this.game, this.headers, {this.tree});

  final ChessGame game;
  final Map<String, String> headers;

  /// Albero con le varianti (RF-52), solo se il PGN ne ha; [game] ha la sola
  /// linea principale.
  final VariationTree? tree;

  /// Annota la mossa [ply] della linea principale, anche nell'albero.
  void annotate(int ply, MoveNote? note) {
    game.annotate(ply, note);
    tree?.mainLine[ply].note = note;
  }

  /// PGN del record com'è ora, con le varianti se ci sono.
  String toPgn() {
    final tree = this.tree;
    if (tree == null) return exportPgn(game, headers: headers);
    return exportTreePgn(
      tree,
      headers: {...headers, 'Result': resultTag(game)},
    );
  }
}

/// Esito di [importPgn]: partite valide e numero di partite scartate.
class PgnImport {
  const PgnImport(this.games, this.skipped);

  final List<PgnRecord> games;
  final int skipped;
}

String resultTag(ChessGame game) => switch (game.outcome) {
  null => '*',
  Outcome(winner: Side.white) => '1-0',
  Outcome(winner: Side.black) => '0-1',
  _ => '1/2-1/2',
};

/// PGN della linea principale di [game]; [headers] si aggiungono a quelle
/// standard o le sostituiscono.
String exportPgn(ChessGame game, {Map<String, String> headers = const {}}) {
  final pgnHeaders = {
    ...PgnGame.defaultHeaders(),
    ...headers,
    'Result': resultTag(game),
  };
  // Il nome della variante viene dalla partita, non da un PGN importato.
  pgnHeaders.remove('Variant');
  if (game.variant != Variant.standard) {
    pgnHeaders['Variant'] = game.variant.pgnName;
  }
  // Chess960 ha sempre bisogno della FEN: la posizione iniziale cambia.
  if (game.variant == Variant.chess960 ||
      game.initial.fen !=
          initialPosition(game.variant, chess960Id: standardChess960Id).fen) {
    pgnHeaders['FEN'] = game.initial.fen;
    pgnHeaders['SetUp'] = '1';
  }
  final root = PgnNode<PgnNodeData>();
  PgnNode<PgnNodeData> node = root;
  for (final m in game.moves) {
    final child = PgnChildNode(
      pgnNodeData(m.san, clock: m.clock, note: m.note),
    );
    node.children.add(child);
    node = child;
  }
  return PgnGame(
    headers: pgnHeaders,
    moves: root,
    comments: const [],
  ).makePgn();
}

/// Legge una o più partite; la partita ha la sola linea principale e le
/// varianti restano nell'albero del record, il tempo `[%clk]`, il
/// commento e il simbolo (`!`, `?`…) di ogni mossa si conservano, una partita con
/// mosse illegali, posizione non valida o variante non supportata viene
/// scartata.
PgnImport importPgn(String text) {
  if (text.trim().isEmpty) return const PgnImport([], 0);
  final games = <PgnRecord>[];
  var skipped = 0;
  for (final pgn in PgnGame.parseMultiGamePgn(text)) {
    final game = _replay(pgn);
    if (game == null) {
      skipped++;
    } else {
      final tree = treeFromPgnGame(pgn);
      games.add(
        PgnRecord(
          game,
          Map.unmodifiable(pgn.headers),
          tree: tree != null && tree.hasVariations ? tree : null,
        ),
      );
    }
  }
  return PgnImport(games, skipped);
}

ChessGame? _replay(PgnGame<PgnNodeData> pgn) {
  final variant = Variant.fromPgn(pgn.headers['Variant']);
  if (variant == null) return null;
  final Position initial;
  try {
    initial = PgnGame.startingPosition(pgn.headers);
  } on Exception {
    // FEN malformato o posizione non valida.
    return null;
  }
  final moves = <Move>[];
  final clocks = <Duration?>[];
  final notes = <MoveNote?>[];
  Position pos = initial;
  for (final data in pgn.moves.mainline()) {
    final move = pos.parseSan(data.san);
    if (move == null) return null;
    moves.add(move);
    clocks.add(pgnClock(data.comments));
    notes.add(pgnNote(data));
    pos = pos.play(move);
  }
  final game = ChessGame.replay(
    initial,
    moves,
    variant: variant,
    clocks: clocks,
    notes: notes,
  );
  if (game != null && !game.isOver) {
    // Il risultato senza matto o patta sulla scacchiera è un abbandono o
    // una patta concordata.
    switch (pgn.headers['Result']) {
      case '1-0':
        game.resign(Side.black);
      case '0-1':
        game.resign(Side.white);
      case '1/2-1/2':
        game.agreeDraw();
    }
  }
  return game;
}
