import 'package:dartchess/dartchess.dart';

const _names = {
  Role.pawn: ('il pedone', 'un pedone'),
  Role.knight: ('il cavallo', 'un cavallo'),
  Role.bishop: ('l\'alfiere', 'un alfiere'),
  Role.rook: ('la torre', 'una torre'),
  Role.queen: ('la donna', 'una donna'),
  Role.king: ('il re', 'il re'),
};

String _the(Role r) => _names[r]!.$1;

/// Primo livello del suggerimento: solo il pezzo da muovere.
String describeHintPiece(Position pos, Square from) {
  final piece = pos.board.pieceAt(from);
  return piece == null ? 'Muovi un pezzo.' : 'Muovi ${_the(piece.role)}.';
}

/// Secondo livello: la mossa a parole semplici, senza notazione, con il
/// motivo quando si riconosce (scacco da parare, cattura, scacco dato).
String describeHintMove(Position pos, Move move) {
  if (move is! NormalMove) return 'Gioca la mossa evidenziata.';
  final piece = pos.board.pieceAt(move.from);
  if (piece == null) return 'Gioca la mossa evidenziata.';
  final isCastling =
      piece.role == Role.king && (move.to.file - move.from.file).abs() == 2;
  if (isCastling) {
    return move.to.file > move.from.file ? 'Arrocca corto.' : 'Arrocca lungo.';
  }
  final promotion = move.promotion;
  if (promotion != null) {
    return 'Promuovi ${_the(piece.role)} in ${move.to.name}: '
        'diventa ${_names[promotion]!.$2}.';
  }

  final after = pos.play(move);
  final base = 'Sposta ${_the(piece.role)} in ${move.to.name}';
  if (pos.isCheck) {
    return piece.role == Role.king
        ? '$base: lo togli dallo scacco.'
        : '$base: pari lo scacco.';
  }
  final victim =
      pos.board.pieceAt(move.to) ??
      (piece.role == Role.pawn && move.from.file != move.to.file
          ? Piece(color: pos.turn.opposite, role: Role.pawn)
          : null);
  final check = after.isCheckmate
      ? 'scacco matto'
      : after.isCheck
      ? 'scacco'
      : null;
  if (victim != null) {
    final taken = ' e cattura ${_the(victim.role)}';
    return check == null ? '$base$taken.' : '$base$taken, dando $check.';
  }
  return check == null ? '$base.' : '$base e dai $check.';
}
