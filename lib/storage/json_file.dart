import 'dart:convert';
import 'dart:io';

/// File JSON locale con versione dello schema, scrittura atomica e
/// salvataggi accodati.
class JsonFile {
  JsonFile(this.file, {required this.version});

  final File file;
  final int version;
  Future<void> _pending = Future.value();

  /// Contenuto salvato, o `null` se il file manca. Un file illeggibile o di
  /// una versione futura viene rinominato in `.bad-<ms>` invece di essere
  /// sovrascritto, e il risultato è `null`.
  Future<Map<String, Object?>?> read({
    Map<String, Object?> Function(Map<String, Object?> json)? decode,
  }) async {
    await _pending;
    if (!await file.exists()) return null;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      final found = json['version'] as int? ?? 0;
      if (found < 1 || found > version) {
        throw FormatException('versione dello schema $found');
      }
      return decode == null ? json : decode(json);
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
