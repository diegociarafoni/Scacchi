import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../progress/activity.dart';
import '../storage/json_file.dart';
import 'curriculum.dart';
import 'path_progress.dart';

typedef RecordActivity = Future<void> Function(Activity activity);

/// Stato del percorso per l'interfaccia, salvato a ogni tappa completata.
class PathController extends ChangeNotifier {
  PathController(File file, {this.recordActivity})
    : _file = JsonFile(file, version: 1);

  /// Controller sul file predefinito nella cartella dati dell'app.
  static Future<PathController> open({RecordActivity? recordActivity}) async {
    final dir = await getApplicationSupportDirectory();
    final controller = PathController(
      File('${dir.path}/path.json'),
      recordActivity: recordActivity,
    );
    await controller.load();
    return controller;
  }

  final JsonFile _file;

  /// Registra XP e obiettivo per le lezioni completate.
  final RecordActivity? recordActivity;

  PathProgress _progress = const PathProgress();
  bool _readOnly = false;

  PathProgress get progress => _progress;

  Future<void> load() async {
    try {
      _progress =
          await _file.read(PathProgress.fromJson) ?? const PathProgress();
    } on FileSystemException catch (e) {
      debugPrint('Lettura del percorso non riuscita: $e');
      _readOnly = true;
    }
    notifyListeners();
  }

  Future<void> complete(Stage stage, int stars, Duration duration) async {
    await replace(_progress.complete(stage.id, stars));
    await recordActivity?.call(LessonCompleted(duration: duration));
  }

  Future<void> replace(PathProgress progress) async {
    _progress = progress;
    notifyListeners();
    if (_readOnly) return;
    try {
      await _file.write(progress.toJson());
    } on FileSystemException catch (e) {
      debugPrint('Salvataggio del percorso non riuscito: $e');
    }
  }
}
