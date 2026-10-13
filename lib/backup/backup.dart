import 'dart:convert';
import 'dart:io';

/// Motivo per cui un backup viene rifiutato.
enum BackupProblem {
  notApp,
  newerVersion,
  unexpectedFile,
  invalidFile,
  invalidPreference,
  unreadable,
}

/// Errore di un backup illeggibile o non compatibile; [detail] è il file o la
/// preferenza coinvolta, se c'è.
class BackupException implements FormatException {
  BackupException(this.problem, [this.detail]);

  final BackupProblem problem;
  final String? detail;

  @override
  String get message =>
      detail == null ? problem.name : '${problem.name}: $detail';

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
  Backup({
    required this.files,
    required this.preferences,
    this.binaries = const {},
    this.version = _version,
  });

  static const _app = 'scacchi';

  /// 2: aggiunti settimana, grandi maestri, finali, partita a due telefoni e
  /// file binari (foto del profilo).
  static const _version = 2;

  /// Unici file ripristinabili: impedisce di scrivere altrove.
  static const dataFiles = {
    'games.json',
    'progress.json',
    'path.json',
    'story.json',
    'tornei.json',
    'training.json',
    'week.json',
    'masters.json',
    'endgames.json',
    'multiplayer.json',
  };

  /// Unici file binari ripristinabili (nel backup in base64).
  static const binaryFiles = {'avatar_photo.jpg'};

  /// Dati che i backup di versione 1 non contenevano: la loro assenza non
  /// significa «vuoto», quindi un ripristino vecchio li lascia intatti.
  static const _sinceV2 = {
    'week.json',
    'masters.json',
    'endgames.json',
    'multiplayer.json',
    'avatar_photo.jpg',
  };

  /// Backup in attesa di essere applicato all'avvio.
  static const pendingName = 'ripristino-in-attesa.json'; // l10n-ok

  /// Suffisso dei dati sostituiti da un ripristino.
  static const previousSuffix = '.prima-del-ripristino'; // l10n-ok

  /// Contenuto testuale dei file, per nome.
  final Map<String, String> files;

  /// Preferenze con valori semplici (bool, numeri, testo, elenchi di testo).
  final Map<String, Object> preferences;

  /// Contenuto dei file binari, per nome.
  final Map<String, List<int>> binaries;

  /// Versione del formato del file di backup.
  final int version;

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
    final binaries = <String, List<int>>{};
    for (final name in binaryFiles) {
      final file = File('${dir.path}/$name');
      if (file.existsSync()) binaries[name] = await file.readAsBytes();
    }
    return Backup(
      files: files,
      preferences: {...preferences},
      binaries: binaries,
    );
  }

  String encode() => jsonEncode({
    'app': _app,
    'version': version,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'files': files,
    'binaries': {
      for (final e in binaries.entries) e.key: base64Encode(e.value),
    },
    'preferences': preferences,
  });

  static Backup decode(String text) {
    try {
      final json = jsonDecode(text) as Map<String, Object?>;
      if (json['app'] != _app) {
        throw BackupException(BackupProblem.notApp);
      }
      final version = json['version'];
      if (version is! int || version < 1 || version > _version) {
        throw BackupException(BackupProblem.newerVersion);
      }
      final files = <String, String>{};
      for (final e
          in ((json['files'] ?? <String, Object?>{}) as Map<String, Object?>)
              .entries) {
        if (!dataFiles.contains(e.key)) {
          throw BackupException(BackupProblem.unexpectedFile, e.key);
        }
        final content = e.value! as String;
        final stored = jsonDecode(content) as Map<String, Object?>;
        final fileVersion = stored['version'];
        if (fileVersion is! int || fileVersion < 1) {
          throw BackupException(BackupProblem.invalidFile, e.key);
        }
        files[e.key] = content;
      }
      final binaries = <String, List<int>>{};
      for (final e
          in ((json['binaries'] ?? <String, Object?>{}) as Map<String, Object?>)
              .entries) {
        if (!binaryFiles.contains(e.key)) {
          throw BackupException(BackupProblem.unexpectedFile, e.key);
        }
        try {
          binaries[e.key] = base64Decode(e.value! as String);
        } on Object {
          throw BackupException(BackupProblem.invalidFile, e.key);
        }
      }
      final preferences = <String, Object>{};
      for (final e
          in ((json['preferences'] ?? <String, Object?>{})
                  as Map<String, Object?>)
              .entries) {
        final v = e.value;
        final simple =
            v is bool ||
            v is num ||
            v is String ||
            (v is List && v.every((x) => x is String));
        if (!simple) {
          throw BackupException(BackupProblem.invalidPreference, e.key);
        }
        preferences[e.key] = v is List ? List<String>.from(v) : v!;
      }
      return Backup(
        files: files,
        preferences: preferences,
        binaries: binaries,
        version: version,
      );
    } on BackupException {
      rethrow;
    } on Object {
      throw BackupException(BackupProblem.unreadable);
    }
  }

  /// Mette il backup in attesa: viene applicato al prossimo avvio, prima che
  /// qualunque archivio sia caricato, così nessun dato in memoria lo
  /// sovrascrive.
  Future<void> stage(Directory dir) async {
    await dir.create(recursive: true);
    final tmp = File('${dir.path}/$pendingName.tmp');
    await tmp.writeAsString(encode(), flush: true);
    await tmp.rename('${dir.path}/$pendingName');
  }

  /// Applica il backup in attesa, se c'è. I file locali sostituiti o assenti
  /// dal backup restano accanto con suffisso [previousSuffix] e l'ora;
  /// [applyPreferences] riceve le preferenze da sostituire per intero.
  static Future<bool> applyPending(
    Directory dir,
    Future<void> Function(Map<String, Object> preferences) applyPreferences,
  ) async {
    final pending = File('${dir.path}/$pendingName');
    if (!pending.existsSync()) return false;
    final text = await pending.readAsString();
    // Eliminato subito: un errore non deve ripetersi a ogni avvio.
    await pending.delete();
    final backup = decode(text);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (final name in dataFiles) {
      if (backup.version < 2 && _sinceV2.contains(name)) continue;
      final file = File('${dir.path}/$name');
      if (file.existsSync()) {
        await file.rename('${file.path}$previousSuffix-$stamp');
      }
      final content = backup.files[name];
      if (content == null) continue;
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(content, flush: true);
      await tmp.rename(file.path);
    }
    for (final name in binaryFiles) {
      if (backup.version < 2 && _sinceV2.contains(name)) continue;
      final file = File('${dir.path}/$name');
      if (file.existsSync()) {
        await file.rename('${file.path}$previousSuffix-$stamp');
      }
      final bytes = backup.binaries[name];
      if (bytes == null) continue;
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
    }
    await applyPreferences(backup.preferences);
    return true;
  }
}
