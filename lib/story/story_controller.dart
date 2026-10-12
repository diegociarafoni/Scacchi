import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/json_file.dart';
import 'story.dart';

/// Stato della storia per l'interfaccia, salvato a ogni passo.
class StoryController extends ChangeNotifier {
  StoryController(File file) : _file = JsonFile(file, version: 1);

  /// Controller sul file predefinito nella cartella dati dell'app.
  static Future<StoryController> open() async {
    final dir = await getApplicationSupportDirectory();
    final controller = StoryController(File('${dir.path}/story.json'));
    await controller.load();
    return controller;
  }

  final JsonFile _file;
  StoryState _state = const StoryState();
  bool _readOnly = false;

  StoryState get state => _state;

  Future<void> load() async {
    try {
      _state = await _file.read(StoryState.fromJson) ?? const StoryState();
    } on FileSystemException catch (e) {
      if (kDebugMode) debugPrint('Lettura della storia non riuscita: $e');
      _readOnly = true;
    }
    notifyListeners();
  }

  /// Registra [count] puzzle risolti al primo tentativo.
  Future<void> puzzlesSolved(StoryChapter chapter, int count) {
    var next = _state;
    for (var i = 0; i < count; i++) {
      next = next.withPuzzleSolved(chapter.id, chapter.puzzleCount);
    }
    return _replace(next);
  }

  Future<void> bossBeaten(StoryChapter chapter) =>
      _replace(_state.withBossBeaten(chapter.id));

  Future<void> _replace(StoryState state) async {
    _state = state;
    notifyListeners();
    if (_readOnly) return;
    try {
      await _file.write(state.toJson());
    } on FileSystemException catch (e) {
      if (kDebugMode) debugPrint('Salvataggio della storia non riuscito: $e');
    }
  }
}
