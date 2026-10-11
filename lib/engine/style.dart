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
      piece.role == Role.king && target != null && target.color == piece.color;
  final enPassant =
      piece.role == Role.pawn &&
      target == null &&
      move.to.file != move.from.file;
  final capture = !castling && (target != null || enPassant);
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
      return _offersMaterial(after, move.to, piece.role) ? _gambitOffer : 0;
  }
}

/// Il pezzo mosso in [square] è attaccato e perderebbe materiale in uno
/// scambio: nessun difensore, o un attaccante di valore minore.
bool _offersMaterial(Position after, Square square, Role role) {
  final attackers = after.board.attacksTo(square, after.turn);
  if (attackers.isEmpty) return false;
  final defenders = after.board.attacksTo(square, after.turn.opposite);
  if (defenders.isEmpty) return true;
  final cheapest = attackers.squares
      .map((s) => _value(after.board.roleAt(s)!))
      .reduce((a, b) => a < b ? a : b);
  return cheapest < _value(role);
}

int _value(Role role) => switch (role) {
  Role.pawn => 1,
  Role.knight || Role.bishop => 3,
  Role.rook => 5,
  Role.queen => 9,
  Role.king => 100,
};

const _aggressiveCapture = 40;
const _aggressiveCheck = 40;
const _positionalCastling = 60;
const _positionalQuiet = 20;
const _gambitOffer = 60;
