import 'package:dartchess/dartchess.dart';

import 'chess_game.dart';

/// Mossa in notazione SAN numerata secondo la posizione iniziale della partita;
/// il numero accompagna sempre il Bianco, il Nero solo se [number].
String moveLabel(ChessGame game, int ply, {bool number = false}) {
  final start = game.initial;
  final abs =
      (start.fullmoves - 1) * 2 + (start.turn == Side.black ? 1 : 0) + ply;
  final n = abs ~/ 2 + 1;
  final san = game.moves[ply].san;
  if (abs.isEven) return '$n. $san';
  return number || ply == 0 ? '$n... $san' : san;
}
