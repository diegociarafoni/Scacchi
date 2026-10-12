import 'dart:typed_data';

import 'tb_geometry.dart';
import 'tb_material.dart';

/// Valori memorizzati in un byte per posizione.
abstract final class TbValue {
  /// Posizione impossibile o non canonica.
  static const illegal = 255;

  /// Patta.
  static const draw = 254;

  /// In costruzione: non ancora risolta.
  static const unknown = 253;

  /// Più lunga distanza dal matto in semimosse che si può memorizzare.
  static const maxPlies = 252;

  /// Chi muove vince: la distanza dal matto in semimosse è dispari.
  static bool isWin(int v) => v < unknown && v.isOdd;

  /// Chi muove perde: la distanza dal matto in semimosse è pari (0 = matto).
  static bool isLoss(int v) => v < unknown && v.isEven;
}

/// Archivio di un materiale: per ogni posizione la distanza dal matto in
/// semimosse (DTM), calcolata a ritroso dai matti. Le posizioni sono ridotte
/// con le simmetrie della scacchiera: otto senza pedoni, lo specchio
/// orizzontale con i pedoni.
class TbTable {
  TbTable(this.material, this.values)
    : assert(values.length == sizeFor(material)) {
    TbGeometry.init();
    slots = material.pieces;
    colors = Uint8List.fromList(material.slotColors);
    roles = Uint8List.fromList(material.slotRoles);
    _prepare();
  }

  static int sizeFor(TbMaterial m) {
    var size = m.hasPawns ? 32 : 10;
    for (var i = 1; i < m.pieces; i++) {
      size *= 64;
    }
    return size * 2;
  }

  final TbMaterial material;

  /// Un valore [TbValue] per posizione ridotta e lato che muove.
  final Uint8List values;

  late final int slots;
  late final Uint8List colors;
  late final Uint8List roles;

  /// Prima casella del re bianco, per ogni simmetria che lo porta nella zona
  /// canonica: casella → simmetrie valide.
  late final List<List<int>> _validSymmetries;

  /// Casella del re bianco → indice ridotto, o -1 fuori dalla zona.
  late final Int8List _kingIndex;

  /// Indice ridotto → casella del re bianco.
  late final Uint8List kingSquares;

  /// Coppie di caselle con lo stesso pezzo, da tenere in ordine.
  late final bool _twinPair;

  void _prepare() {
    final symmetries = material.hasPawns ? 2 : 8;
    _kingIndex = Int8List(64)..fillRange(0, 64, -1);
    final squares = <int>[];
    for (var s = 0; s < 64; s++) {
      final f = s & 7;
      final r = s >> 3;
      final inZone = material.hasPawns ? f <= 3 : r <= f && f <= 3;
      if (inZone) {
        _kingIndex[s] = squares.length;
        squares.add(s);
      }
    }
    kingSquares = Uint8List.fromList(squares);
    _validSymmetries = [
      for (var s = 0; s < 64; s++)
        [
          for (var i = 0; i < symmetries; i++)
            if (_kingIndex[TbGeometry.symmetry[i * 64 + s]] >= 0) i,
        ],
    ];
    _twinPair = slots == 4 && colors[2] == colors[3] && roles[2] == roles[3];
  }

  /// Indice canonico della posizione con [squares] (nell'ordine dei pezzi
  /// del materiale) e il lato che muove [stm] (0 Bianco, 1 Nero).
  int indexOf(List<int> squares, int stm) {
    final sym = TbGeometry.symmetry;
    final syms = _validSymmetries[squares[0]];
    var best = -1;
    for (var k = 0; k < syms.length; k++) {
      final base = syms[k] * 64;
      var key =
          _kingIndex[sym[base + squares[0]]] * 64 + sym[base + squares[1]];
      if (slots == 3) {
        key = key * 64 + sym[base + squares[2]];
      } else {
        var a = sym[base + squares[2]];
        var b = sym[base + squares[3]];
        if (_twinPair && a > b) {
          final t = a;
          a = b;
          b = t;
        }
        key = (key * 64 + a) * 64 + b;
      }
      if (best < 0 || key < best) best = key;
    }
    return best * 2 + stm;
  }

  /// Caselle dei pezzi dell'indice [index] in [out]; restituisce chi muove.
  int decode(int index, List<int> out) {
    final stm = index & 1;
    var rest = index >> 1;
    for (var i = slots - 1; i >= 1; i--) {
      out[i] = rest & 63;
      rest >>= 6;
    }
    out[0] = kingSquares[rest];
    return stm;
  }

  /// Valore della posizione, dal punto di vista di chi muove.
  int valueOf(List<int> squares, int stm) => values[indexOf(squares, stm)];
}
