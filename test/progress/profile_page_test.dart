import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/avatar.dart';
import 'package:scacchi/progress/daily_goal.dart';
import 'package:scacchi/progress/profile_page.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_feedback.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/reminders/reminder.dart';
import 'package:scacchi/reminders/reminder_controller.dart';

class _Scheduler implements ReminderScheduler {
  bool permission = true;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> schedule(Reminder reminder) async {}

  @override
  Future<void> cancel() async {}
}

void main() {
  late Directory dir;
  late ProgressController controller;
  var now = DateTime(2026, 10, 5, 12);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('profile');
    now = DateTime(2026, 10, 5, 12);
    controller = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => now,
    );
    await controller.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    ReminderController? reminders,
    Locale locale = const Locale('it'),
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: ProfilePage(controller: controller, reminders: reminders),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RP-05 il profilo si mostra in inglese', (tester) async {
    await tester.runAsync(
      () => controller.record(const GamePlayed(result: GameResult.win)),
    );
    await show(tester, locale: const Locale('en'));
    expect(find.text('Profile'), findsOneWidget);
    expect(find.textContaining('Level'), findsWidgets);
    expect(find.text('Today\'s challenges'), findsOneWidget);
    expect(find.textContaining('To keep your streak going'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Achievements'), 300);
    expect(find.text('First game'), findsOneWidget);
    expect(find.text('Prima partita'), findsNothing);
  });

  testWidgets('RG-01 mostra livello e XP', (tester) async {
    await tester.runAsync(
      () => controller.record(const GamePlayed(result: GameResult.win)),
    );
    await show(tester);
    expect(find.text('Livello 1'), findsOneWidget);
    expect(find.text('${controller.state.xp} / 100 XP'), findsOneWidget);
  });

  testWidgets('RG-02 mostra serie e obiettivo del giorno', (tester) async {
    await tester.runAsync(
      () => controller.record(const GamePlayed(result: GameResult.loss)),
    );
    await show(tester);
    expect(find.text('1 giorno di fila'), findsOneWidget);
    expect(find.text('Obiettivo raggiunto: 1 / 1 partite'), findsOneWidget);
  });

  testWidgets('la serie spiega cosa serve, oggi, traguardo e rischi', (
    tester,
  ) async {
    await show(tester);
    expect(
      find.text('Per tenere accesa la serie, ogni giorno: gioca 1 partita.'),
      findsOneWidget,
    );
    expect(find.text('Oggi: da fare. Manca 1 partita.'), findsOneWidget);
    expect(
      find.text('Prossimo traguardo: 3 giorni di fila (ne mancano 3).'),
      findsOneWidget,
    );
    expect(
      find.text('Raggiungi l\'obiettivo oggi per iniziare una serie.'),
      findsOneWidget,
    );
    await tester.runAsync(
      () => controller.record(const GamePlayed(result: GameResult.loss)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Oggi: fatto. La serie è al sicuro fino a domani.'),
      findsOneWidget,
    );
    expect(find.textContaining('Se salti un giorno'), findsOneWidget);
  });

  testWidgets('RG-02 cambia obiettivo e giorno di riposo', (tester) async {
    await show(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('goal')), 200);
    await tester.ensureVisible(find.byKey(const Key('goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 puzzle').last);
    await tester.pumpAndSettle();
    expect(controller.settings.goal, const DailyGoal(GoalKind.puzzles, 5));

    await tester.scrollUntilVisible(find.byKey(const Key('restDay')), 200);
    await tester.ensureVisible(find.byKey(const Key('restDay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('restDay')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lunedì').last);
    await tester.pumpAndSettle();
    expect(controller.settings.restDay, DateTime.monday);
  });

  testWidgets('RG-05 traguardi ottenuti e da ottenere', (tester) async {
    await tester.runAsync(
      () => controller.record(const GamePlayed(result: GameResult.loss)),
    );
    await show(tester);
    await tester.scrollUntilVisible(find.text('Prima partita'), 200);
    await tester.ensureVisible(find.text('Prima partita'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Prima partita, ottenuto')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Prima vittoria, da ottenere')),
      findsOneWidget,
    );
  });

  testWidgets('RG-07 mostra le sfide di oggi e della settimana', (
    tester,
  ) async {
    await show(tester);
    await tester.scrollUntilVisible(find.text('Sfide di oggi'), 200);
    final l = lookupAppLocalizations(const Locale('it'));
    for (final (c, _) in controller.challenges) {
      expect(find.text(c.title(l)), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Sfida della settimana'), 200);
    expect(find.text(controller.weeklyChallenge.$1.title(l)), findsOneWidget);
  });

  testWidgets('RG-08 mostra i record personali', (tester) async {
    await tester.runAsync(
      () => controller.record(
        const GamePlayed(
          result: GameResult.win,
          opponentElo: 1400,
          moveCount: 22,
          checkmate: true,
        ),
      ),
    );
    await show(tester);
    await tester.scrollUntilVisible(find.text('Record personali'), 200);
    await tester.scrollUntilVisible(find.text('Bot più forte battuto'), 200);
    expect(find.text('1400 Elo'), findsOneWidget);
    expect(find.text('22 mosse'), findsOneWidget);
  });

  testWidgets('RG-10 record dei minigiochi con il loro nome', (tester) async {
    await tester.runAsync(
      () => controller.record(
        const MinigameFinished(game: 'coordinate', score: 17),
      ),
    );
    await show(tester);
    await tester.scrollUntilVisible(find.text('Coordinate a tempo'), 200);
    expect(find.text('17'), findsOneWidget);
  });

  testWidgets('RG-06 sceglie avatar e cornice tra quelli sbloccati', (
    tester,
  ) async {
    await show(tester);
    expect(find.bySemanticsLabel(RegExp('Avatar: Pedone')), findsOneWidget);
    await tester.tap(find.byKey(const Key('avatar')));
    await tester.pumpAndSettle();

    expect(find.text('Livello 4'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Torre, ')));
    await tester.pumpAndSettle();
    expect(controller.settings.avatar, Avatar.pawn);

    await tester.tap(find.bySemanticsLabel(RegExp('^Cavallo')));
    await tester.pumpAndSettle();
    expect(controller.settings.avatar, Avatar.knight);
  });

  testWidgets('RG-06 con "Sblocca tutto" ogni cornice è disponibile', (
    tester,
  ) async {
    await tester.runAsync(
      () => controller.updateSettings(
        controller.settings.copyWith(unlockAll: true),
      ),
    );
    await show(tester);
    await tester.tap(find.byKey(const Key('avatar')));
    await tester.pumpAndSettle();
    expect(find.text('Livello 4'), findsNothing);
    await tester.ensureVisible(find.bySemanticsLabel(RegExp('^Oro')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Oro')));
    await tester.pumpAndSettle();
    expect(controller.settings.frame, AvatarFrame.gold);
  });

  testWidgets('RG-11 senza notifiche disponibili il promemoria non compare', (
    tester,
  ) async {
    await show(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('restDay')), 200);
    expect(find.byKey(const Key('reminder')), findsNothing);
  });

  testWidgets('RG-11 attiva il promemoria scegliendo l\'orario', (
    tester,
  ) async {
    final reminders = ReminderController(
      controller,
      _Scheduler(),
      () => lookupAppLocalizations(const Locale('it')),
    );
    addTearDown(reminders.dispose);
    await show(tester, reminders: reminders);
    final toggle = find.byKey(const Key('reminder'));
    await tester.scrollUntilVisible(toggle, 200);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('Orario del promemoria'), findsOneWidget);
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();

    expect(controller.settings.reminder, 19 * 60);
    await tester.scrollUntilVisible(find.byKey(const Key('reminderTime')), 200);
    expect(find.text('19:00'), findsOneWidget);
  });

  testWidgets('RG-11 senza permesso il promemoria resta spento', (
    tester,
  ) async {
    final reminders = ReminderController(
      controller,
      _Scheduler()..permission = false,
      () => lookupAppLocalizations(const Locale('it')),
    );
    addTearDown(reminders.dispose);
    await show(tester, reminders: reminders);
    final toggle = find.byKey(const Key('reminder'));
    await tester.scrollUntilVisible(toggle, 200);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();

    expect(controller.settings.reminder, isNull);
    expect(
      find.text(
        'Senza il permesso per le notifiche il promemoria resta spento.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('RG-12 con la gamification spenta il profilo è nascosto', (
    tester,
  ) async {
    await show(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('enabled')), 200);
    await tester.ensureVisible(find.byKey(const Key('enabled')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enabled')));
    await tester.pumpAndSettle();
    expect(controller.settings.enabled, isFalse);
    expect(find.textContaining('Livello'), findsNothing);
    expect(find.textContaining('di fila'), findsNothing);
  });

  testWidgets('RG-05 notifica in-app dei nuovi traguardi', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final update = await tester.runAsync(
      () => controller.record(const GamePlayed(result: GameResult.win)),
    );
    showProgressFeedback(context, update!);
    await tester.pump();
    expect(find.textContaining('Prima vittoria'), findsOneWidget);
    expect(find.textContaining('+${update.xpGained} XP'), findsOneWidget);
  });

  test('RG-07 RG-08 il messaggio cita sfide e record', () async {
    await controller.record(
      const GamePlayed(result: GameResult.win, opponentElo: 900),
    );
    final update = await controller.record(
      const GamePlayed(result: GameResult.win, opponentElo: 1000),
    );
    final l = lookupAppLocalizations(const Locale('it'));
    final message = progressMessage(update, l)!;
    for (final c in update.challengesCompleted) {
      expect(message, contains('Sfida completata: ${c.title(l)}'));
    }
    expect(message, contains('Nuovo record: bot più forte battuto'));
  });

  test('le impostazioni sopravvivono al riavvio', () async {
    await controller.updateSettings(
      controller.settings.copyWith(goal: const DailyGoal(GoalKind.minutes, 10)),
    );
    final again = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => now,
    );
    await again.load();
    expect(again.settings.goal, const DailyGoal(GoalKind.minutes, 10));
  });

  testWidgets('le impostazioni a testo ingrandito non vanno in overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: ProfilePage(
          controller: controller,
          reminders: ReminderController(
            controller,
            _Scheduler(),
            () => lookupAppLocalizations(const Locale('it')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('reminder')), 300);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final last = tester.getRect(find.byKey(const Key('reminder')));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    // Dopo l'ultima voce resta almeno uno spazio, e ogni voce è alta 48 dp.
    expect(last.bottom, lessThanOrEqualTo(screen.height - 16));
    expect(last.height, greaterThanOrEqualTo(48));
  });
}
