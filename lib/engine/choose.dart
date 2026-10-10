import 'dart:math' as math;

import 'uci.dart';

/// Sceglie una mossa tra le varianti candidate con una softmax sulla
/// valutazione: con temperatura 0, o una sola candidata, restituisce sempre
/// la migliore. Un matto a favore non viene mai scartato.
InfoLine? chooseCandidate(
  List<InfoLine> candidates,
  int temperatureCp,
  math.Random random,
) {
  if (candidates.isEmpty) return null;
  int value(InfoLine c) => c.score?.comparable ?? 0;
  final sorted = [...candidates]..sort((a, b) => value(b) - value(a));
  final best = sorted.first;
  if (temperatureCp <= 0 || sorted.length == 1) return best;
  if ((best.score?.mate ?? 0) > 0) return best;

  final top = value(best);
  final weights = [
    for (final c in sorted) math.exp((value(c) - top) / temperatureCp),
  ];
  var r = random.nextDouble() * weights.reduce((a, b) => a + b);
  for (var i = 0; i < sorted.length; i++) {
    r -= weights[i];
    if (r < 0) return sorted[i];
  }
  return best;
}
