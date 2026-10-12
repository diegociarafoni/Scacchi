import 'dart:typed_data';

import 'tb_geometry.dart';
import 'tb_material.dart';
import 'tb_table.dart';

/// Cerca il valore di una posizione in un altro archivio (catture e
/// promozioni portano a un materiale diverso).
abstract interface class TbLookup {
  /// [colors], [roles] e [squares] descrivono i [count] pezzi rimasti, re
  /// compresi; [stm] è chi muove (0 Bianco, 1 Nero).
  int lookup(
    Int32List colors,
    Int32List roles,
    Int32List squares,
    int count,
    int stm,
  );
}

/// Genera l'archivio di un materiale con l'analisi a ritroso: parte dai
/// matti e risale di una semimossa alla volta, quindi i valori sono la
/// distanza esatta dal matto. Le mosse che catturano o promuovono escono
/// dall'archivio e si leggono dagli archivi dei materiali più piccoli.
class TbGenerator {
  TbGenerator(this.material, this._others)
    : n = material.pieces,
      _colors = Int32List.fromList(material.slotColors),
      _roles = Int32List.fromList(material.slotRoles) {
    TbGeometry.init();
  }

  final TbMaterial material;
  final TbLookup _others;
  final int n;

  final Int32List _colors;
  final Int32List _roles;
  final Int32List _sq = Int32List(4);

  // Posizione in costruzione per leggere gli archivi dei materiali vicini.
  final Int32List _oc = Int32List(4);
  final Int32List _or = Int32List(4);
  final Int32List _os = Int32List(4);

  final Int32List _moves = Int32List(256);
  final Int32List _succ = Int32List(256);
  final Int32List _preds = Int32List(256);
  final List<int> _tmp = List<int>.filled(4, 0);

  late TbTable _table;
  late Uint8List _vals;
  late Uint8List _count;
  late Uint8List _outMax;
  final List<List<int>?> _buckets = List.filled(TbValue.maxPlies + 2, null);

  static const _blocked = 200;

  TbTable generate() {
    final size = TbTable.sizeFor(material);
    _vals = Uint8List(size)..fillRange(0, size, TbValue.illegal);
    _count = Uint8List(size);
    _outMax = Uint8List(size);
    _table = TbTable(material, _vals);

    final sq = _tmp;
    for (var index = 0; index < size; index++) {
      final stm = _table.decode(index, sq);
      for (var i = 0; i < n; i++) {
        _sq[i] = sq[i];
      }
      if (!_isLegal(stm) || _table.indexOf(sq, stm) != index) continue;
      _initPosition(index, stm);
    }
    _propagate();
    for (var i = 0; i < size; i++) {
      if (_vals[i] == TbValue.unknown) _vals[i] = TbValue.draw;
    }
    return _table;
  }

  // ---------------------------------------------------------------- geometria

  int _occupancy() {
    var occ = 0;
    for (var i = 0; i < n; i++) {
      if (_sq[i] >= 0) occ |= 1 << _sq[i];
    }
    return occ;
  }

  bool _isLegal(int stm) {
    var occ = 0;
    for (var i = 0; i < n; i++) {
      final s = _sq[i];
      if (occ & (1 << s) != 0) return false;
      occ |= 1 << s;
      if (_roles[i] == TbRole.pawn && (s < 8 || s >= 56)) return false;
    }
    // Chi non muove non può avere il re sotto scacco; vale anche per i re
    // adiacenti.
    final idle = 1 - stm;
    return !_attacked(_sq[idle], stm, occ);
  }

  /// Vero se [target] è attaccata da un pezzo del colore [by].
  bool _attacked(int target, int by, int occ) {
    for (var i = 0; i < n; i++) {
      if (_colors[i] != by) continue;
      final s = _sq[i];
      if (s < 0) continue;
      switch (_roles[i]) {
        case TbRole.king:
          if (TbGeometry.king[s] >>> target & 1 != 0) return true;
        case TbRole.knight:
          if (TbGeometry.knight[s] >>> target & 1 != 0) return true;
        case TbRole.pawn:
          if (TbGeometry.pawn[by * 64 + s] >>> target & 1 != 0) return true;
        case TbRole.bishop:
          if (_slides(s, target, occ, 2)) return true;
        case TbRole.rook:
          if (_slides(s, target, occ, 1)) return true;
        default:
          if (_slides(s, target, occ, 0)) return true;
      }
    }
    return false;
  }

  /// [kind] 1 torre, 2 alfiere, 0 donna.
  bool _slides(int from, int to, int occ, int kind) {
    final l = TbGeometry.line[from * 64 + to];
    if (l == 0 || (kind != 0 && l != kind)) return false;
    return TbGeometry.between[from * 64 + to] & occ == 0;
  }

  // ------------------------------------------------------------- generazione

  static const _rookDirs = [1, 0, -1, 0, 0, 1, 0, -1];
  static const _bishopDirs = [1, 1, 1, -1, -1, 1, -1, -1];

  // Stato della generazione in corso, per non creare funzioni annidate nei
  // cicli più caldi.
  int _gSide = 0;
  int _gOcc = 0;
  int _gCount = 0;
  bool _gChecked = false;
  int _gPinned = 0;

  /// Mosse legali di [side] in [_moves]: casella dell'elenco, destinazione,
  /// promozione (ruolo + 1) e pezzo catturato (+ 1). Restituisce quante.
  int _genMoves(int side) {
    _gSide = side;
    _gCount = 0;
    _gOcc = _occupancy();
    var own = 0;
    for (var i = 0; i < n; i++) {
      if (_sq[i] >= 0 && _colors[i] == side) own |= 1 << _sq[i];
    }
    _findPins(side);
    for (var i = 0; i < n; i++) {
      if (_colors[i] != side || _sq[i] < 0) continue;
      final from = _sq[i];
      switch (_roles[i]) {
        case TbRole.king:
          _targets(i, TbGeometry.king[from] & ~own);
        case TbRole.knight:
          _targets(i, TbGeometry.knight[from] & ~own);
        case TbRole.pawn:
          final up = side == 0 ? 8 : -8;
          final startRank = side == 0 ? 1 : 6;
          final one = from + up;
          if (_gOcc & (1 << one) == 0) {
            _pawnMove(i, one);
            if (from >> 3 == startRank && _gOcc & (1 << (one + up)) == 0) {
              _tryAdd(i, one + up, 0);
            }
          }
          var caps = TbGeometry.pawn[side * 64 + from] & _gOcc & ~own;
          while (caps != 0) {
            final low = caps & -caps;
            _pawnMove(i, _square(low));
            caps ^= low;
          }
        default:
          final role = _roles[i];
          if (role != TbRole.bishop) _slide(i, from, _rookDirs, own);
          if (role != TbRole.rook) _slide(i, from, _bishopDirs, own);
      }
    }
    return _gCount;
  }

  /// Calcola se il re di [side] è sotto scacco e quali pezzi suoi sono
  /// inchiodati: solo per questi, o con il re in scacco, una mossa può
  /// lasciarlo esposto.
  void _findPins(int side) {
    final king = _sq[side];
    _gChecked = _attacked(king, 1 - side, _gOcc);
    _gPinned = 0;
    for (var i = 0; i < n; i++) {
      if (_colors[i] == side) continue;
      final role = _roles[i];
      if (role < TbRole.bishop || role == TbRole.king) continue;
      final line = TbGeometry.line[_sq[i] * 64 + king];
      if (line == 0 ||
          (role == TbRole.bishop && line != 2) ||
          (role == TbRole.rook && line != 1)) {
        continue;
      }
      final between = TbGeometry.between[_sq[i] * 64 + king] & _gOcc;
      if (between != 0 && between & (between - 1) == 0) _gPinned |= between;
    }
  }

  static int _square(int lowBit) => lowBit < 0 ? 63 : lowBit.bitLength - 1;

  void _targets(int slot, int mask) {
    while (mask != 0) {
      final low = mask & -mask;
      _tryAdd(slot, _square(low), 0);
      mask ^= low;
    }
  }

  void _pawnMove(int slot, int to) {
    final last = _gSide == 0 ? 7 : 0;
    if (to >> 3 == last) {
      for (var r = TbRole.knight; r <= TbRole.queen; r++) {
        _tryAdd(slot, to, r + 1);
      }
    } else {
      _tryAdd(slot, to, 0);
    }
  }

  void _slide(int slot, int from, List<int> dirs, int own) {
    for (var d = 0; d < dirs.length; d += 2) {
      var file = (from & 7) + dirs[d];
      var rank = (from >> 3) + dirs[d + 1];
      while (file >= 0 && file < 8 && rank >= 0 && rank < 8) {
        final t = rank * 8 + file;
        final bit = 1 << t;
        if (own & bit != 0) break;
        _tryAdd(slot, t, 0);
        if (_gOcc & bit != 0) break;
        file += dirs[d];
        rank += dirs[d + 1];
      }
    }
  }

  /// Registra la mossa se lascia al re il suo lato al sicuro.
  void _tryAdd(int slot, int to, int promo) {
    final side = _gSide;
    var captured = -1;
    for (var j = 0; j < n; j++) {
      if (_colors[j] != side && _sq[j] == to) captured = j;
    }
    final from = _sq[slot];
    var safe = true;
    if (_gChecked || slot == side || _gPinned & (1 << from) != 0) {
      final newOcc = (_gOcc & ~(1 << from)) | (1 << to);
      _sq[slot] = to;
      if (captured >= 0) _sq[captured] = -1;
      safe = !_attacked(_sq[side], 1 - side, newOcc);
      if (captured >= 0) _sq[captured] = to;
      _sq[slot] = from;
    }
    if (safe) {
      _moves[_gCount++] =
          slot | (to << 3) | (promo << 9) | ((captured + 1) << 12);
    }
  }

  // ---------------------------------------------------------------- iniziale

  void _initPosition(int index, int stm) {
    final count = _genMoves(stm);
    if (count == 0) {
      if (_attacked(_sq[stm], 1 - stm, _occupancy())) {
        _vals[index] = 0;
        _push(0, index);
      } else {
        _vals[index] = TbValue.draw;
      }
      return;
    }
    _vals[index] = TbValue.unknown;
    var quiet = 0;
    var minLoss = 1 << 30;
    var maxWin = 0;
    var escapes = false;
    final sq = _tmp;
    for (var m = 0; m < count; m++) {
      final move = _moves[m];
      final slot = move & 7;
      final to = (move >> 3) & 63;
      final promo = (move >> 9) & 7;
      final captured = (move >> 12) - 1;
      final from = _sq[slot];
      if (captured < 0 && promo == 0) {
        _sq[slot] = to;
        for (var i = 0; i < n; i++) {
          sq[i] = _sq[i];
        }
        _sq[slot] = from;
        quiet = _addUnique(_succ, quiet, _table.indexOf(sq, 1 - stm));
        continue;
      }
      final v = _outsideValue(slot, to, promo, captured, 1 - stm);
      if (v == TbValue.draw) {
        escapes = true;
      } else if (TbValue.isLoss(v)) {
        if (v < minLoss) minLoss = v;
      } else if (v > maxWin) {
        maxWin = v;
      }
    }
    if (minLoss < (1 << 30)) {
      _push(minLoss + 1, index);
    } else if (escapes) {
      _count[index] = _blocked;
    } else {
      _count[index] = quiet;
      _outMax[index] = maxWin;
      if (quiet == 0) _push(maxWin + 1, index);
    }
  }

  /// Valore, per chi muove dopo [stm], della posizione che segue una cattura o
  /// una promozione.
  int _outsideValue(int slot, int to, int promo, int captured, int stm) {
    var count = 0;
    for (var i = 0; i < n; i++) {
      if (i == captured) continue;
      _oc[count] = _colors[i];
      _or[count] = i == slot && promo > 0 ? promo - 1 : _roles[i];
      _os[count] = i == slot ? to : _sq[i];
      count++;
    }
    return _others.lookup(_oc, _or, _os, count, stm);
  }

  /// Aggiunge [value] a [list] (lunga [used]) se manca; restituisce la nuova
  /// lunghezza.
  int _addUnique(Int32List list, int used, int value) {
    for (var i = 0; i < used; i++) {
      if (list[i] == value) return used;
    }
    list[used] = value;
    return used + 1;
  }

  void _push(int ply, int index) {
    if (ply > TbValue.maxPlies) {
      throw StateError('Distanza dal matto oltre il limite');
    }
    (_buckets[ply] ??= <int>[]).add(index);
  }

  // --------------------------------------------------------------- ritroso

  void _propagate() {
    final sq = _tmp;
    for (var ply = 0; ply <= TbValue.maxPlies; ply++) {
      final bucket = _buckets[ply];
      if (bucket == null) continue;
      for (var k = 0; k < bucket.length; k++) {
        final index = bucket[k];
        if (ply > 0 && _vals[index] != TbValue.unknown) continue;
        _vals[index] = ply;
        final stm = _table.decode(index, sq);
        for (var i = 0; i < n; i++) {
          _sq[i] = sq[i];
        }
        final preds = _unmoves(1 - stm, sq);
        for (var p = 0; p < preds; p++) {
          final q = _preds[p];
          if (_vals[q] != TbValue.unknown) continue;
          if (ply.isEven) {
            _push(ply + 1, q);
          } else if (_count[q] < _blocked && --_count[q] == 0) {
            final worst = _outMax[q] > ply ? _outMax[q] : ply;
            _push(worst + 1, q);
          }
        }
      }
      _buckets[ply] = null;
    }
  }

  int _uMover = 0;
  int _uOcc = 0;
  int _uSlot = 0;
  int _uTo = 0;
  int _uUsed = 0;

  /// Posizioni da cui [mover] arriva a quella corrente con una mossa che non
  /// cattura né promuove; indici canonici distinti in [_preds].
  int _unmoves(int mover, List<int> sq) {
    _uMover = mover;
    _uUsed = 0;
    _uOcc = _occupancy();
    for (var i = 0; i < n; i++) {
      if (_colors[i] != mover) continue;
      final to = _sq[i];
      _uSlot = i;
      _uTo = to;
      switch (_roles[i]) {
        case TbRole.king:
          _backTargets(TbGeometry.king[to] & ~_uOcc, sq);
        case TbRole.knight:
          _backTargets(TbGeometry.knight[to] & ~_uOcc, sq);
        case TbRole.pawn:
          final down = mover == 0 ? -8 : 8;
          final from = to + down;
          final startRank = mover == 0 ? 1 : 6;
          if (from >= 8 && from < 56 && _uOcc & (1 << from) == 0) {
            _back(from, sq);
            final two = from + down;
            if (two >> 3 == startRank && _uOcc & (1 << two) == 0) {
              _back(two, sq);
            }
          }
        default:
          final role = _roles[i];
          if (role != TbRole.bishop) _backSlide(_rookDirs, sq);
          if (role != TbRole.rook) _backSlide(_bishopDirs, sq);
      }
    }
    return _uUsed;
  }

  void _backTargets(int mask, List<int> sq) {
    while (mask != 0) {
      final low = mask & -mask;
      _back(_square(low), sq);
      mask ^= low;
    }
  }

  void _backSlide(List<int> dirs, List<int> sq) {
    for (var d = 0; d < dirs.length; d += 2) {
      var file = (_uTo & 7) + dirs[d];
      var rank = (_uTo >> 3) + dirs[d + 1];
      while (file >= 0 && file < 8 && rank >= 0 && rank < 8) {
        final t = rank * 8 + file;
        if (_uOcc & (1 << t) != 0) break;
        _back(t, sq);
        file += dirs[d];
        rank += dirs[d + 1];
      }
    }
  }

  /// La mossa dell'elenco [_uSlot] veniva da [from]: la posizione di
  /// partenza è valida se chi non muove non era sotto scacco.
  void _back(int from, List<int> sq) {
    final mover = _uMover;
    _sq[_uSlot] = from;
    final newOcc = (_uOcc & ~(1 << _uTo)) | (1 << from);
    if (!_attacked(_sq[1 - mover], mover, newOcc)) {
      for (var j = 0; j < n; j++) {
        sq[j] = _sq[j];
      }
      _uUsed = _addUnique(_preds, _uUsed, _table.indexOf(sq, mover));
    }
    _sq[_uSlot] = _uTo;
  }
}
