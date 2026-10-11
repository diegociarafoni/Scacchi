import 'package:dartchess/dartchess.dart';

import '../puzzles/puzzle.dart';
import 'board_utils.dart';
import 'coach.dart';
import 'game_review.dart';
import 'move_classification.dart';
import 'win_probability.dart';

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

  /// Il puzzle nel modello del modulo puzzle, con l'arrocco standard.
  Puzzle toPuzzle() => Puzzle.parseCsv(toCsv());

  /// Riga `id,fen,mosse uci,punteggio,temi` del database Lichess, con
  /// l'arrocco nella forma standard (e1g1).
  String toCsv() {
    Position pos = Chess.fromSetup(Setup.parseFen(fen));
    final uci = <String>[];
    for (final m in moves) {
      uci.add(m is NormalMove ? kingDestination(pos, m).uci : m.uci);
      pos = pos.play(m);
    }
    return '$id,$fen,${uci.join(' ')},$rating,${themes.join(' ')}';
  }
}

const _trainable = {MoveClass.mistake, MoveClass.blunder, MoveClass.miss};

/// Puzzle dagli errori, errori gravi e occasioni mancate dei lati in
/// [players]. La soluzione è la variante del motore, al massimo tre mosse
/// del giocatore (o tutto il matto fino a matto in 5), e finisce sempre
/// con una mossa del giocatore. Si salta l'errore se la seconda scelta del
/// motore vale quasi quanto la prima: il puzzle avrebbe più soluzioni.
/// Gli errori alla prima semimossa non diventano puzzle: manca la mossa
/// dell'avversario richiesta dal formato Lichess.
List<MistakePuzzle> puzzlesFromReview(
  GameReview review, {
  required Set<Side> players,
  required String gameId,
}) {
  final puzzles = <MistakePuzzle>[];
  for (final m in review.moves) {
    if (m.ply == 0 || !players.contains(m.side)) continue;
    if (!_trainable.contains(m.classification)) continue;
    if (!_uniqueBest(m)) continue;
    final previous = review.moves[m.ply - 1];
    final start = Chess.fromSetup(Setup.parseFen(m.fenBefore));
    final mate = m.bestScore?.mate;
    final announced = mate != null && mate > 0 && mate <= 5 ? mate : null;
    final solution = _solution(
      start,
      m.bestLine,
      maxPlies: announced != null ? 2 * announced - 1 : 5,
    );
    if (solution.isEmpty) continue;
    // Tema del matto solo se la soluzione ci arriva davvero.
    final mateIn =
        announced != null &&
            solution.length == 2 * announced - 1 &&
            solution.fold<Position>(start, (p, mv) => p.play(mv)).isCheckmate
        ? announced
        : null;

    final comment = explainMove(m, previous: previous);
    final playerMoves = (solution.length + 1) ~/ 2;
    puzzles.add(
      MistakePuzzle(
        id: 'mio-${gameId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}-${m.ply}',
        fen: previous.fenBefore,
        moves: [previous.move, ...solution],
        rating: mateIn != null ? 800 + 300 * mateIn : 900 + 200 * playerMoves,
        themes: {
          if (mateIn != null) 'mateIn$mateIn' else ...?_themes[comment?.theme],
          _phase(start),
        },
        explanation: comment?.text,
      ),
    );
  }
  return puzzles;
}

/// La migliore supera la seconda scelta di almeno 10 punti di probabilità.
bool _uniqueBest(MoveReview m) {
  final best = m.bestScore;
  final second = m.secondBestScore;
  if (best == null || second == null) return true;
  return winPercent(best) - winPercent(second) >= 10;
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
  CoachTheme.allowedPin: {'defensiveMove', 'pin'},
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

/// Identificativo stabile di una partita per i puzzle: lo stesso valore a ogni
/// avvio e su ogni piattaforma, a differenza di `hashCode`. È FNV-1a a 32 bit;
/// la moltiplicazione è scritta con somme di scorrimenti per non superare la
/// precisione dei numeri sul web.
String gameIdOf(String key) {
  const mask = 0xffffffff;
  var h = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    h ^= unit;
    h = (h + (h << 1) + (h << 4) + (h << 7) + (h << 8) + (h << 24)) & mask;
  }
  return h.toRadixString(36);
}
