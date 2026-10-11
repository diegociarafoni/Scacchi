import 'package:flutter/foundation.dart';

import '../progress/daily_goal.dart';

/// Notifica locale programmata per ricordare l'obiettivo giornaliero.
@immutable
class Reminder {
  const Reminder({required this.at, required this.title, required this.body});

  final DateTime at;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.at == at &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(at, title, body);
}

/// Programma al massimo un promemoria alla volta (RG-11).
abstract interface class ReminderScheduler {
  /// Chiede il permesso di mostrare notifiche; `false` se negato.
  Future<bool> requestPermission();

  /// Sostituisce il promemoria programmato con [reminder].
  Future<void> schedule(Reminder reminder);

  Future<void> cancel();
}

/// Prossimo promemoria, `null` se spento. [minutes] è l'orario scelto in
/// minuti dalla mezzanotte. Uno al giorno al massimo: oggi solo se
/// l'obiettivo manca e l'orario non è passato, mai nel giorno di riposo.
Reminder? nextReminder({
  required DateTime now,
  required int? minutes,
  required DailyGoal goal,
  required bool goalReachedToday,
  required int streak,
  required int? restDay,
}) {
  if (minutes == null) return null;
  DateTime on(int dayOffset) =>
      DateTime(now.year, now.month, now.day + dayOffset, 0, minutes);
  var offset = 0;
  // Un minuto di margine: il permesso o la coda possono ritardare la
  // programmazione, e le notifiche nel passato vengono rifiutate.
  if (goalReachedToday || !on(0).isAfter(now.add(const Duration(minutes: 1)))) {
    offset = 1;
  }
  while (on(offset).weekday == restDay) {
    offset++;
  }
  return Reminder(
    at: on(offset),
    title: 'Scacchi',
    // Un promemoria per un giorno futuro con l'obiettivo di oggi mancato
    // troverebbe la serie già interrotta.
    body: streak > 0 && (offset == 0 || goalReachedToday)
        ? 'Serie di ${streak == 1 ? '1 giorno' : '$streak giorni'}: '
              'basta ${goalLabel(goal)} per continuarla.'
        : 'Obiettivo di oggi: ${goalLabel(goal)}.',
  );
}
