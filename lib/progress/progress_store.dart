import 'dart:io';

import '../storage/json_file.dart';
import 'progress_state.dart';

/// Stato e impostazioni della gamification salvati insieme.
class ProgressData {
  const ProgressData(this.state, this.settings);

  final ProgressState state;
  final ProgressSettings settings;
}

/// Salvataggio locale dei progressi in un file JSON (vedi [JsonFile]).
class ProgressStore {
  ProgressStore(File file) : _file = JsonFile(file, version: schemaVersion);

  static const schemaVersion = 1;

  final JsonFile _file;

  /// Progressi salvati, o quelli iniziali se il file manca o non è valido.
  /// Gli errori di lettura del disco si propagano.
  Future<ProgressData> load() async =>
      await _file.read(
        (json) => ProgressData(
          ProgressState.fromJson((json['state']! as Map).cast()),
          ProgressSettings.fromJson((json['settings']! as Map).cast()),
        ),
      ) ??
      const ProgressData(ProgressState.initial, ProgressSettings());

  /// Salva [data]; i salvataggi si accodano, quindi vince sempre l'ultimo.
  Future<void> save(ProgressData data) => _file.write({
    'settings': data.settings.toJson(),
    'state': data.state.toJson(),
  });
}
