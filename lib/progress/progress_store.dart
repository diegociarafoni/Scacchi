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

  Future<void> _pending = Future.value();

  Future<ProgressData> load() async {
    await _pending;
    if (!await file.exists()) return _empty;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      final version = json['version'] as int? ?? 0;
      if (version < 1 || version > schemaVersion) {
        throw FormatException('versione dello schema $version');
      }
      return ProgressData(
        ProgressState.fromJson((json['state']! as Map).cast()),
        ProgressSettings.fromJson((json['settings']! as Map).cast()),
      );
    } on Object {
      // Il file non si legge: lo si mette da parte invece di sovrascriverlo.
      await file.rename(
        '${file.path}.bad-${DateTime.now().millisecondsSinceEpoch}',
      );
      return _empty;
    }
  }

  /// Salva [data]; i salvataggi si accodano, quindi vince sempre l'ultimo.
  Future<void> save(ProgressData data) {
    final next = _pending.then((_) => _write(data));
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> _write(ProgressData data) async {
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
