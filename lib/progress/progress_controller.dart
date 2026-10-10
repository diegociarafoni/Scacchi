import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'activity.dart';
import 'progress_state.dart';
import 'progress_store.dart';
import 'progress_tracker.dart';

/// Stato della gamification per l'interfaccia, salvato a ogni modifica.
class ProgressController extends ChangeNotifier {
  ProgressController(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Controller sul file predefinito nella cartella dati dell'app.
  static Future<ProgressController> open() async {
    final dir = await getApplicationSupportDirectory();
    final controller = ProgressController(
      ProgressStore(File('${dir.path}/progress.json')),
    );
    await controller.load();
    return controller;
  }

  final ProgressStore _store;
  final DateTime Function() _clock;
  final _tracker = ProgressTracker();

  ProgressState _state = ProgressState.initial;
  ProgressSettings _settings = const ProgressSettings();

  ProgressState get state => _state;
  ProgressSettings get settings => _settings;

  int get streak => _tracker.currentStreak(_state, _clock(), _settings);
  int get freezes => _tracker.currentFreezes(_state, _clock(), _settings);
  int get todayProgress => _tracker.todayProgress(_state, _clock(), _settings);

  Future<void> load() async {
    final data = await _store.load();
    _state = data.state;
    _settings = data.settings;
    notifyListeners();
  }

  Future<ProgressUpdate> record(Activity activity) async {
    final update = _tracker.record(_state, activity, _clock(), _settings);
    if (!identical(update.state, _state)) {
      _state = update.state;
      notifyListeners();
      await _save();
    }
    return update;
  }

  Future<void> updateSettings(ProgressSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _save();
  }

  Future<void> _save() => _store.save(ProgressData(_state, _settings));
}
