import 'dart:async';

import 'package:flutter/foundation.dart';

import '../progress/progress_controller.dart';
import 'reminder.dart';

/// Tiene il promemoria allineato ai progressi: si riprogramma quando cambiano
/// obiettivo, impostazioni o attività del giorno.
class ReminderController {
  ReminderController(
    this._progress,
    this._scheduler, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _progress.addListener(_onProgress);
  }

  final ProgressController _progress;
  final ReminderScheduler _scheduler;
  final DateTime Function() _clock;

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
    await sync();
    return true;
  }

  Future<void> disable() async {
    await _progress.updateSettings(
      _progress.settings.copyWith(reminder: () => null),
    );
    await sync();
  }

  /// Calcola il prossimo promemoria e lo programma se è cambiato.
  Future<void> sync() => _pending = _pending.then((_) => _sync());

  Future<void> _sync() async {
    final s = _progress.settings;
    final next = s.enabled
        ? nextReminder(
            now: _clock(),
            minutes: s.reminder,
            goal: s.goal,
            goalReachedToday: _progress.todayProgress >= s.goal.target,
            streak: _progress.streak,
            restDay: s.restDay,
          )
        : null;
    if (_synced && next == _scheduled) return;
    try {
      if (next == null) {
        await _scheduler.cancel();
      } else {
        await _scheduler.schedule(next);
      }
      _scheduled = next;
      _synced = true;
    } on Object catch (e) {
      // Si riprova al prossimo cambiamento dei progressi.
      debugPrint('Promemoria non programmato: $e');
    }
  }

  void dispose() => _progress.removeListener(_onProgress);
}
