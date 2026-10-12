import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../progress/activity.dart';
import '../storage/json_file.dart';
import 'masters_progress.dart';

/// Risultati di «Indovina la mossa», salvati a ogni partita conclusa.
class MastersController extends ChangeNotifier {
  MastersController(File file, {this.recordActivity})
    : _file = JsonFile(file, version: 1);

  /// Controller sul file predefinito nella cartella dati dell'app.
  static Future<MastersController> open({
    RecordActivity? recordActivity,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final controller = MastersController(
      File('${dir.path}/masters.json'),
      recordActivity: recordActivity,
    );
    await controller.load();
    return controller;
  }

  final JsonFile _file;

  /// Registra XP e obiettivo la prima volta che una partita è conclusa.
  final RecordActivity? recordActivity;

  MastersProgress _progress = const MastersProgress();
  bool _readOnly = false;

  MastersProgress get progress => _progress;

  Future<void> load() async {
    try {
      _progress =
          await _file.read(MastersProgress.fromJson) ?? const MastersProgress();
    } on FileSystemException catch (e) {
      if (kDebugMode)
        debugPrint('Lettura delle partite dei maestri non riuscita: $e');
      _readOnly = true;
    }
    notifyListeners();
  }

  Future<void> finish(String id, int percent, Duration duration) async {
    final first = _progress.bestPercent(id) == null;
    _progress = _progress.record(id, percent);
    notifyListeners();
    if (!_readOnly) {
      try {
        await _file.write(_progress.toJson());
      } on FileSystemException catch (e) {
        if (kDebugMode)
          debugPrint('Salvataggio delle partite dei maestri non riuscito: $e');
      }
    }
    if (!first) return;
    // L'esito è già salvato: un errore nei progressi non lo deve perdere.
    try {
      await recordActivity?.call(LessonCompleted(duration: duration));
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Attività non registrata: $e');
    }
  }
}
