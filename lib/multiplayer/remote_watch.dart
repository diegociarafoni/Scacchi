import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../reminders/local_notification_scheduler.dart';
import 'remote_watch_task.dart';

/// Controllo in background delle partite a distanza: ogni tanto guarda se
/// l'amico ha giocato e, se sì, avvisa con una notifica locale.
abstract interface class RemoteWatch {
  Future<void> enable();
  Future<void> disable();
}

/// Android: WorkManager, con rete disponibile, ogni 15 minuti (il minimo che
/// il sistema concede). Su iOS il sistema non garantisce nulla in
/// background, quindi non si programma: l'avviso arriva solo con l'app aperta.
class BackgroundRemoteWatch implements RemoteWatch {
  const BackgroundRemoteWatch();

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool _initialized = false;

  @override
  Future<void> enable() async {
    if (!supported) return;
    try {
      // Il permesso si chiede qui, quando parte la prima partita a distanza.
      await LocalNotificationScheduler().requestPermission();
      await _init();
      await Workmanager().registerPeriodicTask(
        remoteTaskId,
        remoteTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('Controllo in background non attivato: $e'); // l10n-ok
      }
    }
  }

  @override
  Future<void> disable() async {
    if (!supported) return;
    try {
      await _init();
      await Workmanager().cancelByUniqueName(remoteTaskId);
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('Controllo in background non spento: $e'); // l10n-ok
      }
    }
  }

  static Future<void> _init() async {
    if (_initialized) return;
    await Workmanager().initialize(remoteWatchDispatcher);
    _initialized = true;
  }
}
