import 'package:dartchess/dartchess.dart';

enum GamePhase {
  opening('Apertura'),
  middlegame('Mediogioco'),
  endgame('Finale');

  const GamePhase(this.label);

  final String label;
}

/// Fase della posizione: apertura fino alla decima mossa, finale con al
/// massimo quattro pezzi oltre a re e pedoni, altrimenti mediogioco.
GamePhase phaseOf(Position pos) {
  if (pos.fullmoves <= 10) return GamePhase.opening;
  final pieces =
      pos.board.occupied.size - pos.board.pawns.size - pos.board.kings.size;
  return pieces <= 4 ? GamePhase.endgame : GamePhase.middlegame;
}

GamePhase phaseOfFen(String fen) =>
    phaseOf(Chess.fromSetup(Setup.parseFen(fen)));
