import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../badges/badge_def.dart';
import '../badges/badge_sources.dart';
import '../l10n/app_localizations.dart';
import '../summary/week_log.dart';
import 'activity.dart';
import 'challenges.dart';
import 'progress_state.dart';
import 'progress_store.dart';
import 'progress_tracker.dart';
import 'streak_info.dart';

/// Stato della gamification per l'interfaccia, salvato a ogni modifica.
class ProgressController extends ChangeNotifier {
  ProgressController(
    this._store, {
    DateTime Function()? clock,
    this._journal,
    this._photoFile,
  }) : _clock = clock ?? DateTime.now;

  /// Controller sul file predefinito nella cartella dati dell'app.
  static Future<ProgressController> open() async {
    final dir = await getApplicationSupportDirectory();
    final controller = ProgressController(
      ProgressStore(File('${dir.path}/progress.json')),
      journal: WeekLogStore(File('${dir.path}/week.json')),
      photoFile: File('${dir.path}/avatar_photo.jpg'),
    );
    await controller.load();
    return controller;
  }

  final ProgressStore _store;
  final DateTime Function() _clock;
  final WeekLogStore? _journal;

  /// Foto del profilo (RP-09): un file a parte nella cartella privata
  /// dell'app, fuori da `progress.json` e quindi dal backup.
  final File? _photoFile;
  final _tracker = ProgressTracker();

  ProgressState _state = ProgressState.initial;
  ProgressSettings _settings = const ProgressSettings();

  ProgressState get state => _state;
  ProgressSettings get settings => _settings;

  /// Foto salvata, anche se al momento si mostra un avatar.
  Uint8List? get photo => _photo;
  Uint8List? _photo;

  /// Foto da mostrare come avatar, se scelta.
  Uint8List? get activePhoto => _settings.usePhoto ? _photo : null;

  /// Le scritture della foto si accodano, così «Rimuovi» non scavalca un
  /// salvataggio ancora in corso.
  Future<void> _photoQueue = Future.value();

  /// Badge ottenuti (RG-17) con il giorno in cui sono arrivati.
  Map<String, int> get badges => _state.badges;

  BadgeSources _badgeSources = BadgeSources.empty;

  /// Avanzamenti dei salvataggi di Percorso, finali, maestri e Storia.
  BadgeSources get badgeSources => _badgeSources;

  final _unlocks = StreamController<List<BadgeDef>>.broadcast();

  /// Badge appena ottenuti, un elenco per ogni aggiornamento.
  Stream<List<BadgeDef>> get badgeUnlocks => _unlocks.stream;

  /// Conteggi degli ultimi giorni per il riepilogo settimanale (RG-16).
  WeekLog get weekLog => _weekLog;
  WeekLog _weekLog = const WeekLog();

  int get streak => _tracker.currentStreak(_state, _clock(), _settings);
  int get freezes => _tracker.currentFreezes(_state, _clock(), _settings);
  int get todayProgress => _tracker.todayProgress(_state, _clock(), _settings);

  /// Spiegazione della serie di oggi: obiettivo, stato, traguardo e rischi.
  StreakInfo streakInfo(AppLocalizations l) => describeStreak(
    l,
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
      debugPrint('Lettura dei progressi non riuscita: $e'); // l10n-ok
      _readOnly = true;
    }
    await _loadJournal();
    await _loadPhoto();
    notifyListeners();
  }

  Future<void> _loadPhoto() async {
    try {
      final file = _photoFile;
      _photo = file != null && file.existsSync()
          ? await file.readAsBytes()
          : null;
    } on FileSystemException catch (e) {
      if (kDebugMode) {
        debugPrint('Lettura della foto non riuscita: $e'); // l10n-ok
      }
    }
  }

  /// Imposta la foto; se non si riesce a scrivere la si tiene in memoria.
  Future<void> setPhoto(Uint8List bytes) async {
    _photo = bytes;
    await updateSettings(_settings.copyWith(usePhoto: true));
    await _queuePhotoWrite(() async {
      try {
        await _photoFile?.writeAsBytes(bytes, flush: true);
      } on FileSystemException catch (e) {
        if (kDebugMode) {
          debugPrint('Salvataggio della foto non riuscito: $e'); // l10n-ok
        }
      }
    });
  }

  Future<void> removePhoto() async {
    _photo = null;
    await updateSettings(_settings.copyWith(usePhoto: false));
    await _queuePhotoWrite(() async {
      try {
        final file = _photoFile;
        if (file != null && file.existsSync()) await file.delete();
      } on FileSystemException catch (e) {
        if (kDebugMode) {
          debugPrint('Rimozione della foto non riuscita: $e'); // l10n-ok
        }
      }
    });
  }

  Future<void> _queuePhotoWrite(Future<void> Function() job) =>
      _photoQueue = _photoQueue.then((_) => job()).onError((e, _) {
        if (kDebugMode) debugPrint('Foto del profilo: $e'); // l10n-ok
      });

  /// Un diario illeggibile non deve fermare il salvataggio dei progressi.
  Future<void> _loadJournal() async {
    try {
      _weekLog = await _journal?.load() ?? const WeekLog();
    } on FileSystemException catch (e) {
      if (kDebugMode) {
        debugPrint('Lettura del diario non riuscita: $e'); // l10n-ok
      }
    }
  }

  Future<ProgressUpdate> record(Activity activity) async {
    final update = _tracker.record(
      _state,
      activity,
      _clock(),
      _settings,
      _badgeSources,
    );
    if (!identical(update.state, _state)) {
      final before = _state.badges;
      _state = update.state;
      _announceBadges(before);
      notifyListeners();
      await _save();
    }
    if (_settings.enabled) await _journalize(activity);
    return update;
  }

  /// Gli avanzamenti letti dai salvataggi degli altri archivi; sblocca i badge
  /// già meritati, anche prima dell'introduzione dei badge.
  Future<void> updateBadgeSources(BadgeSources sources) async {
    if (sources == _badgeSources) return;
    _badgeSources = sources;
    final next = _tracker.refreshBadges(_state, _clock(), _settings, sources);
    if (identical(next, _state)) return;
    final before = _state.badges;
    _state = next;
    _announceBadges(before);
    notifyListeners();
    await _save();
  }

  void _announceBadges(Map<String, int> before) {
    final fresh = [
      for (final id in _state.badges.keys)
        if (!before.containsKey(id)) ?badgeById(id),
    ];
    if (fresh.isNotEmpty && !_unlocks.isClosed) _unlocks.add(fresh);
  }

  @override
  void dispose() {
    unawaited(_unlocks.close());
    super.dispose();
  }

  Future<void> _journalize(Activity activity) async {
    final next = _weekLog.record(activity, _clock());
    if (identical(next, _weekLog)) return;
    _weekLog = next;
    if (_readOnly) return;
    try {
      await _journal?.save(next);
    } on FileSystemException catch (e) {
      if (kDebugMode) {
        debugPrint('Salvataggio del diario non riuscito: $e'); // l10n-ok
      }
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
      debugPrint('Salvataggio dei progressi non riuscito: $e'); // l10n-ok
    }
  }
}
