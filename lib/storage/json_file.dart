import 'dart:convert';
import 'dart:io';

/// File JSON locale con versione dello schema, scrittura atomica e
/// salvataggi accodati.
class JsonFile {
  JsonFile(this.file, {required this.version});

  final File file;
  final int version;
  Future<void> _pending = Future.value();

  /// Contenuto decodificato con [decode], o `null` se il file manca. Un file
  /// non valido (JSON, versione futura, o [decode] che fallisce) viene
  /// rinominato in `.bad-<ms>` invece di essere sovrascritto, e il risultato è
  /// `null`. Gli errori di lettura del disco si propagano senza toccare il file.
  Future<T?> read<T>(T Function(Map<String, Object?> json) decode) async {
    await _pending;
    final String text;
    try {
      text = await file.readAsString();
    } on PathNotFoundException {
      return null;
    }
    try {
      final json = jsonDecode(text) as Map<String, Object?>;
      final found = json['version'] as int? ?? 0;
      if (found < 1 || found > version) {
        throw FormatException('versione dello schema $found');
      }
      return decode(json);
    } on Object {
      await file.rename(
        '${file.path}.bad-${DateTime.now().millisecondsSinceEpoch}',
      );
      return null;
    }
  }

  /// Salva [data] con la versione; vince sempre l'ultimo salvataggio.
  Future<void> write(Map<String, Object?> data) {
    final next = _pending.then((_) => _write(data));
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
