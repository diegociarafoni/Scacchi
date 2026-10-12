import 'package:dartchess/dartchess.dart';

/// Statistiche di una mossa dalle partite del database pubblico: quante volte
/// è stata giocata e come sono finite, viste dal Bianco.
class MoveStat {
  const MoveStat(this.san, this.games, this.white, this.black);

  final String san;
  final int games;

  /// Partite vinte dal Bianco e dal Nero; le patte sono il resto.
  final int white;
  final int black;

  int get draws => games - white - black;

  /// Percentuali intere che sommano sempre 100 (resto maggiore), perché tre
  /// arrotondamenti separati possono dare 99 o 101.
  ({int white, int draws, int black}) get percents {
    if (games <= 0) return (white: 0, draws: 0, black: 0);
    final parts = [white, draws, black];
    final base = [for (final p in parts) p * 100 ~/ games];
    final order = [0, 1, 2]
      ..sort((a, b) {
        final ra = parts[a] * 100 % games;
        final rb = parts[b] * 100 % games;
        return rb != ra ? rb.compareTo(ra) : a.compareTo(b);
      });
    final missing = 100 - base.fold(0, (a, b) => a + b);
    for (var i = 0; i < missing; i++) {
      base[order[i]]++;
    }
    return (white: base[0], draws: base[1], black: base[2]);
  }
}

/// Statistiche per mossa del libro delle aperture, incluse nell'app per
/// funzionare senza rete.
///
/// File TSV `chiave\tmosse` con intestazione; `mosse` è un elenco separato da
/// virgole di `san:partite:vittorie-bianco:vittorie-nero`, dalla più giocata.
/// Lo produce `tool/datasets/build_opening_stats.py`.
class OpeningStats {
  OpeningStats._(this._rows);

  factory OpeningStats.parseTsv(String tsv) {
    final rows = <String, List<MoveStat>>{};
    for (final line in tsv.split('\n').skip(1)) {
      final f = line.trimRight().split('\t');
      if (f.length < 2 || f[0].isEmpty) continue;
      final moves = <MoveStat>[];
      for (final item in f[1].split(',')) {
        final p = item.split(':');
        if (p.length != 4) continue;
        final games = int.tryParse(p[1]);
        final white = int.tryParse(p[2]);
        final black = int.tryParse(p[3]);
        if (games == null || white == null || black == null) continue;
        if (white < 0 || black < 0 || white + black > games) continue;
        moves.add(MoveStat(p[0], games, white, black));
      }
      if (moves.isNotEmpty) rows[f[0]] = moves;
    }
    return OpeningStats._(rows);
  }

  final Map<String, List<MoveStat>> _rows;

  bool get isEmpty => _rows.isEmpty;

  /// Chiave di una posizione: hash FNV-1a a 64 bit di pezzi, tratto e
  /// arrocchi. L'en passant è escluso perché i due lati lo scrivono in modo
  /// diverso; il generatore Python usa la stessa regola.
  static String keyOf(Position pos) {
    var h = 0xcbf29ce484222325;
    for (final b in pos.fen.split(' ').take(3).join(' ').codeUnits) {
      h = (h ^ b) * 0x100000001b3;
    }
    String half(int v) => v.toRadixString(16).padLeft(8, '0');
    return half(h >>> 32) + half(h & 0xffffffff);
  }

  /// Mosse con statistiche da [pos], dalla più giocata.
  List<MoveStat> at(Position pos) => _rows[keyOf(pos)] ?? const [];

  int totalAt(Position pos) => at(pos).fold(0, (sum, m) => sum + m.games);
}
