import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';

/// Immagine in toni di grigio, già ridotta, su cui si confrontano le foto.
class BoardFrame {
  BoardFrame({required this.width, required this.height, required this.luma})
    : assert(luma.length == width * height);

  final int width;
  final int height;
  final Uint8List luma;

  /// Luminosità nel punto normalizzato ([x], [y]) tra 0 e 1.
  int sample(double x, double y) {
    final px = (x * width).floor().clamp(0, width - 1);
    final py = (y * height).floor().clamp(0, height - 1);
    return luma[py * width + px];
  }
}

/// Punto della foto in coordinate normalizzate (0..1).
class PhotoPoint {
  const PhotoPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is PhotoPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PhotoPoint($x, $y)';
}

/// Angoli della scacchiera nella foto, visti da chi guarda l'immagine.
class BoardQuad {
  const BoardQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  /// Scacchiera che occupa tutta la foto, con un bordo di [margin].
  factory BoardQuad.inset(double margin) => BoardQuad(
    topLeft: PhotoPoint(margin, margin),
    topRight: PhotoPoint(1 - margin, margin),
    bottomRight: PhotoPoint(1 - margin, 1 - margin),
    bottomLeft: PhotoPoint(margin, 1 - margin),
  );

  static const full = BoardQuad(
    topLeft: PhotoPoint(0, 0),
    topRight: PhotoPoint(1, 0),
    bottomRight: PhotoPoint(1, 1),
    bottomLeft: PhotoPoint(0, 1),
  );

  final PhotoPoint topLeft;
  final PhotoPoint topRight;
  final PhotoPoint bottomRight;
  final PhotoPoint bottomLeft;

  BoardQuad copyWith({
    PhotoPoint? topLeft,
    PhotoPoint? topRight,
    PhotoPoint? bottomRight,
    PhotoPoint? bottomLeft,
  }) => BoardQuad(
    topLeft: topLeft ?? this.topLeft,
    topRight: topRight ?? this.topRight,
    bottomRight: bottomRight ?? this.bottomRight,
    bottomLeft: bottomLeft ?? this.bottomLeft,
  );

  /// Punto della foto corrispondente a ([u], [v]) nella scacchiera, con
  /// (0,0) in alto a sinistra e (1,1) in basso a destra: interpolazione
  /// bilineare, sufficiente per una ripresa quasi dall'alto.
  PhotoPoint at(double u, double v) {
    double mix(double a, double b, double c, double d) =>
        (a * (1 - u) + b * u) * (1 - v) + (d * (1 - u) + c * u) * v;
    return PhotoPoint(
      mix(topLeft.x, topRight.x, bottomRight.x, bottomLeft.x),
      mix(topLeft.y, topRight.y, bottomRight.y, bottomLeft.y),
    );
  }
}

/// Mossa legale con il suo costo: più è basso, meglio spiega le due foto.
typedef PhotoGuess = ({Move move, double cost});

/// Sotto questa differenza media di luminosità le due foto sono uguali.
const _minChange = 18.0;

/// Spostamento della seconda foto tollerato, in frazione della foto.
const _jitter = 0.008;

const _promotionOrder = [Role.queen, Role.rook, Role.bishop, Role.knight];

/// Deduce quale mossa legale di [pos] separa la foto [before] dalla foto
/// [after] della stessa scacchiera, senza riconoscere i pezzi: guarda quali
/// caselle sono cambiate e sceglie le mosse che cambiano proprio quelle.
/// [view] è il lato che sta in basso nella foto. Le mosse sono ordinate dalla
/// più probabile; la lista è vuota se le foto non differiscono.
List<PhotoGuess> guessMoves(
  Position pos, {
  required BoardFrame before,
  required BoardFrame after,
  BoardQuad quad = BoardQuad.full,
  Side view = Side.white,
}) {
  final change = _squareChanges(before, after, quad, view);
  final sorted = [...change.values]..sort();
  final top = sorted.last;
  if (top < _minChange) return const [];
  // Una mossa cambia almeno due caselle: la seconda per entità dà la scala.
  final scale = math.max(sorted[sorted.length - 2] * .5, _minChange);
  final level = {
    for (final e in change.entries) e.key: (e.value / scale).clamp(0.0, 1.0),
  };

  final guesses = <PhotoGuess>[];
  for (final entry in pos.legalMoves.entries) {
    for (final to in entry.value.squares) {
      final base = NormalMove(from: entry.key, to: to);
      final touched = _touched(pos, base);
      var cost = 0.0;
      for (final e in level.entries) {
        cost += touched.contains(e.key) ? 1 - e.value : e.value;
      }
      if (_isPromotion(pos, base)) {
        for (final (i, role) in _promotionOrder.indexed) {
          guesses.add((move: base.withPromotion(role), cost: cost + i * 1e-3));
        }
      } else {
        guesses.add((move: base, cost: cost));
      }
    }
  }
  guesses.sort((a, b) => a.cost.compareTo(b.cost));
  return guesses;
}

/// Le prime [count] mosse con caselle di partenza e arrivo diverse: le
/// quattro promozioni di una stessa mossa occupano un posto solo (la prima,
/// cioè la donna).
List<PhotoGuess> topGuesses(List<PhotoGuess> guesses, int count) {
  final seen = <(Square, Square)>{};
  final top = <PhotoGuess>[];
  for (final g in guesses) {
    final m = g.move;
    if (m is NormalMove && !seen.add((m.from, m.to))) continue;
    top.add(g);
    if (top.length == count) break;
  }
  return top;
}

/// Caselle che una mossa cambia nella foto.
Set<Square> _touched(Position pos, NormalMove move) {
  final piece = pos.board.pieceAt(move.from);
  final target = pos.board.pieceAt(move.to);
  final touched = {move.from, move.to};
  if (piece?.role == Role.king) {
    final castlesOwnRook =
        target != null &&
        target.color == piece!.color &&
        target.role == Role.rook;
    final twoSteps = (move.to.file - move.from.file).abs() == 2;
    if (castlesOwnRook || twoSteps) {
      // Re e torre finiscono sempre su g/f (lato di re) o c/d (lato di
      // donna), anche negli arrocchi di Chess960.
      final kingSide = move.to.file > move.from.file;
      final rank = move.from.rank;
      touched
        ..add(
          castlesOwnRook
              ? move.to
              : Square.fromCoords(File(kingSide ? 7 : 0), rank),
        )
        ..add(Square.fromCoords(File(kingSide ? 6 : 2), rank))
        ..add(Square.fromCoords(File(kingSide ? 5 : 3), rank));
    }
  } else if (piece?.role == Role.pawn &&
      target == null &&
      move.from.file != move.to.file) {
    touched.add(Square.fromCoords(move.to.file, move.from.rank));
  }
  return touched;
}

bool _isPromotion(Position pos, NormalMove move) {
  final last = move.to.rank == Rank.first || move.to.rank == Rank.eighth;
  return last && pos.board.pieceAt(move.from)?.role == Role.pawn;
}

/// Differenza media di luminosità, casella per casella, già corretta per
/// la luce complessiva e per un piccolo movimento della mano.
Map<Square, double> _squareChanges(
  BoardFrame before,
  BoardFrame after,
  BoardQuad quad,
  Side view,
) {
  const grid = 5;
  const offsets = [
    (0.0, 0.0),
    (_jitter, 0.0),
    (-_jitter, 0.0),
    (0.0, _jitter),
    (0.0, -_jitter),
    (_jitter, _jitter),
    (-_jitter, -_jitter),
    (_jitter, -_jitter),
    (-_jitter, _jitter),
  ];

  // Punti da confrontare in ogni casella: una griglia nella metà centrale,
  // dove stanno i pezzi, lontano dai bordi che la prospettiva sposta.
  List<PhotoPoint> points(Square s) {
    final col = view == Side.white ? s.file.value : 7 - s.file.value;
    final row = view == Side.white ? 7 - s.rank.value : s.rank.value;
    return [
      for (var i = 0; i < grid; i++)
        for (var j = 0; j < grid; j++)
          quad.at(
            (col + .25 + .5 * (i + .5) / grid) / 8,
            (row + .25 + .5 * (j + .5) / grid) / 8,
          ),
    ];
  }

  final perSquare = {for (final s in Square.values) s: points(s)};

  double meanDiff(List<PhotoPoint> pts, double dx, double dy, double gain) {
    var sum = 0.0;
    for (final p in pts) {
      sum += (after.sample(p.x + dx, p.y + dy) - before.sample(p.x, p.y) - gain)
          .abs();
    }
    return sum / pts.length;
  }

  // Se cambia la luce cambiano tutte le caselle: la mediana delle differenze
  // con segno è l'effetto della luce, non delle mosse.
  final signed = <double>[];
  for (final pts in perSquare.values) {
    var sum = 0.0;
    for (final p in pts) {
      sum += after.sample(p.x, p.y) - before.sample(p.x, p.y);
    }
    signed.add(sum / pts.length);
  }
  signed.sort();
  final gain = (signed[31] + signed[32]) / 2;

  return {
    for (final e in perSquare.entries)
      e.key: offsets
          .map((o) => meanDiff(e.value, o.$1, o.$2, gain))
          .reduce(math.min),
  };
}
