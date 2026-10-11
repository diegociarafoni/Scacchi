import 'dart:math' as math;

import '../engine/uci.dart';

/// Probabilità di vittoria (0–100) per il giocatore che muove, con la curva
/// logistica di Lichess: satura nelle posizioni decise, così +8 e +12 pesano
/// quasi uguale.
double winPercent(EngineScore score) {
  final mate = score.mate;
  if (mate != null) return mate > 0 ? 100 : 0;
  final cp = score.cp!.clamp(-1000, 1000);
  return 50 + 50 * (2 / (1 + math.exp(-0.00368208 * cp)) - 1);
}
