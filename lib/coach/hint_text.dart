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
/// Senza [showSquare] non cita la casa, per il profilo bambino che non vede
/// numeri: rimanda al cerchio sulla scacchiera.
String describeHintMove(Position pos, Move move, {bool showSquare = true}) {
  if (move is! NormalMove) return 'Gioca la mossa evidenziata.';
  final piece = pos.board.pieceAt(move.from);
  if (piece == null) return 'Gioca la mossa evidenziata.';
  final target = pos.board.pieceAt(move.to);
  // Negli scacchi960 l'arrocco è "re sulla propria torre".
  final isCastling =
      piece.role == Role.king &&
      ((move.to.file - move.from.file).abs() == 2 ||
          (target?.role == Role.rook && target?.color == piece.color));
  if (isCastling) {
    return move.to.file > move.from.file ? 'Arrocca corto.' : 'Arrocca lungo.';
  }

  final after = pos.play(move);
  final victim =
      target ??
      (piece.role == Role.pawn && move.from.file != move.to.file
          ? Piece(color: pos.turn.opposite, role: Role.pawn)
          : null);
  final where = showSquare ? 'in ${move.to.name}' : 'sul cerchio';
  final promotion = move.promotion;
  final base = promotion != null
      ? 'Promuovi ${_the(piece.role)} $where'
      : 'Sposta ${_the(piece.role)} $where';
  final end = promotion != null ? ': diventa ${_names[promotion]!.$2}' : '';
  final check = after.isCheckmate
      ? 'scacco matto'
      : after.isCheck
      ? 'scacco'
      : null;

  if (pos.isCheck) {
    final escape = piece.role == Role.king
        ? ': lo togli dallo scacco'
        : ': pari lo scacco';
    return check == null ? '$base$escape.' : '$base$escape, dando $check.';
  }
  final taken = victim == null ? '' : ' e cattura ${_the(victim.role)}';
  if (promotion != null) return '$base$taken$end.';
  if (victim != null) {
    return check == null ? '$base$taken.' : '$base$taken, dando $check.';
  }
  return check == null ? '$base.' : '$base e dai $check.';
}
