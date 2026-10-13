import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';
import '../review/board_utils.dart';

const _value = {
  Role.pawn: 1,
  Role.knight: 3,
  Role.bishop: 3,
  Role.rook: 5,
  Role.queen: 9,
  Role.king: 100,
};

/// Una riga su cosa fa, minaccia o prepara la mossa del computer (RF-122).
/// [followUp] è la mossa che il computer giocherebbe subito dopo
/// (`CoachSession.threat`, come la freccia di RF-56): da lì le minacce. Con
/// [showSquares] falso (profilo bambino) non cita le case. `null` se la mossa
/// non è giocabile da [before].
String? explainComputerMove(
  AppLocalizations l,
  Position before,
  Move move, {
  NormalMove? followUp,
  bool showSquares = true,
}) {
  if (move is! NormalMove || !before.isLegal(move)) return null;
  final piece = before.board.pieceAt(move.from)!;
  final target = before.board.pieceAt(move.to);
  final after = before.play(move);
  final them = piece.color.opposite;
  String name(Role r) => l.whyPiece(r.name);

  if (after.isCheckmate) return l.whyMate;

  // Negli scacchi960 e in dartchess l'arrocco è «re sulla propria torre».
  final castles =
      piece.role == Role.king &&
      ((move.to.file - move.from.file).abs() == 2 ||
          (target?.role == Role.rook && target?.color == piece.color));
  if (castles) return l.whyCastle;

  final victim =
      target ??
      (piece.role == Role.pawn && move.from.file != move.to.file
          ? Piece(color: them, role: Role.pawn)
          : null);
  final promotion = move.promotion;
  final parts = [
    if (promotion != null) l.whyPromote(promotion.name),
    if (victim != null) l.whyCapture(name(victim.role), name(piece.role)),
    if (after.isCheck && (promotion != null || victim != null)) l.whyCheck,
  ];
  if (parts.isNotEmpty) return parts.join(' ');
  if (after.isCheck) return l.whyCheck;

  if (piece.role != Role.king &&
      _hanging(before.board, move.from, piece) &&
      after.board.attacksTo(move.to, them).isEmpty) {
    return l.whySafe(name(piece.role));
  }

  final threat = _threat(l, after, followUp, showSquares);
  if (threat != null) return threat;

  final home = piece.color == Side.white ? 0 : 7;
  if ((piece.role == Role.knight || piece.role == Role.bishop) &&
      move.from.rank == home) {
    return l.whyDevelop(name(piece.role));
  }
  final pushRank = piece.color == Side.white ? 3 : 4;
  if (piece.role == Role.pawn &&
      (move.to.file == File.d || move.to.file == File.e) &&
      move.to.rank == pushRank) {
    return l.whyCenter;
  }
  return l.whyImprove(name(piece.role));
}

/// Il pezzo in [sq] è davvero minacciato: attaccato da un pezzo di valore
/// minore o non difeso.
bool _hanging(Board board, Square sq, Piece piece) {
  final attackers = board.attacksTo(sq, piece.color.opposite);
  if (attackers.isEmpty) return false;
  final cheapest = attackers.squares
      .map((a) => _value[board.pieceAt(a)!.role]!)
      .reduce((a, b) => a < b ? a : b);
  return cheapest < _value[piece.role]! ||
      board.attacksTo(sq, piece.color).isEmpty;
}

/// Cosa farebbe il computer alla mossa seguente, se toccasse ancora a lui.
String? _threat(
  AppLocalizations l,
  Position after,
  NormalMove? followUp,
  bool showSquares,
) {
  if (followUp == null) return null;
  final fen = threatFen(after);
  if (fen == null) return null;
  final ahead = Chess.fromSetup(Setup.parseFen(fen));
  final next = parseEngineMove(ahead, followUp.uci);
  if (next is! NormalMove) return null;
  final mover = ahead.board.pieceAt(next.from);
  final prey = ahead.board.pieceAt(next.to);
  if (mover == null) return null;
  if (prey != null && prey.color != mover.color) {
    final defended = ahead.board.attacksTo(next.to, prey.color).isNotEmpty;
    if (!defended || _value[prey.role]! >= _value[mover.role]!) {
      final victim = l.whyPiece(prey.role.name);
      return showSquares
          ? l.whyThreatCapture(victim, next.to.name)
          : l.whyThreatCaptureKid(victim);
    }
  }
  if (next.promotion != null) return l.whyThreatPromote;
  if (ahead.play(next).isCheck) return l.whyThreatCheck;
  return null;
}
