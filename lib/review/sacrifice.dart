import 'package:dartchess/dartchess.dart';

const _values = {
  Role.pawn: 1,
  Role.knight: 3,
  Role.bishop: 3,
  Role.rook: 5,
  Role.queen: 9,
  Role.king: 0,
};

/// Materiale di [side] meno quello dell'avversario, in pedoni.
int materialBalance(Position pos, Side side) {
  int total(Side s) => pos.board
      .materialCount(s)
      .entries
      .fold(0, (sum, e) => sum + _values[e.key]! * e.value);
  return total(side) - total(side.opposite);
}

/// Vero se [played] cede almeno due pedoni di materiale che la variante
/// prevista [pv] non restituisce entro le due risposte successive.
bool isSacrifice(Position before, Move played, List<String> pv) {
  final side = before.turn;
  final start = materialBalance(before, side);
  if (!before.isLegal(played)) return false;
  var pos = before.play(played);

  // Finestra pari (avversario, noi, ...) per contare la ripresa del pezzo.
  var plies = pv.length.clamp(0, 4);
  if (plies > 1 && plies.isOdd) plies--;
  var balance = materialBalance(pos, side);
  for (final uci in pv.take(plies)) {
    final m = Move.parse(uci);
    if (m == null) break;
    final move = m is NormalMove ? pos.normalizeMove(m) : m;
    if (!pos.isLegal(move)) break;
    pos = pos.play(move);
    balance = materialBalance(pos, side);
  }
  return start - balance >= 2;
}
