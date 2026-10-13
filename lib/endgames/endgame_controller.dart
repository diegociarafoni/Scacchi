import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../progress/activity.dart';
import '../storage/json_file.dart';
import 'drill.dart';
import 'endgame_progress.dart';

/// Stato dell'allenatore dei finali, salvato a ogni prova conclusa.
class EndgameController extends ChangeNotifier {
  EndgameController(File file, {this.recordActivity})
    : _file = JsonFile(file, version: 1);

  /// Controller sul file predefinito nella cartella dati dell'app.
  static Future<EndgameController> open({
    RecordActivity? recordActivity,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final controller = EndgameController(
      File('${dir.path}/endgames.json'),
      recordActivity: recordActivity,
    );
    await controller.load();
    return controller;
  }

  final JsonFile _file;

  /// Registra XP e obiettivo la prima volta che una posizione riesce.
  final RecordActivity? recordActivity;

  EndgameProgress _progress = const EndgameProgress();
  bool _readOnly = false;

  EndgameProgress get progress => _progress;

  Future<void> load() async {
    try {
      _progress =
          await _file.read(EndgameProgress.fromJson) ?? const EndgameProgress();
    } on FileSystemException catch (e) {
      debugPrint('Lettura dei finali non riuscita: $e'); // l10n-ok
      _readOnly = true;
    }
    notifyListeners();
  }

  /// Salva l'esito: zero stelle segna la posizione da ripetere.
  Future<void> finish(EndgameDrill drill, int stars, Duration duration) async {
    if (stars == 0) return _save(_progress.fail(drill.id));
    final first = _progress.starsFor(drill.id) == 0;
    await _save(_progress.complete(drill.id, stars));
    if (first) await recordActivity?.call(LessonCompleted(duration: duration));
  }

  Future<void> _save(EndgameProgress progress) async {
    _progress = progress;
    notifyListeners();
    if (_readOnly) return;
    try {
      await _file.write(progress.toJson());
    } on FileSystemException catch (e) {
      debugPrint('Salvataggio dei finali non riuscito: $e'); // l10n-ok
    }
  }
}
