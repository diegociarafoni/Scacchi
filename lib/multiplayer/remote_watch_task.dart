import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../l10n/app_localizations.dart';
import 'remote_turn_check.dart';
import 'saved_game.dart';

/// Nome del lavoro periodico e della sua registrazione in WorkManager.
const remoteTaskName = 'rokko.remoteTurn';
const remoteTaskId = 'rokko.remoteTurn.periodic';

/// Punto d'ingresso del lavoro in background (isolate separato).
@pragma('vm:entry-point')
void remoteWatchDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != remoteTaskName) return true;
    try {
      final stillWatching = await checkRemoteGame(
        store: await SavedGameStore.open(),
        notifier: LocalTurnNotifier(),
        log: PrefsNotifiedLog(),
      );
      if (!stillWatching) await Workmanager().cancelByUniqueName(remoteTaskId);
      return true;
    } on Object catch (e) {
      // Si riprova al prossimo giro.
      if (kDebugMode) {
        debugPrint('Controllo in background fallito: $e'); // l10n-ok
      }
      return false;
    }
  });
}

/// Fino a quale mossa si è già avvisato, per partita.
class PrefsNotifiedLog implements NotifiedLog {
  static String _key(String gameId) => 'multiplayer.notified.$gameId';

  @override
  Future<int> read(String gameId) async =>
      (await SharedPreferences.getInstance()).getInt(_key(gameId)) ?? 0;

  @override
  Future<void> write(String gameId, int moves) async =>
      (await SharedPreferences.getInstance()).setInt(_key(gameId), moves);
}

/// Titolo e testo dell'avviso per [turn].
(String, String) turnNotificationText(RemoteTurn turn, AppLocalizations l10n) {
  final san = turn.san;
  return (
    l10n.multiplayerRemoteNotifyTitle,
    turn.over || san == null
        ? l10n.multiplayerRemoteNotifyOver
        : l10n.multiplayerRemoteNotifyBody(san),
  );
}

/// Notifica locale nella lingua del telefono (italiano se non c'è).
class LocalTurnNotifier implements TurnNotifier {
  LocalTurnNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _id = 2;

  static AppLocalizations _l10n() {
    try {
      return lookupAppLocalizations(
        Locale(PlatformDispatcher.instance.locale.languageCode),
      );
    } on Object {
      return lookupAppLocalizations(const Locale('it'));
    }
  }

  @override
  Future<void> notify(RemoteTurn turn) async {
    final l10n = _l10n();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final (title, body) = turnNotificationText(turn, l10n);
    await _plugin.show(
      id: _id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'partite-a-distanza', // l10n-ok
          l10n.multiplayerRemoteNotifyChannel,
          channelDescription: l10n.multiplayerRemoteNotifyChannelDescription,
        ),
      ),
    );
  }
}
