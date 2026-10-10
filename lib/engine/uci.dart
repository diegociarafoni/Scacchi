/// Utilità pure per il protocollo UCI, senza dipendenze dal motore.
library;

/// Valutazione dal punto di vista del giocatore che muove: centipedoni o
/// matto in [mate] mosse (negativo se è chi muove a subirlo).
class EngineScore {
  const EngineScore.cp(int value) : cp = value, mate = null;
  const EngineScore.mate(int value) : mate = value, cp = null;

  final int? cp;
  final int? mate;

  /// Valore confrontabile: un matto vale più di qualsiasi vantaggio
  /// materiale, e un matto più vicino vale di più.
  int get comparable {
    final m = mate;
    if (m == null) return cp!;
    if (m == 0) return -100000;
    return m > 0 ? 100000 - m : -100000 - m;
  }

  EngineScore get negated =>
      mate != null ? EngineScore.mate(-mate!) : EngineScore.cp(-cp!);

  @override
  bool operator ==(Object other) =>
      other is EngineScore && other.cp == cp && other.mate == mate;

  @override
  int get hashCode => Object.hash(cp, mate);

  @override
  String toString() => mate != null ? 'mate $mate' : 'cp $cp';
}

/// Una riga `info` con una variante principale.
class InfoLine {
  const InfoLine({
    required this.multipv,
    required this.pv,
    this.depth,
    this.score,
  });

  final int multipv;
  final List<String> pv;
  final int? depth;
  final EngineScore? score;
}

final _uciMove = RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$');

/// `bestmove e2e4 ponder e7e5` → `e2e4`; `bestmove (none)` → `null`
/// (nessuna mossa legale).
String? parseBestMove(String line) {
  final parts = line.trim().split(RegExp(r'\s+'));
  if (parts.length < 2 || parts[0] != 'bestmove') return null;
  return _uciMove.hasMatch(parts[1]) ? parts[1] : null;
}

/// Interpreta una riga `info` che contiene una variante; altrimenti `null`.
InfoLine? parseInfo(String line) {
  if (!line.startsWith('info ') || !line.contains(' pv ')) return null;
  final t = line.trim().split(RegExp(r'\s+'));
  var multipv = 1;
  int? depth;
  EngineScore? score;
  var pv = <String>[];
  for (var i = 1; i < t.length; i++) {
    switch (t[i]) {
      case 'depth' when i + 1 < t.length:
        depth = int.tryParse(t[++i]);
      case 'multipv' when i + 1 < t.length:
        multipv = int.tryParse(t[++i]) ?? 1;
      case 'score' when i + 2 < t.length:
        final kind = t[++i];
        final value = int.tryParse(t[++i]);
        if (value != null && kind == 'cp') score = EngineScore.cp(value);
        if (value != null && kind == 'mate') score = EngineScore.mate(value);
      case 'pv':
        pv = t.sublist(i + 1);
        i = t.length;
    }
  }
  if (pv.isEmpty) return null;
  return InfoLine(multipv: multipv, pv: pv, depth: depth, score: score);
}
