import 'dart:typed_data';

import 'tb_generator.dart';
import 'tb_material.dart';
import 'tb_table.dart';

/// Insieme degli archivi disponibili, per materiale canonico. Genera i
/// materiali che mancano, a partire da quelli più piccoli.
class TbSet implements TbLookup {
  final Map<int, TbTable> _tables = {};

  final List<int> _slotSquares = List<int>.filled(4, 0);
  final List<bool> _used = List<bool>.filled(4, false);

  Iterable<TbTable> get tables => _tables.values;

  TbTable? table(TbMaterial material) => _tables[material.canonical.code];

  /// Aggiunge un archivio già calcolato, per esempio letto dal disco.
  void add(TbTable table) => _tables[table.material.code] = table;

  /// Restituisce l'archivio del materiale, generandolo se manca insieme ai
  /// materiali da cui dipende. [onGenerated] riceve ogni archivio nuovo.
  TbTable ensure(
    TbMaterial material, {
    void Function(TbTable table)? onGenerated,
  }) {
    final canonical = material.canonical;
    if (!canonical.supported) {
      throw ArgumentError(
        'Materiale non gestito: ${canonical.name}', // l10n-ok
      );
    }
    final existing = _tables[canonical.code];
    if (existing != null) return existing;
    for (final dep in dependencies(canonical)) {
      if (dep.pieces > 2) ensure(dep, onGenerated: onGenerated);
    }
    final table = TbGenerator(canonical, this).generate();
    _tables[canonical.code] = table;
    onGenerated?.call(table);
    return table;
  }

  /// Materiale e tutti quelli da cui dipende, dal più piccolo; i soli re sono
  /// esclusi perché sono sempre patta.
  static List<TbMaterial> closure(TbMaterial material) {
    final ordered = <int, TbMaterial>{};
    void visit(TbMaterial m) {
      final canonical = m.canonical;
      if (canonical.pieces <= 2 || ordered.containsKey(canonical.code)) return;
      for (final dep in dependencies(canonical)) {
        visit(dep);
      }
      ordered[canonical.code] = canonical;
    }

    visit(material);
    return ordered.values.toList();
  }

  /// Materiali raggiungibili con una cattura o una promozione.
  static Set<TbMaterial> dependencies(TbMaterial m) {
    final result = <int, TbMaterial>{};
    void add(List<int> white, List<int> black) {
      final dep = TbMaterial(white, black).canonical;
      result[dep.code] = dep;
    }

    List<int> without(List<int> side, int i) => [...side]..removeAt(i);

    for (var i = 0; i < m.white.length; i++) {
      add(without(m.white, i), m.black);
    }
    for (var i = 0; i < m.black.length; i++) {
      add(m.white, without(m.black, i));
    }
    for (final sideIsWhite in const [true, false]) {
      final own = sideIsWhite ? m.white : m.black;
      final enemy = sideIsWhite ? m.black : m.white;
      for (var i = 0; i < own.length; i++) {
        if (own[i] != TbRole.pawn) continue;
        for (var r = TbRole.knight; r <= TbRole.queen; r++) {
          final promoted = [...own]..[i] = r;
          void put(List<int> enemySide) =>
              sideIsWhite ? add(promoted, enemySide) : add(enemySide, promoted);
          put(enemy);
          for (var j = 0; j < enemy.length; j++) {
            put(without(enemy, j));
          }
        }
      }
    }
    return result.values.toSet();
  }

  @override
  int lookup(
    Int32List colors,
    Int32List roles,
    Int32List squares,
    int count,
    int stm,
  ) {
    if (count <= 2) return TbValue.draw;
    final white = <int>[];
    final black = <int>[];
    for (var i = 0; i < count; i++) {
      if (roles[i] == TbRole.king) continue;
      (colors[i] == 0 ? white : black).add(roles[i]);
    }
    final material = TbMaterial(white, black);
    final swap = material.needsSwap;
    final table = _tables[material.canonical.code];
    if (table == null) {
      throw StateError('Archivio mancante: ${material.canonical.name}');
    }
    // Riempie le caselle nell'ordine dei pezzi dell'archivio.
    final slotColors = table.colors;
    final slotRoles = table.roles;
    for (var i = 0; i < count; i++) {
      _used[i] = false;
    }
    for (var s = 0; s < count; s++) {
      for (var i = 0; i < count; i++) {
        if (_used[i]) continue;
        final color = swap ? 1 - colors[i] : colors[i];
        if (color == slotColors[s] && roles[i] == slotRoles[s]) {
          _used[i] = true;
          _slotSquares[s] = swap ? squares[i] ^ 56 : squares[i];
          break;
        }
      }
    }
    return table.valueOf(_slotSquares, swap ? 1 - stm : stm);
  }
}
