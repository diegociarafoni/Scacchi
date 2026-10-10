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
  final pawns = _pawns(cp);
  if (pawns == '0.0') return pawns;
  return cp > 0 ? '+$pawns' : '$_minus$pawns';
}

String _pawns(int cp) => (cp.abs() / 100).toStringAsFixed(1);

/// Valutazione dal punto di vista del Bianco per i lettori di schermo.
String describeScore(EngineScore score) {
  final mate = score.mate;
  if (mate != null) {
    if (mate == 0) return 'Scacco matto';
    return 'Matto in ${mate.abs()} per il ${mate > 0 ? 'Bianco' : 'Nero'}';
  }
  final cp = score.cp!;
  final pawns = _pawns(cp);
  if (pawns == '0.0') return 'Parità';
  return '${cp > 0 ? 'Bianco' : 'Nero'} avanti di $pawns';
}
