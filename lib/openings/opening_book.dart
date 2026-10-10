import 'package:dartchess/dartchess.dart';

/// Apertura con codice ECO e nome (in inglese, come nel dataset Lichess).
class Opening {
  const Opening(this.eco, this.name);

  final String eco;
  final String name;

  /// Famiglia, per esempio "Sicilian Defense".
  String get family => name.split(': ').first;

  /// Variante dopo i due punti, se c'è.
  String? get variation {
    final i = name.indexOf(': ');
    return i < 0 ? null : name.substring(i + 2);
  }

  @override
  String toString() => '$eco $name';
}

/// Continuazione del libro da una posizione.
class BookMove {
  const BookMove({
    required this.move,
    required this.san,
    required this.lines,
    required this.share,
    this.opening,
  });

  final Move move;
  final String san;

  /// Varianti del libro che passano per questa mossa.
  final int lines;

  /// Quota delle varianti della posizione che proseguono con questa mossa.
  final double share;

  /// Apertura con nome raggiunta dalla mossa, se la posizione ne ha uno.
  final Opening? opening;
}

class _Edge {
  _Edge(this.move, this.child);

  final Move move;
  final String child;
  int lines = 0;
}

/// Libro delle aperture: posizioni con nome e mosse che le collegano.
///
/// Le posizioni sono confrontate per EPD, così le trasposizioni portano allo
/// stesso nome.
class OpeningBook {
  OpeningBook._();

  /// File TSV `eco\tname\tuci` con intestazione.
  factory OpeningBook.parseTsv(String tsv) {
    final book = OpeningBook._();
    for (final line in tsv.split('\n').skip(1)) {
      final f = line.trimRight().split('\t');
      if (f.length < 3) continue;
      book._addLine(Opening(f[0], f[1]), f[2].split(' '));
    }
    return book;
  }

  final Map<String, Opening> _names = {};
  final Map<String, Map<String, _Edge>> _edges = {};

  int get size => _names.length;

  static String key(Position pos) => pos.fen.split(' ').take(4).join(' ');

  void _addLine(Opening opening, List<String> moves) {
    Position pos = Chess.initial;
    for (final uci in moves) {
      final move = Move.parse(uci);
      if (move == null || !pos.isLegal(move)) return;
      final (after, san) = pos.makeSan(move);
      final edge = _edges
          .putIfAbsent(key(pos), () => {})
          .putIfAbsent(san, () => _Edge(move, key(after)));
      edge.lines++;
      pos = after;
    }
    _names.putIfAbsent(key(pos), () => opening);
  }

  /// Posizioni raggiunte da [moves] a partire dalla posizione iniziale; si ferma
  /// alla prima mossa illegale.
  static List<Position> replay(List<Move> moves) {
    final positions = <Position>[Chess.initial];
    for (final m in moves) {
      if (!positions.last.isLegal(m)) break;
      positions.add(positions.last.play(m));
    }
    return positions;
  }

  Opening? nameOf(Position pos) => _names[key(pos)];

  /// Ultima apertura con nome attraversata dalla partita.
  Opening? classify(List<Move> moves) => classifyPositions(replay(moves));

  /// Come [classify], a partire dalle posizioni già calcolate della partita.
  Opening? classifyPositions(List<Position> positions) {
    for (final pos in positions.reversed) {
      final o = _names[key(pos)];
      if (o != null) return o;
    }
    return null;
  }

  bool _inBook(Position pos) {
    final k = key(pos);
    return _names.containsKey(k) || _edges.containsKey(k);
  }

  /// Numero di semimosse iniziali di [moves] che restano nel libro.
  int bookPlies(List<Move> moves) {
    final positions = replay(moves);
    var n = 0;
    for (final pos in positions.skip(1)) {
      if (!_inBook(pos)) break;
      n++;
    }
    return n;
  }

  /// Mosse del libro dalla posizione raggiunta con [moves], dalla più ricca.
  List<BookMove> continuations(List<Move> moves) {
    final positions = replay(moves);
    if (positions.length != moves.length + 1) return const [];
    return continuationsAt(positions.last);
  }

  /// Mosse del libro da [pos], dalla più ricca.
  List<BookMove> continuationsAt(Position pos) {
    final edges = _edges[key(pos)];
    if (edges == null) return const [];
    final total = edges.values.fold(0, (sum, e) => sum + e.lines);
    final list =
        [
          for (final MapEntry(key: san, value: e) in edges.entries)
            BookMove(
              move: e.move,
              san: san,
              lines: e.lines,
              share: e.lines / total,
              opening: _names[e.child],
            ),
        ]..sort(
          (a, b) => b.lines != a.lines
              ? b.lines.compareTo(a.lines)
              : a.san.compareTo(b.san),
        );
    return list;
  }
}
