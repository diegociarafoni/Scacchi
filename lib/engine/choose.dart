import 'dart:math' as math;

import 'uci.dart';

/// Sceglie una candidata con probabilità proporzionale a
/// exp((score - migliore) / temperatureCp); con temperatura 0 o una sola
/// candidata, la migliore. Un matto a favore vince sempre, il più breve.
/// [bonus] (stile di un bot) si somma alla valutazione; [windowCp] esclude le
/// candidate più lontane dalla migliore.
InfoLine? chooseCandidate(
  List<InfoLine> candidates,
  int temperatureCp,
  math.Random random, {
  int Function(InfoLine)? bonus,
  int? windowCp,
}) {
  if (candidates.isEmpty) return null;
  int raw(InfoLine c) => c.score?.comparable ?? 0;
  var pool = candidates;
  if (windowCp != null) {
    final top = candidates.map(raw).reduce(math.max);
    pool = [
      for (final c in candidates)
        if (raw(c) >= top - windowCp) c,
    ];
  }
  int value(InfoLine c) => raw(c) + (bonus?.call(c) ?? 0);
  final sorted = [...pool]..sort((a, b) => value(b) - value(a));
  final best = sorted.first;
  final mating = sorted.where((c) => (c.score?.mate ?? 0) > 0).toList()
    ..sort((a, b) => raw(b) - raw(a));
  if (mating.isNotEmpty) return mating.first;
  if (temperatureCp <= 0 || sorted.length == 1) return best;

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
