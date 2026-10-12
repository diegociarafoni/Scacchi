import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/reminders/reminder.dart';
import 'package:scacchi/settings/settings.dart';

import '../localized_app.dart';

class _Scheduler implements ReminderScheduler {
  final scheduled = <Reminder>[];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(Reminder reminder) async => scheduled.add(reminder);

  @override
  Future<void> cancel() async {}
}

void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('you');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    ReminderScheduler? scheduler,
    SettingsController? settings,
  }) async {
    tester.view.physicalSize = const Size(1170, 5000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: settings ?? SettingsController.defaults(),
          progress: () async => progress,
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          reminderScheduler: () => scheduler,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
  }

  testWidgets('la scheda Tu porta a profilo, percorso e altro', (tester) async {
    await show(tester);
    expect(find.text('Livello 1'), findsOneWidget);
    for (final label in [
      'Profilo',
      'Percorso',
      'Minigiochi',
      'Riepilogo settimanale',
      'Statistiche',
      'La tua settimana',
      'Scacchiera fisica',
      'Archivio',
    ]) {
      // La lista è lunga: con caratteri più larghi le ultime voci stanno fuori.
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Minigiochi'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Minigiochi'), findsOneWidget);
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profilo'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Profilo'), findsOneWidget);
  });

  testWidgets('con le notifiche disponibili il profilo offre il promemoria', (
    tester,
  ) async {
    await show(tester, scheduler: _Scheduler());
    await tester.tap(find.text('Profilo'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('reminder')), 200);
    expect(find.byKey(const Key('reminder')), findsOneWidget);
  });

  testWidgets('senza notifiche il promemoria non compare', (tester) async {
    await show(tester);
    await tester.tap(find.text('Profilo'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('restDay')), 200);
    expect(find.byKey(const Key('reminder')), findsNothing);
  });

  testWidgets('RP-06 il profilo bambino semplifica schede e sezioni', (
    tester,
  ) async {
    final settings = SettingsController.defaults();
    await settings.update(settings.value.copyWith(kidMode: true));
    await show(tester, settings: settings);
    expect(find.text('Aperture'), findsNothing);
    for (final label in [
      'Profilo',
      'Percorso',
      'Minigiochi',
      'Riepilogo settimanale',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final label in [
      'Statistiche',
      'La tua settimana',
      'Scacchiera fisica',
      'Archivio',
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }

    await settings.update(settings.value.copyWith(kidMode: false));
    await tester.pumpAndSettle();
    expect(find.text('Aperture'), findsOneWidget);
    expect(find.text('Statistiche'), findsOneWidget);
  });

  testWidgets('RG-16 il riepilogo settimanale si apre dalla scheda Tu', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.text('Riepilogo settimanale'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AppBar, 'Riepilogo settimanale'),
      findsOneWidget,
    );
    expect(
      find.textContaining('il riepilogo si riempie da solo'),
      findsOneWidget,
    );
  });
}
