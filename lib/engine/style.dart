import 'package:dartchess/dartchess.dart';

/// Stile di gioco dei bot (RF-23): sposta la scelta tra le prime candidate
/// del motore senza cambiarne la forza di base. Vedi docs/bot.md.
enum BotStyle { aggressive, positional, gambitist }

/// Bonus in centipedoni per [move] giocata da chi muove in [position].
int styleBonus(Position position, Move move, BotStyle style) {
  if (move is! NormalMove) return 0;
  final piece = position.board.pieceAt(move.from);
  if (piece == null) return 0;
  final target = position.board.pieceAt(move.to);
  final castling =
      piece.role == Role.king &&
      ((target != null && target.color == piece.color) ||
          (move.to.file - move.from.file).abs() == 2);
  final capture =
      !castling &&
      (target != null ||
          (piece.role == Role.pawn &&
              move.to.file != move.from.file &&
              position.board.pieceAt(move.to) == null));
  final after = position.playUnchecked(move);
  switch (style) {
    case BotStyle.aggressive:
      return (capture ? _aggressiveCapture : 0) +
          (after.isCheck ? _aggressiveCheck : 0);
    case BotStyle.positional:
      if (castling) return _positionalCastling;
      return capture ? 0 : _positionalQuiet;
    case BotStyle.gambitist:
      if (capture || castling || piece.role == Role.king) return 0;
      return after.board.attacksTo(move.to, after.turn).isNotEmpty
          ? _gambitOffer
          : 0;
  }
}

const _aggressiveCapture = 40;
const _aggressiveCheck = 40;
const _positionalCastling = 60;
const _positionalQuiet = 20;
const _gambitOffer = 60;
