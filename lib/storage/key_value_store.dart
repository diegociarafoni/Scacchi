import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'json_file.dart';

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

/// Tutte le chiavi in un unico file JSON (`JsonFile`: scrittura atomica,
/// salvataggi accodati, file non valido messo da parte).
class JsonFileStore implements KeyValueStore {
  JsonFileStore(File file) : _file = JsonFile(file, version: 1);

  static Future<JsonFileStore>? _shared;

  /// File `training.json` nella cartella dati dell'app, condiviso da puzzle e
  /// repertorio: una sola istanza, così le scritture non si sovrascrivono.
  static Future<JsonFileStore> open() =>
      _shared ??= getApplicationSupportDirectory().then(
        (dir) => JsonFileStore(File('${dir.path}/training.json')),
      );

  final JsonFile _file;
  Future<Map<String, String>>? _data;

  // Il Future è memorizzato: letture concorrenti condividono la stessa mappa.
  Future<Map<String, String>> _load() => _data ??= _file
      .read(
        (json) => {
          for (final e in (json['values']! as Map).entries)
            e.key as String: e.value as String,
        },
      )
      .then((m) => m ?? <String, String>{});

  @override
  Future<String?> read(String key) async => (await _load())[key];

  @override
  Future<void> write(String key, String value) async {
    final data = await _load();
    data[key] = value;
    try {
      await _file.write({
        'values': {...data},
      });
    } on FileSystemException catch (e) {
      // Senza spazio o permessi si continua con i dati in memoria.
      debugPrint('Salvataggio non riuscito: $e'); // l10n-ok
    }
  }
}
