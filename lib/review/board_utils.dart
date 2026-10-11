import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';

/// Mossa UCI del motore resa legale per dartchess (arrocco come re su torre);
/// `null` se illeggibile o illegale in [pos].
Move? parseEngineMove(Position pos, String? uci) {
  final m = uci == null ? null : Move.parse(uci);
  if (m == null) return null;
  final move = m is NormalMove ? pos.normalizeMove(m) : m;
  return pos.isLegal(move) ? move : null;
}

/// Vero se [side], al tratto in [pos], può catturare legalmente su [square].
bool canCapture(Position pos, Square square, Side side) =>
    pos.turn == side &&
    pos.board
        .attacksTo(square, side)
        .squares
        .any((from) => pos.isLegal(NormalMove(from: from, to: square)));

/// Vero se [move] è un arrocco (re che va sulla propria torre).
bool isCastling(Position pos, NormalMove move) {
  final piece = pos.board.pieceAt(move.from);
  final target = pos.board.pieceAt(move.to);
  return piece?.role == Role.king &&
      target?.role == Role.rook &&
      target?.color == piece?.color;
}

/// Mossa come la vede il giocatore: l'arrocco va sulla casa del re (g/c),
/// non su quella della torre come lo rappresenta dartchess.
NormalMove kingDestination(Position pos, NormalMove move) {
  if (!isCastling(pos, move)) return move;
  final file = move.to.file > move.from.file ? File.g : File.c;
  return NormalMove(
    from: move.from,
    to: Square.fromCoords(file, move.from.rank),
  );
}

/// Numero della mossa che parte da [before]: `3.` per il Bianco, `3…` per il
/// Nero.
String moveNumber(Position before) =>
    before.turn == Side.white ? '${before.fullmoves}.' : '${before.fullmoves}…';

/// Stato per la scacchiera di chessground: [interactive] lascia muovere il
/// lato al tratto.
GameData gameDataFor(
  Position pos, {
  Move? lastMove,
  bool interactive = false,
}) => GameData(
  fen: pos.fen,
  lastMove: lastMove,
  playerSide: !interactive
      ? PlayerSide.none
      : (pos.turn == Side.white ? PlayerSide.white : PlayerSide.black),
  sideToMove: pos.turn,
  kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
  validMoves: interactive ? makeLegalMoves(pos) : const {},
);
