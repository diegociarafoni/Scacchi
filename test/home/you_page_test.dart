import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/home/you_page.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/reminders/reminder.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/story/story_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
          story: () async => StoryController(File('${dir.path}/story.json')),
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          reminderScheduler: () => scheduler,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
  }

  testWidgets('la scheda Tu porta a profilo, badge, statistiche e archivio', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('Livello 1'), findsOneWidget);
    for (final label in [
      'Profilo',
      'Badge',
      'Statistiche',
      'La tua settimana',
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
    for (final label in ['Profilo', 'La tua settimana']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final label in ['Badge', 'Statistiche', 'Archivio']) {
      expect(find.text(label), findsNothing, reason: label);
    }

    await settings.update(settings.value.copyWith(kidMode: false));
    await tester.pumpAndSettle();
    expect(find.text('Statistiche'), findsOneWidget);
  });

  testWidgets('RG-16 il riepilogo settimanale si apre dalla scheda Tu', (
    tester,
  ) async {
    await show(tester);
    // La voce può finire sotto la barra di navigazione: la si porta in alto.
    await tester.ensureVisible(find.text('La tua settimana'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
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

  group('scheda Tu solo dati', () {
    // «Gioca» è anche l'etichetta della barra di navigazione.
    Finder inList(String text) =>
        find.descendant(of: find.byType(ListView), matching: find.text(text));
    double top(WidgetTester tester, String text) =>
        tester.getTopLeft(inList(text)).dy;

    testWidgets('un solo gruppo di dati, senza Impara né Gioca', (
      tester,
    ) async {
      await show(tester);
      expect(inList('I miei dati'), findsOneWidget);
      expect(top(tester, 'I miei dati'), lessThan(top(tester, 'Profilo')));
      expect(inList('Impara'), findsNothing);
      for (final moved in [
        'Storia',
        'Finali',
        'Grandi maestri',
        'Tornei',
        'Minigiochi',
        'Scacchiera fisica',
        'Gioca con un amico',
      ]) {
        expect(inList(moved), findsNothing, reason: moved);
      }
    });

    testWidgets('l\'intestazione è annunciata come tale', (tester) async {
      final handle = tester.ensureSemantics();
      await show(tester);
      expect(
        tester.getSemantics(inList('I miei dati')),
        matchesSemantics(label: 'I miei dati', isHeader: true),
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
        lessThan(top(tester, 'I miei dati')),
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
      for (final label in ['Badge', 'Statistiche', 'Profilo']) {
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

    testWidgets('profilo bambino: solo i dati, senza voci per adulti', (
      tester,
    ) async {
      final settings = SettingsController.defaults();
      await settings.update(settings.value.copyWith(kidMode: true));
      await show(tester, settings: settings);
      expect(inList('I miei dati'), findsOneWidget);
      for (final hidden in ['Badge', 'Statistiche', 'Archivio', 'Tornei']) {
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
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.person_outline),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue where you left off'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(YouPage), matching: find.text('Learn')),
        findsNothing,
      );
      expect(find.text('Your data'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
    });
  });

  group('U10 invito a rivedere la prima partita', () {
    Future<void> finishedGame() =>
        GameArchive(File('${dir.path}/games.json')).save(
          SavedGame(
            id: 'g1',
            createdAt: DateTime(2026, 10, 3),
            updatedAt: DateTime(2026, 10, 3),
            white: 'Tu',
            black: 'Bot',
            mode: SavedGame.computer,
            result: '1-0',
            pgn: '1. e4 e5 1-0',
            playerSide: Side.white,
          ),
        );

    // La lettura dell'archivio è I/O vero: va lasciata finire fuori dal tempo finto.
    Future<void> showWithGame(
      WidgetTester tester, {
      SettingsController? settings,
    }) async {
      await tester.runAsync(finishedGame);
      await show(tester, settings: settings);
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('compare con una partita conclusa mai rivista', (tester) async {
      await showWithGame(tester);
      expect(find.text('Rivedi la tua prima partita'), findsOneWidget);
    });

    testWidgets('senza partite concluse non compare', (tester) async {
      await show(tester);
      expect(find.text('Rivedi la tua prima partita'), findsNothing);
    });

    testWidgets('«Non ora» la toglie e non torna', (tester) async {
      await showWithGame(tester);
      await tester.tap(find.text('Non ora'));
      await tester.pumpAndSettle();
      expect(find.text('Rivedi la tua prima partita'), findsNothing);
    });

    testWidgets('nel profilo bambino non compare', (tester) async {
      final settings = SettingsController.defaults();
      await settings.update(settings.value.copyWith(kidMode: true));
      await showWithGame(tester, settings: settings);
      expect(find.text('Rivedi la tua prima partita'), findsNothing);
    });
  });
}
