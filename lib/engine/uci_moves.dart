import 'package:dartchess/dartchess.dart';

/// UCI standard: l'arrocco di dartchess (re su torre) diventa e1g1/e1c1.
String standardUci(Position position, Move move) {
  final uci = move.uci;
  if (move is! NormalMove ||
      position.board.roleAt(move.from) != Role.king ||
      position.board.pieceAt(move.to)?.color != position.turn) {
    return uci;
  }
  final file = uci.codeUnitAt(2) > uci.codeUnitAt(0) ? 'g' : 'c';
  return '${uci.substring(0, 2)}$file${uci[3]}';
}

/// Mossa in UCI standard (e1g1 per l'arrocco) nel formato di dartchess.
Move moveFromStandardUci(Position position, String uci) =>
    position.normalizeMove(NormalMove.fromUci(uci));
