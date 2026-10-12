import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../summary/week_log.dart';
import 'activity.dart';
import 'challenges.dart';
import 'progress_state.dart';
import 'progress_store.dart';
import 'progress_tracker.dart';
import 'streak_info.dart';

/// Stato della gamification per l'interfaccia, salvato a ogni modifica.
class ProgressController extends ChangeNotifier {
  ProgressController(this._store, {DateTime Function()? clock, this._journal})
    : _clock = clock ?? DateTime.now;

  /// Controller sul file predefinito nella cartella dati dell'app.
  static Future<ProgressController> open() async {
    final dir = await getApplicationSupportDirectory();
    final controller = ProgressController(
      ProgressStore(File('${dir.path}/progress.json')),
      journal: WeekLogStore(File('${dir.path}/week.json')),
    );
    await controller.load();
    return controller;
  }

  final ProgressStore _store;
  final DateTime Function() _clock;
  final WeekLogStore? _journal;
  final _tracker = ProgressTracker();

  ProgressState _state = ProgressState.initial;
  ProgressSettings _settings = const ProgressSettings();

  ProgressState get state => _state;
  ProgressSettings get settings => _settings;

  /// Conteggi degli ultimi giorni per il riepilogo settimanale (RG-16).
  WeekLog get weekLog => _weekLog;
  WeekLog _weekLog = const WeekLog();

  int get streak => _tracker.currentStreak(_state, _clock(), _settings);
  int get freezes => _tracker.currentFreezes(_state, _clock(), _settings);
  int get todayProgress => _tracker.todayProgress(_state, _clock(), _settings);

  /// Spiegazione della serie di oggi: obiettivo, stato, traguardo e rischi.
  StreakInfo get streakInfo => describeStreak(
    streak: streak,
    bestStreak: _state.bestStreak,
    freezes: freezes,
    goal: _settings.goal,
    progress: todayProgress,
    restDayToday: _clock().weekday == _settings.restDay,
  );

  List<(Challenge, int)> get challenges =>
      _tracker.challengeProgress(_state, _clock());
  (Challenge, int) get weeklyChallenge =>
      _tracker.weeklyProgress(_state, _clock());

  /// Vero se il file non si è potuto leggere: per non sovrascrivere i
  /// progressi salvati, si gioca senza salvare.
  bool get readOnly => _readOnly;
  bool _readOnly = false;

  Future<void> load() async {
    try {
      final data = await _store.load();
      _state = data.state;
      _settings = data.settings;
      _readOnly = false;
    } on FileSystemException catch (e) {
      debugPrint('Lettura dei progressi non riuscita: $e');
      _readOnly = true;
    }
    await _loadJournal();
    notifyListeners();
  }

  /// Un diario illeggibile non deve fermare il salvataggio dei progressi.
  Future<void> _loadJournal() async {
    try {
      _weekLog = await _journal?.load() ?? const WeekLog();
    } on FileSystemException catch (e) {
      debugPrint('Lettura del diario non riuscita: $e');
    }
  }

  Future<ProgressUpdate> record(Activity activity) async {
    final update = _tracker.record(_state, activity, _clock(), _settings);
    if (!identical(update.state, _state)) {
      _state = update.state;
      notifyListeners();
      await _save();
    }
    if (_settings.enabled) await _journalize(activity);
    return update;
  }

  Future<void> _journalize(Activity activity) async {
    final next = _weekLog.record(activity, _clock());
    if (identical(next, _weekLog)) return;
    _weekLog = next;
    if (_readOnly) return;
    try {
      await _journal?.save(next);
    } on FileSystemException catch (e) {
      debugPrint('Salvataggio del diario non riuscito: $e');
    }
  }

  Future<void> updateSettings(ProgressSettings settings) async {
    _settings = settings;
    _state = _tracker.refreshGoal(_state, _clock(), settings).state;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    if (_readOnly) return;
    try {
      await _store.save(ProgressData(_state, _settings));
    } on FileSystemException catch (e) {
      // Senza spazio o permessi si continua a giocare con i dati in memoria.
      debugPrint('Salvataggio dei progressi non riuscito: $e');
    }
  }
}
