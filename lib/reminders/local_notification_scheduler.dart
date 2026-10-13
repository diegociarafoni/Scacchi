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

  Future<void> _init() => _initialized ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Il permesso si chiede solo quando l'utente attiva il promemoria.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
      )
      .catchError((Object e, StackTrace st) {
        // Un errore di avvio si riprova alla chiamata successiva.
        _initialized = null;
        Error.throwWithStackTrace(e, st);
      });

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
    // Il canale esiste già con il nome della lingua precedente: ricrearlo con
    // lo stesso id ne aggiorna nome e descrizione.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            'promemoria',
            reminder.channelName,
            description: reminder.channelDescription,
          ),
        );
    await _plugin.zonedSchedule(
      id: _id,
      // Istante assoluto: l'ora locale è già risolta in [Reminder.at].
      scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
      title: reminder.title,
      body: reminder.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'promemoria',
          reminder.channelName,
          channelDescription: reminder.channelDescription,
        ),
        iOS: const DarwinNotificationDetails(),
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
