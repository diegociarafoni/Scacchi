import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder.dart';

/// Promemoria con le notifiche locali di Android e iOS, senza rete.
class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Le notifiche programmate esistono solo su Android e iOS.
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const _id = 1;

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialized;

  Future<void> _init() => _initialized ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // Il permesso si chiede solo quando l'utente attiva il promemoria.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
    ),
  );

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    await _init();
    await _plugin.cancel(id: _id);
    await _plugin.zonedSchedule(
      id: _id,
      // Istante assoluto: l'ora locale è già risolta in [Reminder.at].
      scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
      title: reminder.title,
      body: reminder.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'promemoria',
          'Promemoria giornaliero',
          channelDescription: "Ricorda l'obiettivo del giorno, una volta.",
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Orario approssimato: non serve il permesso per le sveglie esatte.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel() async {
    await _init();
    await _plugin.cancel(id: _id);
  }
}
