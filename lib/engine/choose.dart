import 'dart:math' as math;

import 'uci.dart';

/// Sceglie una candidata con probabilità proporzionale a
/// exp((score - migliore) / temperatureCp). Con temperatura 0, una sola
/// candidata o un matto a favore restituisce la migliore. Il [bonus]
/// (stile di un bot) si somma alla valutazione, ma non scavalca un matto.
InfoLine? chooseCandidate(
  List<InfoLine> candidates,
  int temperatureCp,
  math.Random random, {
  int Function(InfoLine)? bonus,
}) {
  if (candidates.isEmpty) return null;
  int value(InfoLine c) => (c.score?.comparable ?? 0) + (bonus?.call(c) ?? 0);
  final sorted = [...candidates]..sort((a, b) => value(b) - value(a));
  final best = sorted.first;
  if (temperatureCp <= 0 || sorted.length == 1) return best;
  final mating = sorted.where((c) => (c.score?.mate ?? 0) > 0).firstOrNull;
  if (mating != null) return mating;

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
