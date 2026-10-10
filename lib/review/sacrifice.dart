import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

const _values = {
  Role.pawn: 1,
  Role.knight: 3,
  Role.bishop: 3,
  Role.rook: 5,
  Role.queen: 9,
  Role.king: 0,
};

int _value(Piece? p) => p == null ? 0 : _values[p.role]!;

/// Materiale di [side] meno quello dell'avversario, in pedoni.
int materialBalance(Position pos, Side side) {
  int total(Side s) => pos.board
      .materialCount(s)
      .entries
      .fold(0, (sum, e) => sum + _values[e.key]! * e.value);
  return total(side) - total(side.opposite);
}

/// Vero se [played] cede almeno due pedoni di materiale: perché la variante
/// prevista [pv] li prende senza restituirli, oppure perché il pezzo mosso
/// resta in presa anche se il motore preferisce non prenderlo.
bool isSacrifice(Position before, Move played, List<String> pv) {
  if (!before.isLegal(played)) return false;
  final side = before.turn;
  final start = materialBalance(before, side);
  final after = before.play(played);
  if (_offered(before, played, after)) return true;

  var pos = after;
  Square? lastTo;
  var applied = 0;
  for (final uci in pv.take(4)) {
    final m = Move.parse(uci);
    if (m == null) break;
    final move = m is NormalMove ? pos.normalizeMove(m) : m;
    if (!pos.isLegal(move)) break;
    lastTo = move is NormalMove ? move.to : null;
    pos = pos.play(move);
    applied++;
  }
  var balance = materialBalance(pos, side);
  // Variante finita su una presa avversaria: contiamo la nostra ripresa.
  final target = lastTo;
  if (applied.isOdd && target != null) {
    final canRetake = pos.board
        .attacksTo(target, side)
        .squares
        .any((from) => pos.isLegal(NormalMove(from: from, to: target)));
    if (canRetake) balance += _value(pos.board.pieceAt(target));
  }
  return start - balance >= 2;
}

/// Pezzo mosso in presa: l'avversario lo guadagnerebbe catturandolo.
bool _offered(Position before, Move played, Position after) {
  if (played is! NormalMove) return false;
  final piece = after.board.pieceAt(played.to);
  final value = _value(piece);
  if (value < 3) return false;
  final captured = _value(before.board.pieceAt(played.to));
  final enemy = before.turn.opposite;
  final attackers = after.board.attacksTo(played.to, enemy);
  if (attackers.isEmpty) return false;
  final cheapest = attackers.squares
      .map((s) => _value(after.board.pieceAt(s)))
      .map((v) => v == 0 ? 100 : v)
      .reduce(math.min);
  final defended = after.board.attacksTo(played.to, before.turn).isNotEmpty;
  final gain = defended ? value - cheapest : value;
  return gain - captured >= 2;
}
