import '../engine/uci.dart';

const _minus = '−';

/// Valutazione dal punto di vista del Bianco in forma breve: `+0.3`, `M3`, `#`.
String formatScore(EngineScore score) {
  final mate = score.mate;
  if (mate != null) {
    if (mate == 0) return '#';
    return mate > 0 ? 'M$mate' : '${_minus}M${-mate}';
  }
  final cp = score.cp!;
  if (cp == 0) return '0.0';
  final pawns = (cp.abs() / 100).toStringAsFixed(1);
  return cp > 0 ? '+$pawns' : '$_minus$pawns';
}

/// Valutazione dal punto di vista del Bianco per i lettori di schermo.
String describeScore(EngineScore score) {
  final mate = score.mate;
  if (mate != null) {
    if (mate == 0) return 'Scacco matto';
    return 'Matto in ${mate.abs()} per il ${mate > 0 ? 'Bianco' : 'Nero'}';
  }
  final cp = score.cp!;
  if (cp.abs() < 10) return 'Parità';
  final pawns = (cp.abs() / 100).toStringAsFixed(1);
  return '${cp > 0 ? 'Bianco' : 'Nero'} avanti di $pawns';
}
