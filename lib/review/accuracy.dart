import 'dart:math' as math;

/// Precisione di una mossa (0–100) dalla probabilità di vittoria prima e dopo,
/// dal punto di vista di chi muove.
double moveAccuracy(double winBefore, double winAfter) {
  final loss = math.max(0.0, winBefore - winAfter);
  final raw =
      103.1668100711649 * math.exp(-0.04354415386753951 * loss) -
      3.166924740191411;
  return raw.clamp(0, 100).toDouble();
}

/// Media tra aritmetica e armonica: un solo errore grave abbassa il voto più
/// di quanto farebbe la media semplice.
double? gameAccuracy(List<double> moves) {
  if (moves.isEmpty) return null;
  final mean = moves.reduce((a, b) => a + b) / moves.length;
  final harmonic =
      moves.length /
      moves.map((a) => 1 / math.max(a, 1)).reduce((a, b) => a + b);
  return (mean + harmonic) / 2;
}

// Corrispondenza indicativa precisione → Elo, interpolata linearmente.
const _eloTable = <(double, int)>[
  (0, 100),
  (40, 250),
  (50, 400),
  (60, 800),
  (70, 1200),
  (80, 1700),
  (85, 2000),
  (90, 2300),
  (95, 2700),
  (100, 3200),
];

/// Stima indicativa della forza della prestazione.
int estimatedElo(double accuracy) {
  final a = accuracy.clamp(0, 100);
  for (var i = 1; i < _eloTable.length; i++) {
    final (x1, y1) = _eloTable[i];
    if (a <= x1) {
      final (x0, y0) = _eloTable[i - 1];
      return (y0 + (y1 - y0) * (a - x0) / (x1 - x0)).round();
    }
  }
  return _eloTable.last.$2;
}
