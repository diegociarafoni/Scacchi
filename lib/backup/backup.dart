import 'dart:convert';
import 'dart:io';

/// Errore di un backup illeggibile o non compatibile.
class BackupException implements FormatException {
  BackupException(this.message);

  @override
  final String message;

  @override
  dynamic get source => null;

  @override
  int? get offset => null;

  @override
  String toString() => message;
}

/// Copia completa dei dati locali: file JSON dell'app e preferenze, in un
/// unico file leggibile (RF-103).
class Backup {
  Backup({required this.files, required this.preferences});

  static const _app = 'scacchi';
  static const _version = 1;

  /// Unici file ripristinabili: impedisce di scrivere altrove.
  static const dataFiles = {
    'games.json',
    'progress.json',
    'path.json',
    'tornei.json',
    'training.json',
  };

  /// Suffisso dei dati sostituiti da un ripristino.
  static const previousSuffix = '.prima-del-ripristino';

  /// Contenuto testuale dei file, per nome.
  final Map<String, String> files;

  /// Preferenze con valori semplici (bool, numeri, testo, elenchi di testo).
  final Map<String, Object> preferences;

  static Future<Backup> collect(
    Directory dir,
    Map<String, Object> preferences,
  ) async {
    final files = <String, String>{};
    for (final name in dataFiles) {
      final file = File('${dir.path}/$name');
      if (file.existsSync()) {
        files[name] = await file.readAsString();
      }
    }
    return Backup(files: files, preferences: {...preferences});
  }

  String encode() => jsonEncode({
    'app': _app,
    'version': _version,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'files': files,
    'preferences': preferences,
  });

  static Backup decode(String text) {
    try {
      final json = jsonDecode(text) as Map<String, Object?>;
      if (json['app'] != _app) {
        throw BackupException('Non è un backup di Scacchi');
      }
      final version = json['version'];
      if (version is! int || version < 1 || version > _version) {
        throw BackupException('Backup creato da una versione più recente');
      }
      final files = <String, String>{};
      for (final e in (json['files']! as Map<String, Object?>).entries) {
        if (!dataFiles.contains(e.key)) {
          throw BackupException('File inatteso nel backup: ${e.key}');
        }
        final content = e.value! as String;
        jsonDecode(content) as Map<String, Object?>;
        files[e.key] = content;
      }
      final preferences = <String, Object>{};
      for (final e in (json['preferences']! as Map<String, Object?>).entries) {
        final v = e.value;
        final simple =
            v is bool ||
            v is num ||
            v is String ||
            (v is List && v.every((x) => x is String));
        if (!simple) throw BackupException('Preferenza non valida: ${e.key}');
        preferences[e.key] = v is List ? List<String>.from(v) : v!;
      }
      return Backup(files: files, preferences: preferences);
    } on BackupException {
      rethrow;
    } on Object {
      throw BackupException('Backup non leggibile');
    }
  }

  /// Scrive i file in [dir]; i dati esistenti restano accanto, con il
  /// suffisso [previousSuffix].
  Future<void> restore(Directory dir) async {
    await dir.create(recursive: true);
    for (final e in files.entries) {
      final file = File('${dir.path}/${e.key}');
      if (file.existsSync()) await file.rename('${file.path}$previousSuffix');
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(e.value, flush: true);
      await tmp.rename(file.path);
    }
  }
}
