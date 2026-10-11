import 'package:dartchess/dartchess.dart';

import '../settings/notation.dart';
import 'chess_game.dart';

/// Mossa in notazione SAN numerata secondo la posizione iniziale della partita;
/// il numero accompagna sempre il Bianco, il Nero solo se [number].
/// [notation] sceglie come si scrivono i pezzi.
String moveLabel(
  ChessGame game,
  int ply, {
  bool number = false,
  required MoveNotation notation,
}) {
  final start = game.initial;
  final abs =
      (start.fullmoves - 1) * 2 + (start.turn == Side.black ? 1 : 0) + ply;
  final n = abs ~/ 2 + 1;
  final san = formatSan(game.moves[ply].san, notation);
  if (abs.isEven) return '$n. $san';
  return number || ply == 0 ? '$n... $san' : san;
}
