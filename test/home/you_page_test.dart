import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/path/path_controller.dart';
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
          path: () async => PathController(File('${dir.path}/path.json')),
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
      'La tua settimana',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final label in ['Statistiche', 'Scacchiera fisica', 'Archivio']) {
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
    await tester.tap(find.text('La tua settimana'));
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

  group('U5 scheda a gruppi', () {
    // «Gioca» è anche l'etichetta della barra di navigazione.
    Finder inList(String text) =>
        find.descendant(of: find.byType(ListView), matching: find.text(text));
    double top(WidgetTester tester, String text) =>
        tester.getTopLeft(inList(text)).dy;

    testWidgets('tre gruppi con intestazione, nell\'ordine Impara-Gioca-Dati', (
      tester,
    ) async {
      await show(tester);
      for (final h in ['Impara', 'Gioca', 'I miei dati']) {
        expect(inList(h), findsOneWidget, reason: h);
      }
      expect(top(tester, 'Impara'), lessThan(top(tester, 'Percorso')));
      expect(top(tester, 'Percorso'), lessThan(top(tester, 'Gioca')));
      expect(top(tester, 'Minigiochi'), lessThan(top(tester, 'I miei dati')));
      expect(top(tester, 'I miei dati'), lessThan(top(tester, 'Profilo')));
    });

    testWidgets('le intestazioni sono annunciate come tali', (tester) async {
      final handle = tester.ensureSemantics();
      await show(tester);
      expect(
        tester.getSemantics(inList('Impara')),
        matchesSemantics(label: 'Impara', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('«Continua da dove eri» propone la prossima tappa', (
      tester,
    ) async {
      await show(tester);
      expect(find.text('Continua da dove eri'), findsOneWidget);
      expect(
        top(tester, 'Continua da dove eri'),
        lessThan(top(tester, 'Impara')),
      );
      await tester.tap(find.text('Continua da dove eri'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Continua da dove eri'), findsNothing);
    });

    testWidgets('le voci hanno tocco da 48 dp e testo al 130% senza overflow', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(tester);
      for (final label in ['Percorso', 'Minigiochi', 'Profilo']) {
        await tester.scrollUntilVisible(
          find.text(label),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final tile = find.ancestor(
          of: find.text(label),
          matching: find.byType(ListTile),
        );
        expect(
          tester.getSize(tile.first).height,
          greaterThanOrEqualTo(48),
          reason: label,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('profilo bambino: gruppi ridotti, senza voci per adulti', (
      tester,
    ) async {
      final settings = SettingsController.defaults();
      await settings.update(settings.value.copyWith(kidMode: true));
      await show(tester, settings: settings);
      for (final h in ['Impara', 'Gioca', 'I miei dati']) {
        expect(inList(h), findsOneWidget, reason: h);
      }
      for (final hidden in ['Statistiche', 'Archivio', 'Tornei']) {
        expect(find.text(hidden), findsNothing, reason: hidden);
      }
    });

    testWidgets('la settimana ha una sola voce e porta al riepilogo', (
      tester,
    ) async {
      await show(tester);
      expect(find.text('Riepilogo settimanale'), findsNothing);
      expect(find.text('La tua settimana'), findsOneWidget);
    });

    testWidgets('in inglese i testi fissi sono tradotti', (tester) async {
      tester.view.physicalSize = const Size(1170, 5000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localizedApp(
          locale: const Locale('en'),
          home: HomeShell(
            settings: SettingsController.defaults(),
            progress: () async => progress,
            path: () async => PathController(File('${dir.path}/path.json')),
            archive: () async => GameArchive(File('${dir.path}/games.json')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Continue where you left off'), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Your data'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
    });
  });
}
