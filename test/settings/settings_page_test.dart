import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/main.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/notation.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;
  late ProgressController progress;
  late SettingsController settings;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('settings_page');
    progress = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => DateTime(2026, 10, 5, 12),
    );
    await progress.load();
    settings = SettingsController.defaults();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester, {bool withProgress = true}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: SettingsPage(
          controller: settings,
          progress: withProgress ? progress : null,
          expanded: SettingsSection.values.toSet(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapChip(WidgetTester tester, String label) async {
    // Modalità, notazione e animazioni sono chip; temi e pezzi, tessere.
    final chip = find.widgetWithText(ChoiceChip, label);
    final target = chip.evaluate().isNotEmpty ? chip : find.text(label);
    if (target.evaluate().isEmpty) await tester.scrollUntilVisible(target, 200);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('RF-76 la notazione delle mosse si sceglie dalle Impostazioni', (
    tester,
  ) async {
    await show(tester);
    expect(settings.value.notation, MoveNotation.figurine);
    await tapChip(tester, 'Italiana (Cf3)');
    expect(settings.value.notation, MoveNotation.italian);
    await tapChip(tester, 'Inglese (Nf3)');
    expect(settings.value.notation, MoveNotation.english);
  });

  testWidgets('RP-04 coordinate fuori dalla scacchiera, solo se visibili', (
    tester,
  ) async {
    await show(tester);
    final toggle = find.byKey(const Key('coordinatesOutside'));
    await tester.scrollUntilVisible(toggle, 200);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.value.coordinatesOutside, isTrue);

    final coordinates = find.text('Coordinate');
    await tester.ensureVisible(coordinates);
    await tester.pumpAndSettle();
    await tester.tap(coordinates);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(toggle).onChanged,
      isNull,
      reason: 'senza coordinate la scelta non ha effetto',
    );
  });

  testWidgets('RP-01 i nuovi pezzi e le nuove scacchiere si scelgono', (
    tester,
  ) async {
    await show(tester);
    await tapChip(tester, 'Castello');
    expect(settings.value.boardTheme, BoardTheme.castello);
    await tapChip(tester, 'Arcano');
    expect(settings.value.pieceSet, PieceStyle.arcano);
  });

  testWidgets('RG-06 un tema bloccato dice come sbloccarlo', (tester) async {
    await show(tester);
    await tapChip(tester, 'Sabbia');
    expect(settings.value.boardTheme, BoardTheme.spazio);
    expect(find.text('Sabbia si sblocca con: Livello 2'), findsOneWidget);

    await tapChip(tester, 'Legno');
    expect(settings.value.boardTheme, BoardTheme.brown);
  });

  testWidgets('RG-06 "Sblocca tutto" rende disponibili temi e pezzi', (
    tester,
  ) async {
    await show(tester);
    final toggle = find.byKey(const Key('unlockAll'));
    await tester.scrollUntilVisible(toggle, 200);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(progress.settings.unlockAll, isTrue);

    await tapChip(tester, 'Celtic');
    expect(settings.value.pieceSet, PieceStyle.celtic);
  });

  testWidgets('senza progressi tutto è disponibile', (tester) async {
    await show(tester, withProgress: false);
    expect(find.byKey(const Key('unlockAll')), findsNothing);
    await tapChip(tester, 'Oro');
    expect(settings.value.boardTheme, BoardTheme.gold);
  });

  testWidgets('con la gamification spenta tutto è disponibile', (tester) async {
    await tester.runAsync(
      () => progress.updateSettings(const ProgressSettings(enabled: false)),
    );
    await show(tester);
    expect(find.byKey(const Key('unlockAll')), findsNothing);
    await tapChip(tester, 'Notte');
    expect(settings.value.boardTheme, BoardTheme.night);
  });

  testWidgets('RP-06 il profilo bambino si attiva dalle Impostazioni', (
    tester,
  ) async {
    await show(tester);
    final toggle = find.byKey(const Key('kidMode'));
    expect(find.text('Profilo bambino'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.value.kidMode, isTrue);
  });

  testWidgets('RP-06 per uscire dal profilo bambino serve un adulto', (
    tester,
  ) async {
    await settings.update(settings.value.copyWith(kidMode: true));
    await show(tester);
    await tester.tap(find.byKey(const Key('kidMode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adultGate')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('adultAnswer')), '1');
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();
    expect(settings.value.kidMode, isTrue);
    expect(find.text('Risposta sbagliata.'), findsOneWidget);

    final question = tester
        .widget<Text>(find.byKey(const Key('adultQuestion')))
        .data!;
    final factors = RegExp(r'(\d+) × (\d+)').firstMatch(question)!;
    final answer = int.parse(factors.group(1)!) * int.parse(factors.group(2)!);
    await tester.enterText(find.byKey(const Key('adultAnswer')), '$answer');
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();
    expect(settings.value.kidMode, isFalse);
  });

  testWidgets('RP-06 annullando la domanda il profilo resta attivo', (
    tester,
  ) async {
    await settings.update(settings.value.copyWith(kidMode: true));
    await show(tester);
    await tester.tap(find.byKey(const Key('kidMode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(settings.value.kidMode, isTrue);
  });

  testWidgets('RP-02 aspetto dell\'app: Sistema predefinito, poi Chiaro', (
    tester,
  ) async {
    await show(tester);
    ChoiceChip chip(String label) =>
        tester.widget(find.widgetWithText(ChoiceChip, label));
    expect(chip('Sistema').selected, isTrue);
    expect(chip('Scuro').selected, isFalse);
    await tapChip(tester, 'Chiaro');
    expect(settings.value.themeMode, ThemeMode.light);
    expect(chip('Chiaro').selected, isTrue);
  });

  testWidgets('RP-02 la scelta in Impostazioni cambia il tema dell\'app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();
    ThemeMode? mode() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    expect(mode(), ThemeMode.system);

    // L'apertura legge i progressi dal disco: serve l'I/O reale.
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Impostazioni'));
      for (
        var i = 0;
        i < 50 && find.byType(SettingsPage).evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    await tapChip(tester, 'Scuro');
    expect(mode(), ThemeMode.dark);
    expect(
      SettingsScope.maybeOf(tester.element(find.byType(SettingsPage)))
          ?.themeMode,
      ThemeMode.dark,
    );
    await tapChip(tester, 'Sistema');
    expect(mode(), ThemeMode.system);
  });
}
