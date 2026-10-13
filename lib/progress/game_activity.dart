import 'package:dartchess/dartchess.dart';

import '../badges/opening_volumes.dart';
import '../game/chess_game.dart';
import '../openings/opening_book.dart';
import 'activity.dart';

/// Converte una partita conclusa in un'attività, dal punto di vista di
/// [player]; senza [player] è una partita locale tra due persone.
/// La partita deve essere conclusa.
GamePlayed gameActivity(
  ChessGame game, {
  Side? player,
  int? opponentElo,
  Duration duration = Duration.zero,
  OpeningBook? book,
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
    checkmate: game.endReason == GameEndReason.checkmate,
    matedWith: matedWith,
    castledLong: castledLong,
    highlights: player == null
        ? const {}
        : _highlights(game, player, result, matedWith, playerMoves),
    openingBook: book == null ? null : _volume(game, book),
    duration: duration,
  );
}

/// Libro a cui porta l'ultima apertura con nome attraversata dalla partita.
String? _volume(ChessGame game, OpeningBook book) {
  final opening = book.classifyPositions([
    game.initial,
    for (final m in game.moves) m.after,
  ]);
  return opening == null ? null : volumeForFamily(opening.family)?.id;
}

Set<GameHighlight> _highlights(
  ChessGame game,
  Side player,
  GameResult result,
  Role? matedWith,
  int playerMoves,
) {
  final checkmate = game.endReason == GameEndReason.checkmate;
  var enPassant = false;
  var underpromotion = false;
  var before = game.initial;
  for (final played in game.moves) {
    final move = played.move;
    if (before.turn == player && move is NormalMove) {
      final promotion = move.promotion;
      if (promotion != null && promotion != Role.queen) underpromotion = true;
      // Il pedone che cattura in diagonale su una casa vuota prende en passant.
      if (before.board.roleAt(move.from) == Role.pawn &&
          move.from.file != move.to.file &&
          before.board.roleAt(move.to) == null) {
        enPassant = true;
      }
    }
    before = played.after;
  }
  return {
    if (result == GameResult.win &&
        checkmate &&
        matedWith == Role.queen &&
        playerMoves <= 4)
      GameHighlight.scholarsMate,
    if (result == GameResult.loss && checkmate && playerMoves <= 2)
      GameHighlight.foolsMate,
    if (enPassant) GameHighlight.enPassant,
    if (underpromotion) GameHighlight.underpromotion,
    if (game.endReason == GameEndReason.stalemate) GameHighlight.stalemate,
    if (playerMoves >= GameHighlight.marathonMoves) GameHighlight.marathon,
  };
}
