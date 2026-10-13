import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/main.dart';
import 'package:scacchi/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game_actions.dart';
import '../settings/settings_nav.dart';
import '../support/devices.dart';

/// Schermate principali con il testo al 130%: nessun overflow e bersagli di
/// tocco adeguati, su telefono piccolo e medio.
Future<void> _pumpApp(WidgetTester tester, Device device) async {
  device.apply(tester);
  tester.platformDispatcher
    ..localesTestValue = [const Locale('it')]
    ..textScaleFactorTestValue = 1.3;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues({'sound': false});
  await tester.pumpWidget(const ScacchiApp());
  await tester.pumpAndSettle();
}

Future<void> _goTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _check(WidgetTester tester, String screen) async {
  final error = tester.takeException();
  expect(error, isNull, reason: '$screen: overflow');
  await expectLater(
    tester,
    meetsGuideline(androidTapTargetGuideline),
    reason: '$screen: bersagli sotto 48 dp',
  );
  await expectLater(
    tester,
    meetsGuideline(labeledTapTargetGuideline),
    reason: '$screen: comandi senza etichetta',
  );
}

void main() {
  for (final device in [Device.phoneSmall, Device.phoneMedium]) {
    group('testo al 130% su ${device.name}', () {
      testWidgets('schede della barra', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpApp(tester, device);
        await _check(tester, 'Home');
        for (final tab in ['Impara', 'Tu']) {
          await _goTab(tester, tab);
          await _check(tester, tab);
        }
        handle.dispose();
      });

      testWidgets('impostazioni e sue sezioni', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpApp(tester, device);
        await tester.tap(find.byTooltip('Impostazioni'));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('section-profile')), findsOneWidget);
        await _check(tester, 'Impostazioni');
        handle.dispose();
      });

      testWidgets('ogni sezione delle impostazioni', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpApp(tester, device);
        await tester.tap(find.byTooltip('Impostazioni'));
        // I progressi si caricano da file, fuori dal tempo finto dei test.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        for (final section in SettingsSection.values) {
          await openSection(tester, section);
          await _check(tester, 'Sezione ${section.name}');
          await backToMenu(tester);
        }
        handle.dispose();
      });

      testWidgets('Storia', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpApp(tester, device);
        await _goTab(tester, 'Impara');
        await tester.tap(find.text('Storia').first);
        await tester.pumpAndSettle();
        await _check(tester, 'Storia');
        handle.dispose();
      });

      testWidgets('partita e menu ⋮', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpApp(tester, device);
        await openBoard(tester);
        await _check(tester, 'Partita');
        // Nella partita a due il pannello «Altro» non c'è: si apre il menu ⋮.
        final menu = find.byTooltip('Altre azioni');
        expect(menu, findsOneWidget);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await _check(tester, 'Menu della partita');
        handle.dispose();
      });
    });
  }
}
