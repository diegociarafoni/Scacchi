import 'package:dartchess/dartchess.dart';

import 'chess_game.dart';

/// Valore convenzionale dei pezzi, in pedoni.
const pieceValues = {
  Role.pawn: 1,
  Role.knight: 3,
  Role.bishop: 3,
  Role.rook: 5,
  Role.queen: 9,
  Role.king: 0,
};

/// Pezzi catturati e differenza di materiale di una partita.
class MaterialBalance {
  MaterialBalance._(this._captured, this._score);

  factory MaterialBalance.of(ChessGame game) {
    final captured = {for (final side in Side.values) side: <Role>[]};
    var before = game.initial;
    for (final played in game.moves) {
      final role = _capturedRole(before, played.move);
      if (role != null) captured[before.turn]!.add(role);
      before = played.after;
    }
    for (final list in captured.values) {
      list.sort((a, b) => pieceValues[b]!.compareTo(pieceValues[a]!));
    }
    final board = game.position.board;
    final score = {
      for (final side in Side.values) side: materialScore(board, side),
    };
    return MaterialBalance._(captured, score);
  }

  static Role? _capturedRole(Position before, Move move) {
    if (move is! NormalMove) return null;
    final target = before.board.pieceAt(move.to);
    if (target != null && target.color != before.turn) return target.role;
    final moving = before.board.pieceAt(move.from);
    if (moving?.role == Role.pawn && move.from.file != move.to.file) {
      return Role.pawn;
    }
    return null;
  }

  final Map<Side, List<Role>> _captured;
  final Map<Side, int> _score;

  /// Pezzi avversari catturati da [side], dal più prezioso.
  List<Role> capturedBy(Side side) => _captured[side]!;

  /// Materiale di [side] meno quello dell'avversario.
  int advantage(Side side) => _score[side]! - _score[side.opposite]!;
}

/// Somma dei valori dei pezzi di [side] sulla scacchiera.
int materialScore(Board board, Side side) => board
    .materialCount(side)
    .entries
    .fold(0, (sum, e) => sum + e.value * pieceValues[e.key]!);
