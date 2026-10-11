import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/settings/settings_page.dart';

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
        home: SettingsPage(
          controller: settings,
          progress: withProgress ? progress : null,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapChip(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(ChoiceChip, label);
    if (chip.evaluate().isEmpty) await tester.scrollUntilVisible(chip, 200);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  testWidgets('RG-06 un tema bloccato dice come sbloccarlo', (tester) async {
    await show(tester);
    await tapChip(tester, 'Sabbia');
    expect(settings.value.boardTheme, BoardTheme.green);
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
}
