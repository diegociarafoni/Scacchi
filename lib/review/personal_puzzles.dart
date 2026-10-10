import 'package:dartchess/dartchess.dart';

import 'board_utils.dart';
import 'coach.dart';
import 'game_review.dart';
import 'move_classification.dart';

/// Puzzle ricavato da un errore del giocatore, nel formato dei puzzle Lichess:
/// [fen] è la posizione prima della mossa dell'avversario, la prima di
/// [moves] è quella mossa e le successive sono la soluzione.
class MistakePuzzle {
  const MistakePuzzle({
    required this.id,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.themes,
    required this.explanation,
  });

  final String id;
  final String fen;
  final List<Move> moves;
  final int rating;
  final Set<String> themes;

  /// Spiegazione del coach dell'errore originale, da mostrare dopo.
  final String? explanation;

  /// Riga `id,fen,mosse uci,punteggio,temi` del database Lichess, con
  /// l'arrocco nella forma standard (e1g1).
  String toCsv() {
    Position pos = Chess.fromSetup(Setup.parseFen(fen));
    final uci = <String>[];
    for (final m in moves) {
      uci.add(m is NormalMove ? _standardUci(pos, m) : m.uci);
      pos = pos.play(m);
    }
    return '$id,$fen,${uci.join(' ')},$rating,${themes.join(' ')}';
  }
}

const _trainable = {MoveClass.mistake, MoveClass.blunder, MoveClass.miss};

/// Puzzle dagli errori, errori gravi e occasioni mancate dei lati in
/// [players]. La soluzione è la variante del motore, al massimo tre mosse
/// del giocatore (o tutto il matto fino a matto in 3), e finisce sempre
/// con una mossa del giocatore.
List<MistakePuzzle> puzzlesFromReview(
  GameReview review, {
  required Set<Side> players,
  required String gameId,
}) {
  final puzzles = <MistakePuzzle>[];
  for (final m in review.moves) {
    if (m.ply == 0 || !players.contains(m.side)) continue;
    if (!_trainable.contains(m.classification)) continue;
    final previous = review.moves[m.ply - 1];
    final start = Chess.fromSetup(Setup.parseFen(m.fenBefore));
    final mate = m.bestScore?.mate;
    final mateIn = mate != null && mate > 0 && mate <= 3 ? mate : null;
    final solution = _solution(
      start,
      m.bestLine,
      maxPlies: mateIn != null ? 2 * mateIn - 1 : 5,
    );
    if (solution.isEmpty) continue;

    final comment = explainMove(m, previous: previous);
    final playerMoves = (solution.length + 1) ~/ 2;
    puzzles.add(
      MistakePuzzle(
        id: 'mio-$gameId-${m.ply}',
        fen: previous.fenBefore,
        moves: [previous.move, ...solution],
        rating: mateIn != null ? 800 + 300 * mateIn : 900 + 200 * playerMoves,
        themes: {
          ...?_themes[comment?.theme],
          if (mateIn != null) 'mateIn$mateIn',
          _phase(start),
        },
        explanation: comment?.text,
      ),
    );
  }
  return puzzles;
}

/// Mosse legali della variante, troncate a un numero dispari di semimosse.
List<Move> _solution(
  Position start,
  List<String> line, {
  required int maxPlies,
}) {
  final moves = <Move>[];
  var pos = start;
  for (final uci in line.take(maxPlies)) {
    final move = parseEngineMove(pos, uci);
    if (move == null) break;
    moves.add(move);
    pos = pos.play(move);
  }
  if (moves.length.isEven && moves.isNotEmpty) moves.removeLast();
  return moves;
}

const _themes = {
  CoachTheme.allowedMate: {'defensiveMove'},
  CoachTheme.hangingPiece: {'defensiveMove'},
  CoachTheme.allowedFork: {'defensiveMove'},
  CoachTheme.materialLoss: {'defensiveMove'},
  CoachTheme.missedCapture: {'hangingPiece'},
  CoachTheme.missedFork: {'fork'},
  CoachTheme.missedDiscovery: {'discoveredAttack'},
};

/// Fase della partita con i nomi dei temi Lichess.
String _phase(Position pos) {
  if (pos.fullmoves <= 10) return 'opening';
  final pieces =
      pos.board.occupied.size - pos.board.pawns.size - pos.board.kings.size;
  return pieces <= 4 ? 'endgame' : 'middlegame';
}

String _standardUci(Position pos, NormalMove move) {
  if (!isCastling(pos, move)) return move.uci;
  final file = move.to.file > move.from.file ? File.g : File.c;
  return NormalMove(
    from: move.from,
    to: Square.fromCoords(file, move.from.rank),
  ).uci;
}
