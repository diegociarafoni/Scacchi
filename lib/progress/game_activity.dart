import 'package:dartchess/dartchess.dart';

import '../game/chess_game.dart';
import 'activity.dart';

/// Converte una partita conclusa in un'attività, dal punto di vista di
/// [player]; senza [player] è una partita locale tra due persone.
GamePlayed gameActivity(
  ChessGame game, {
  Side? player,
  Duration duration = Duration.zero,
}) {
  final winner = game.outcome?.winner;
  final result = player == null
      ? GameResult.local
      : game.outcome == null || winner == null
      ? GameResult.draw
      : winner == player
      ? GameResult.win
      : GameResult.loss;
  Role? matedWith;
  if (result == GameResult.win && game.endReason == GameEndReason.checkmate) {
    final last = game.moves.last;
    final to = (last.move as NormalMove).to;
    matedWith = last.after.board.roleAt(to);
  }
  var castledLong = false;
  var side = game.initial.turn;
  for (final m in game.moves) {
    if (side == player && m.san.startsWith('O-O-O')) castledLong = true;
    side = side.opposite;
  }
  return GamePlayed(
    result: result,
    matedWith: matedWith,
    castledLong: castledLong,
    duration: duration,
  );
}
