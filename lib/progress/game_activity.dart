import 'package:dartchess/dartchess.dart';

import '../game/chess_game.dart';
import 'activity.dart';

/// Converte una partita conclusa in un'attività, dal punto di vista di
/// [player]; senza [player] è una partita locale tra due persone.
/// La partita deve essere conclusa.
GamePlayed gameActivity(
  ChessGame game, {
  Side? player,
  int? opponentElo,
  Duration duration = Duration.zero,
}) {
  final outcome = game.outcome;
  if (outcome == null) {
    throw ArgumentError.value(game, 'game', 'partita non conclusa');
  }
  final result = player == null
      ? GameResult.local
      : outcome.winner == null
      ? GameResult.draw
      : outcome.winner == player
      ? GameResult.win
      : GameResult.loss;
  Role? matedWith;
  if (result == GameResult.win && game.endReason == GameEndReason.checkmate) {
    // Conta il pezzo che dà scacco, non quello mosso: vale per scoperte e arrocchi.
    final pos = game.position;
    final checkers = pos.checkers;
    if (checkers.size == 1) matedWith = pos.board.roleAt(checkers.first!);
  }
  var castledLong = false;
  var playerMoves = 0;
  var side = game.initial.turn;
  for (final m in game.moves) {
    if (side == player) {
      playerMoves++;
      if (m.san.startsWith('O-O-O')) castledLong = true;
    }
    side = side.opposite;
  }
  return GamePlayed(
    result: result,
    playerSide: player,
    moveCount: player == null ? (game.moves.length + 1) ~/ 2 : playerMoves,
    opponentElo: opponentElo,
    matedWith: matedWith,
    castledLong: castledLong,
    duration: duration,
  );
}
