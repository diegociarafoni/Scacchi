import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';

/// Primo livello del suggerimento: solo il pezzo da muovere.
String describeHintPiece(AppLocalizations l, Position pos, Square from) {
  final piece = pos.board.pieceAt(from);
  return piece == null
      ? l.coachHintMoveSomePiece
      : l.coachHintMovePiece(l.whyPiece(piece.role.name));
}

/// Secondo livello: la mossa a parole semplici, senza notazione, con il
/// motivo quando si riconosce (scacco da parare, cattura, scacco dato).
/// Senza [showSquare] non cita la casa, per il profilo bambino che non vede
/// numeri: rimanda al cerchio sulla scacchiera.
String describeHintMove(
  AppLocalizations l,
  Position pos,
  Move move, {
  bool showSquare = true,
}) {
  if (move is! NormalMove) return l.coachHintPlayHighlighted;
  final piece = pos.board.pieceAt(move.from);
  if (piece == null) return l.coachHintPlayHighlighted;
  final target = pos.board.pieceAt(move.to);
  // Negli scacchi960 l'arrocco è "re sulla propria torre".
  final isCastling =
      piece.role == Role.king &&
      ((move.to.file - move.from.file).abs() == 2 ||
          (target?.role == Role.rook && target?.color == piece.color));
  if (isCastling) {
    return move.to.file > move.from.file
        ? l.coachHintCastleShort
        : l.coachHintCastleLong;
  }

  final after = pos.play(move);
  final victim =
      target ??
      (piece.role == Role.pawn && move.from.file != move.to.file
          ? Piece(color: pos.turn.opposite, role: Role.pawn)
          : null);
  final where = showSquare ? 'square' : 'circle';
  final promotion = move.promotion;
  final check = after.isCheckmate
      ? 'mate'
      : after.isCheck
      ? 'check'
      : 'none';
  final name = l.whyPiece(piece.role.name);
  final taken = victim == null ? '' : l.whyPiece(victim.role.name);

  if (pos.isCheck) {
    return l.coachHintCheckEscape(
      promotion != null ? 'yes' : 'no',
      name,
      where,
      move.to.name,
      piece.role == Role.king ? 'king' : 'other',
      check,
    );
  }
  if (promotion != null) {
    return l.coachHintPromote(
      name,
      where,
      move.to.name,
      victim != null ? 'yes' : 'no',
      taken,
      l.coachHintPieceAn(promotion.name),
    );
  }
  if (victim != null) {
    return l.coachHintCapture(name, where, move.to.name, taken, check);
  }
  return l.coachHintMove(name, where, move.to.name, check);
}
