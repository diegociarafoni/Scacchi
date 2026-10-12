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

/// Una riga su cosa fa, minaccia o prepara la mossa del computer (RF-122), con
/// regole a modello come il resto dell'allenatore. [followUp] è la mossa che il
/// computer giocherebbe subito dopo (`CoachSession.threat`, la stessa analisi
/// della freccia di RF-56): da lì si ricavano le minacce. Con [showSquares]
/// falso (profilo bambino) il testo non cita le case. `null` se la mossa non è
/// giocabile dalla posizione [before].
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

  final promotion = move.promotion;
  if (promotion != null) return l.whyPromote(promotion.name);

  final victim =
      target ??
      (piece.role == Role.pawn && move.from.file != move.to.file
          ? Piece(color: them, role: Role.pawn)
          : null);
  if (victim != null) {
    final text = l.whyCapture(name(victim.role), name(piece.role));
    return after.isCheck ? '$text ${l.whyCheck}' : text;
  }
  if (after.isCheck) return l.whyCheck;

  if (piece.role != Role.king &&
      before.board.attacksTo(move.from, them).isNotEmpty &&
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
      (move.to.rank == pushRank || move.to.rank == 7 - pushRank)) {
    return l.whyCenter;
  }
  return l.whyImprove(name(piece.role));
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
