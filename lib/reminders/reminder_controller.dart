import 'dart:async';

import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../progress/progress_controller.dart';
import 'reminder.dart';

/// Tiene il promemoria allineato ai progressi: si riprogramma quando cambiano
/// obiettivo, impostazioni o attività del giorno.
class ReminderController {
  ReminderController(
    this._progress,
    this._scheduler,
    this._l10n, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _progress.addListener(_onProgress);
    // Al ritorno nell'app il giorno può essere cambiato.
    _lifecycle = AppLifecycleListener(onResume: _onProgress);
    unawaited(sync());
  }

  final ProgressController _progress;
  final ReminderScheduler _scheduler;

  /// Lingua dell'app al momento della programmazione.
  final AppLocalizations Function() _l10n;
  final DateTime Function() _clock;
  late final AppLifecycleListener _lifecycle;

  Reminder? _scheduled;

  /// Il primo allineamento applica sempre lo stato, anche per cancellare un
  /// promemoria rimasto da una sessione precedente.
  var _synced = false;
  Future<void> _pending = Future.value();

  void _onProgress() => unawaited(sync());

  /// Attiva il promemoria all'orario [minutes]; `false` senza permesso.
  Future<bool> enable(int minutes) async {
    if (!await _scheduler.requestPermission()) return false;
    await _progress.updateSettings(
      _progress.settings.copyWith(reminder: () => minutes),
    );
    // updateSettings avvisa gli ascoltatori, che hanno già accodato sync().
    await _pending;
    return true;
  }

  Future<void> disable() async {
    await _progress.updateSettings(
      _progress.settings.copyWith(reminder: () => null),
    );
    await _pending;
  }

  /// Calcola il prossimo promemoria e lo programma se è cambiato.
  Future<void> sync() => _pending = _pending.then((_) => _sync());

  Future<void> _sync() async {
    try {
      final s = _progress.settings;
      final next = s.enabled
          ? nextReminder(
              _l10n(),
              now: _clock(),
              minutes: s.reminder,
              goal: s.goal,
              goalReachedToday: _progress.todayProgress >= s.goal.target,
              streak: _progress.streak,
              restDay: s.restDay,
            )
          : null;
      if (_synced && next == _scheduled) return;
      if (next == null) {
        await _scheduler.cancel();
      } else {
        await _scheduler.schedule(next);
      }
      _scheduled = next;
      _synced = true;
    } on Object catch (e) {
      // Si riprova al prossimo cambiamento dei progressi.
      debugPrint('Promemoria non programmato: $e'); // l10n-ok
    }
  }

  void dispose() {
    _progress.removeListener(_onProgress);
    _lifecycle.dispose();
  }
}
