import 'dart:convert';
import 'dart:io';

/// Porta il contenuto dalla versione `n` alla `n + 1` dello schema.
typedef JsonMigration = Map<String, Object?> Function(
  Map<String, Object?> json,
);

/// File JSON locale con versione dello schema, migrazioni, scrittura atomica
/// e salvataggi accodati.
class JsonFile {
  JsonFile(
    this.file, {
    required this.version,
    this.migrations = const {},
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final DateTime Function() _clock;

  final File file;
  final int version;

  /// Passi per aggiornare un file vecchio: la chiave `n` porta dalla versione
  /// `n` alla `n + 1`. Prima di migrare si tiene una copia in `.v<n>.bak`.
  final Map<int, JsonMigration> migrations;
  Future<void> _pending = Future.value();

  /// Contenuto decodificato con [decode], o `null` se il file manca. Un file
  /// vecchio passa prima dalle [migrations] (la lettura non lo riscrive: lo fa
  /// il primo salvataggio). Un file non valido (JSON, versione futura, passo
  /// di migrazione mancante o fallito, o [decode] che fallisce) viene
  /// rinominato in `.bad-<ms>` invece di essere sovrascritto, e il risultato è
  /// `null`. Gli errori di lettura del disco si propagano senza toccare il file.
  Future<T?> read<T>(T Function(Map<String, Object?> json) decode) async {
    await _pending;
    final String text;
    try {
      text = utf8.decode(await file.readAsBytes());
    } on PathNotFoundException {
      return null;
    } on FormatException {
      return _setAside();
    }
    final Map<String, Object?> json;
    final int found;
    try {
      json = jsonDecode(text) as Map<String, Object?>;
      found = json['version'] as int? ?? 0;
      if (found < 1 || found > version) {
        throw FormatException('versione dello schema $found');
      }
      for (var v = found; v < version; v++) {
        if (migrations[v] == null) {
          throw FormatException('manca la migrazione da $v');
        }
      }
    } on Object {
      return _setAside();
    }
    // Fuori dal controllo del contenuto: un errore del disco si propaga e il
    // file buono resta dov'è.
    if (found < version) await _keepCopy(found, text);
    try {
      var migrated = json;
      for (var v = found; v < version; v++) {
        migrated = {...migrations[v]!(migrated), 'version': v + 1};
      }
      return decode(migrated);
    } on Object {
      return _setAside();
    }
  }

  /// Il nome porta i millisecondi; se esiste già (due file rovinati nello
  /// stesso istante) si aggiunge un contatore, perché la rinomina
  /// sovrascriverebbe in silenzio la copia precedente.
  Future<T?> _setAside<T>() async {
    final base = '${file.path}.bad-${_clock().millisecondsSinceEpoch}';
    var target = base;
    for (var n = 1; File(target).existsSync(); n++) {
      target = '$base-$n';
    }
    await file.rename(target);
    return null;
  }

  /// Copia del file com'era prima di migrare, una sola volta per versione e
  /// con rinomina atomica, così un'interruzione non lascia una copia a metà.
  Future<void> _keepCopy(int found, String text) async {
    final copy = File('${file.path}.v$found.bak');
    if (copy.existsSync()) return;
    final tmp = File('${copy.path}.tmp');
    await tmp.writeAsString(text, flush: true);
    await tmp.rename(copy.path);
  }

  /// Salva [data] con la versione; vince sempre l'ultimo salvataggio.
  Future<void> write(Map<String, Object?> data) {
    final next = _pending.then((_) => _write(data));
    _pending = next.catchError((Object _) {});
    return next;
  }

  /// Elimina il file, dopo i salvataggi già accodati.
  Future<void> delete() {
    final next = _pending.then((_) async {
      try {
        await file.delete();
      } on PathNotFoundException {
        // Già assente.
      }
    });
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> _write(Map<String, Object?> data) async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({'version': version, ...data}),
      flush: true,
    );
    // Rinomina atomica: un'interruzione non lascia il file a metà.
    await tmp.rename(file.path);
  }
}
