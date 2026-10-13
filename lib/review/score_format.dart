import '../engine/uci.dart';
import '../l10n/app_localizations.dart';

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
String describeScore(AppLocalizations l, EngineScore score) {
  final mate = score.mate;
  if (mate != null) {
    if (mate == 0) return l.reviewScoreCheckmate;
    return l.reviewScoreMateIn(mate.abs(), mate > 0 ? 'white' : 'black');
  }
  final cp = score.cp!;
  final pawns = _pawns(cp);
  if (pawns == '0.0') return l.reviewScoreEven;
  return l.reviewScoreAhead(cp > 0 ? 'white' : 'black', pawns);
}
