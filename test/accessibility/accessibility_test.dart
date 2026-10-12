import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/devices.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  Device device = Device.phoneMedium,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  device.apply(tester);
  tester.platformDispatcher
    ..localesTestValue = [const Locale('it')]
    ..textScaleFactorTestValue = textScale
    ..platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const ScacchiApp());
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    group('tema ${brightness.name}', () {
      testWidgets('i comandi hanno un\'etichetta per i lettori di schermo', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pumpApp(tester, brightness: brightness);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('i comandi hanno dimensioni tattili adeguate', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pumpApp(tester, brightness: brightness);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('il testo ha un contrasto sufficiente (WCAG AA)', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pumpApp(tester, brightness: brightness);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    });
  }

  testWidgets('i pulsanti si leggono come pulsanti con il loro nome', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpApp(tester);
    expect(
      tester.getSemantics(find.text('Gira')),
      matchesSemantics(
        label: 'Gira',
        isButton: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  for (final device in Device.phones) {
    testWidgets('testo ingrandito al 200% senza sovrapposizioni '
        'su ${device.name}', (tester) async {
      await _pumpApp(tester, device: device, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  }
}
