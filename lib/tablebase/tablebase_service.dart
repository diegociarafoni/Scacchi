import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart' show Position;

import 'tablebase.dart';
import 'tb_material.dart';
import 'tb_set.dart';
import 'tb_table.dart';

/// Versione del formato su disco: da alzare se cambia l'algoritmo o la
/// codifica, così le tabelle vecchie si rigenerano.
const tablebaseFormat = 1;

/// Genera le tabelle che mancano, di norma in un isolate: riceve il
/// materiale e le tabelle già pronte, restituisce quelle nuove per nome.
typedef TbBuilder = Future<Map<String, Uint8List>> Function(
  String material,
  Map<String, Uint8List> ready,
);

/// Costruisce le tabelle in un isolate, per non bloccare l'interfaccia.
Future<Map<String, Uint8List>> buildInIsolate(
  String material,
  Map<String, Uint8List> ready,
) => Isolate.run(() => buildTables(material, ready));

/// Come [buildInIsolate] ma nello stesso isolate.
Map<String, Uint8List> buildTables(
  String material,
  Map<String, Uint8List> ready,
) {
  final set = TbSet();
  for (final entry in ready.entries) {
    set.add(TbTable(TbMaterial.parse(entry.key), entry.value));
  }
  final created = <String, Uint8List>{};
  set.ensure(
    TbMaterial.parse(material),
    onGenerated: (t) => created[t.material.name] = t.values,
  );
  return created;
}

/// Tabelle dei finali perfetti: le genera la prima volta che servono (da
/// pochi decimi di secondo per tre pezzi a una decina di secondi per quattro
/// su un computer) e le tiene in una cartella locale compresse, così le
/// volte dopo si leggono soltanto. Nessun dato esce dal dispositivo.
class TablebaseService {
  TablebaseService(this._directory, {this.builder = buildInIsolate});

  final Future<Directory> Function() _directory;

  /// Calcola le tabelle mancanti.
  final TbBuilder builder;
  final TbSet _set = TbSet();

  /// Una richiesta alla volta: il motore e le tabelle non si calcolano in
  /// parallelo per non consumare batteria e memoria.
  Future<void> _queue = Future.value();

  late final Tablebase tablebase = Tablebase(_set);

  /// Vero se la posizione ha un materiale gestito.
  bool covers(Position pos) => Tablebase.covers(pos);

  /// Rende disponibili le tabelle per [pos], generandole se servono.
  /// Restituisce `false` se la posizione non è coperta o se la generazione
  /// non è riuscita (disco pieno, memoria).
  Future<bool> prepare(Position pos) {
    final material = Tablebase.materialOf(pos);
    if (material == null) return Future.value(false);
    final run = _queue.then((_) => _prepare(material));
    _queue = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  /// Vero se tutte le tabelle per [pos] sono già in memoria o su disco, cioè
  /// se [prepare] sarà rapido.
  Future<bool> isReady(Position pos) async {
    final material = Tablebase.materialOf(pos);
    if (material == null) return false;
    for (final m in TbSet.closure(material)) {
      if (_set.table(m) != null) continue;
      if (!(await _file(m)).existsSync()) return false;
    }
    return true;
  }

  Future<bool> _prepare(TbMaterial material) async {
    try {
      final needed = TbSet.closure(material);
      final ready = <String, Uint8List>{};
      var missing = false;
      for (final m in needed) {
        if (_set.table(m) != null) continue;
        final bytes = await _load(m);
        if (bytes == null) {
          missing = true;
        } else {
          _set.add(TbTable(m, bytes));
        }
      }
      if (!missing) return true;
      for (final table in _set.tables) {
        ready[table.material.name] = table.values;
      }
      final created = await builder(material.canonical.name, ready);
      for (final entry in created.entries) {
        final m = TbMaterial.parse(entry.key);
        _set.add(TbTable(m, entry.value));
        await _save(m, entry.value);
      }
      return _set.table(material) != null;
    } on Object {
      return false;
    }
  }

  Future<File> _file(TbMaterial m) async {
    final dir = await _directory();
    return File('${dir.path}/tablebase/${m.name}.v$tablebaseFormat.tb');
  }

  Future<Uint8List?> _load(TbMaterial m) async {
    final file = await _file(m);
    try {
      final bytes = Uint8List.fromList(
        ZLibDecoder().convert(await file.readAsBytes()),
      );
      if (bytes.length == TbTable.sizeFor(m)) return bytes;
    } on FileSystemException {
      return null;
    } on FormatException {
      // File danneggiato: si rigenera.
    }
    return null;
  }

  Future<void> _save(TbMaterial m, Uint8List values) async {
    try {
      final file = await _file(m);
      await file.parent.create(recursive: true);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(ZLibEncoder().convert(values), flush: true);
      // Rinomina atomica: un'interruzione non lascia il file a metà.
      await tmp.rename(file.path);
    } on FileSystemException {
      // Senza cache le tabelle restano valide in memoria.
    }
  }
}
