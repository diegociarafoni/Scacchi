import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/daily_goal.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/reminders/reminder.dart';
import 'package:scacchi/reminders/reminder_controller.dart';

class FakeScheduler implements ReminderScheduler {
  final scheduled = <Reminder>[];
  var cancelled = 0;
  bool permission = true;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> schedule(Reminder reminder) async => scheduled.add(reminder);

  @override
  Future<void> cancel() async => cancelled++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const goal = DailyGoal(GoalKind.games, 1);
  // 2026-10-05 è un lunedì; promemoria alle 19:00.
  const seven = 19 * 60;

  Reminder? next({
    required DateTime now,
    int? at = seven,
    bool reached = false,
    int streak = 0,
    int? restDay,
  }) => nextReminder(
    lookupAppLocalizations(const Locale('it')),
    now: now,
    minutes: at,
    goal: goal,
    goalReachedToday: reached,
    streak: streak,
    restDay: restDay,
  );

  group('RG-11 promemoria del giorno', () {
    test('nessun promemoria di default', () {
      expect(const ProgressSettings().reminder, isNull);
      expect(next(now: DateTime(2026, 10, 5, 9), at: null), isNull);
    });

    test('oggi all\'orario scelto se l\'obiettivo manca', () {
      final r = next(now: DateTime(2026, 10, 5, 9))!;
      expect(r.at, DateTime(2026, 10, 5, 19));
    });

    test('domani se l\'obiettivo di oggi è già raggiunto', () {
      final r = next(now: DateTime(2026, 10, 5, 9), reached: true)!;
      expect(r.at, DateTime(2026, 10, 6, 19));
    });

    test('domani se l\'orario di oggi è passato', () {
      final r = next(now: DateTime(2026, 10, 5, 19))!;
      expect(r.at, DateTime(2026, 10, 6, 19));
    });

    test('un orario a meno di un minuto passa a domani', () {
      final r = next(now: DateTime(2026, 10, 5, 18, 59, 30))!;
      expect(r.at, DateTime(2026, 10, 6, 19));
    });

    test('salta il giorno di riposo', () {
      final r = next(
        now: DateTime(2026, 10, 5, 20),
        restDay: DateTime.tuesday,
      )!;
      expect(r.at, DateTime(2026, 10, 7, 19));
    });

    test('il testo ricorda la serie da continuare', () {
      expect(
        next(now: DateTime(2026, 10, 5, 9), streak: 4)!.body,
        'Serie di 4 giorni: basta 1 partita per continuarla.',
      );
      expect(
        next(now: DateTime(2026, 10, 5, 9))!.body,
        'Obiettivo di oggi: 1 partita.',
      );
    });

    test('non promette una serie che domani sarà interrotta', () {
      expect(
        next(now: DateTime(2026, 10, 5, 20), streak: 4)!.body,
        'Obiettivo di oggi: 1 partita.',
      );
      expect(
        next(now: DateTime(2026, 10, 5, 20), streak: 4, reached: true)!.body,
        'Serie di 4 giorni: basta 1 partita per continuarla.',
      );
    });

    test('ora e minuti si salvano con le impostazioni', () {
      const s = ProgressSettings(reminder: 7 * 60 + 30);
      expect(ProgressSettings.fromJson(s.toJson()), s);
      expect(
        ProgressSettings.fromJson(const ProgressSettings().toJson()).reminder,
        isNull,
      );
    });
  });

  group('ReminderController', () {
    late Directory dir;
    late ProgressController progress;
    late FakeScheduler scheduler;
    late ReminderController controller;
    var now = DateTime(2026, 10, 5, 9);

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('reminders');
      now = DateTime(2026, 10, 5, 9);
      progress = ProgressController(
        ProgressStore(File('${dir.path}/p.json')),
        clock: () => now,
      );
      await progress.load();
      scheduler = FakeScheduler();
      controller = ReminderController(
        progress,
        scheduler,
        () => lookupAppLocalizations(const Locale('it')),
        clock: () => now,
      );
    });
    tearDown(() {
      controller.dispose();
      dir.deleteSync(recursive: true);
    });

    test('all\'avvio programma il promemoria salvato', () async {
      controller.dispose();
      await progress.updateSettings(
        progress.settings.copyWith(reminder: () => seven),
      );
      controller = ReminderController(
        progress,
        scheduler,
        () => lookupAppLocalizations(const Locale('it')),
        clock: () => now,
      );
      await controller.sync();
      expect(scheduler.scheduled.last.at, DateTime(2026, 10, 5, 19));
    });

    test('spento non programma nulla', () async {
      await controller.sync();
      expect(scheduler.scheduled, isEmpty);
    });

    test('attivarlo chiede il permesso e programma', () async {
      expect(await controller.enable(seven), isTrue);
      expect(progress.settings.reminder, seven);
      expect(scheduler.scheduled.last.at, DateTime(2026, 10, 5, 19));
    });

    test(
      'al cambio lingua il promemoria si riprogramma col nuovo testo',
      () async {
        controller.dispose();
        var locale = const Locale('it');
        await progress.updateSettings(
          progress.settings.copyWith(reminder: () => seven),
        );
        controller = ReminderController(
          progress,
          scheduler,
          () => lookupAppLocalizations(locale),
          clock: () => now,
        );
        await controller.sync();
        final before = scheduler.scheduled.last;
        locale = const Locale('en');
        await ReminderController.languageChanged();
        expect(scheduler.scheduled.last.body, isNot(before.body));
      },
    );

    test('senza permesso resta spento', () async {
      scheduler.permission = false;
      expect(await controller.enable(seven), isFalse);
      expect(progress.settings.reminder, isNull);
      expect(scheduler.scheduled, isEmpty);
    });

    test('raggiunto l\'obiettivo, il promemoria passa a domani', () async {
      await controller.enable(seven);
      await progress.record(const GamePlayed(result: GameResult.loss));
      await controller.sync();
      expect(scheduler.scheduled.last.at, DateTime(2026, 10, 6, 19));
    });

    test('non riprogramma se nulla cambia', () async {
      await controller.enable(seven);
      await controller.sync();
      await controller.sync();
      expect(scheduler.scheduled, hasLength(1));
    });

    test('spegnerlo cancella il promemoria', () async {
      await controller.enable(seven);
      await controller.disable();
      expect(progress.settings.reminder, isNull);
      expect(scheduler.cancelled, greaterThan(0));
    });

    test('con la gamification spenta il promemoria si cancella', () async {
      await controller.enable(seven);
      await progress.updateSettings(progress.settings.copyWith(enabled: false));
      await controller.sync();
      expect(scheduler.cancelled, greaterThan(0));
    });
  });
}
