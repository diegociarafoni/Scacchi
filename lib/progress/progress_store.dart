import 'dart:convert';
import 'dart:io';

import 'progress_state.dart';

/// Stato e impostazioni della gamification salvati insieme.
class ProgressData {
  const ProgressData(this.state, this.settings);

  final ProgressState state;
  final ProgressSettings settings;
}

/// Salvataggio locale in un file JSON con versione dello schema.
class ProgressStore {
  ProgressStore(this.file);

  static const schemaVersion = 1;

  final File file;

  Future<ProgressData> load() async {
    try {
      if (!await file.exists()) return _empty;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      return ProgressData(
        ProgressState.fromJson((json['state']! as Map).cast()),
        ProgressSettings.fromJson((json['settings']! as Map).cast()),
      );
    } on Object {
      // Un file corrotto non deve impedire di giocare.
      return _empty;
    }
  }

  Future<void> save(ProgressData data) async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'version': schemaVersion,
        'settings': data.settings.toJson(),
        'state': data.state.toJson(),
      }),
      flush: true,
    );
    // Rinomina atomica: un'interruzione non lascia il file a metà.
    await tmp.rename(file.path);
  }

  static const _empty = ProgressData(ProgressState.initial, ProgressSettings());
}
