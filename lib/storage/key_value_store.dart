import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Archivio locale chiave-valore per piccoli stati in JSON.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

/// Tutte le chiavi in un unico file JSON, scritto in modo atomico.
class JsonFileStore implements KeyValueStore {
  JsonFileStore(this.file);

  /// File `training.json` nella cartella dati dell'app.
  static Future<JsonFileStore> open() async {
    final dir = await getApplicationSupportDirectory();
    return JsonFileStore(File('${dir.path}/training.json'));
  }

  final File file;
  Map<String, String>? _data;
  Future<void> _pending = Future.value();

  Future<Map<String, String>> _load() async {
    if (_data != null) return _data!;
    if (!await file.exists()) return _data = {};
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _data = {for (final e in json.entries) e.key: e.value as String};
    } on Object {
      // File illeggibile: lo si mette da parte invece di sovrascriverlo.
      await file.rename(
        '${file.path}.bad-${DateTime.now().millisecondsSinceEpoch}',
      );
      return _data = {};
    }
  }

  @override
  Future<String?> read(String key) async => (await _load())[key];

  @override
  Future<void> write(String key, String value) async {
    (await _load())[key] = value;
    final snapshot = jsonEncode(_data);
    // Scritture in coda: l'ultima vince sempre.
    final next = _pending.then((_) async {
      await file.parent.create(recursive: true);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(snapshot, flush: true);
      await tmp.rename(file.path);
    });
    _pending = next.catchError((Object e) {
      debugPrint('Salvataggio non riuscito: $e');
    });
    return _pending;
  }
}
