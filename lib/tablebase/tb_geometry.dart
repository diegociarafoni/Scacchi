import 'dart:typed_data';

/// Tabelle di attacco precalcolate per le caselle 0–63 (a1 = 0, h1 = 7).
abstract final class TbGeometry {
  static final Int64List knight = Int64List(64);
  static final Int64List king = Int64List(64);

  /// Caselle attaccate da un pedone: indice colore · 64 + casella.
  static final Int64List pawn = Int64List(128);

  /// 0 se le caselle non sono allineate, 1 sulla stessa riga o colonna,
  /// 2 sulla stessa diagonale; indice a · 64 + b.
  static final Uint8List line = Uint8List(4096);

  /// Caselle strettamente tra a e b, se allineate.
  static final Int64List between = Int64List(4096);

  /// Le otto simmetrie della scacchiera: indice simmetria · 64 + casella.
  static final Uint8List symmetry = Uint8List(512);

  static bool _ready = false;

  static void init() {
    if (_ready) return;
    _ready = true;
    for (var s = 0; s < 64; s++) {
      final f = s & 7;
      final r = s >> 3;
      for (final (df, dr) in const [
        (1, 2),
        (2, 1),
        (-1, 2),
        (-2, 1),
        (1, -2),
        (2, -1),
        (-1, -2),
        (-2, -1),
      ]) {
        final nf = f + df;
        final nr = r + dr;
        if (nf >= 0 && nf < 8 && nr >= 0 && nr < 8) {
          knight[s] |= 1 << (nr * 8 + nf);
        }
      }
      for (var df = -1; df <= 1; df++) {
        for (var dr = -1; dr <= 1; dr++) {
          final nf = f + df;
          final nr = r + dr;
          if ((df != 0 || dr != 0) && nf >= 0 && nf < 8 && nr >= 0 && nr < 8) {
            king[s] |= 1 << (nr * 8 + nf);
          }
        }
      }
      for (final df in const [-1, 1]) {
        final nf = f + df;
        if (nf < 0 || nf > 7) continue;
        if (r < 7) pawn[s] |= 1 << ((r + 1) * 8 + nf);
        if (r > 0) pawn[64 + s] |= 1 << ((r - 1) * 8 + nf);
      }
      for (var t = 0; t < 64; t++) {
        if (s == t) continue;
        final df = (t & 7) - f;
        final dr = (t >> 3) - r;
        final isLine = df == 0 || dr == 0;
        final isDiagonal = df.abs() == dr.abs();
        if (!isLine && !isDiagonal) continue;
        line[s * 64 + t] = isLine ? 1 : 2;
        final stepF = df.sign;
        final stepR = dr.sign;
        var mask = 0;
        var cf = f + stepF;
        var cr = r + stepR;
        while (cf != (t & 7) || cr != (t >> 3)) {
          mask |= 1 << (cr * 8 + cf);
          cf += stepF;
          cr += stepR;
        }
        between[s * 64 + t] = mask;
      }
      final coords = [
        (f, r),
        (7 - f, r),
        (f, 7 - r),
        (7 - f, 7 - r),
        (r, f),
        (7 - r, f),
        (r, 7 - f),
        (7 - r, 7 - f),
      ];
      for (var i = 0; i < 8; i++) {
        symmetry[i * 64 + s] = coords[i].$2 * 8 + coords[i].$1;
      }
    }
  }
}
