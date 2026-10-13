import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game_actions.dart';
import '../support/board.dart';
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
    await openBoard(tester);
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

  testWidgets('i pezzi catturati si vedono sullo sfondo del tema scuro', (
    tester,
  ) async {
    await _pumpApp(tester, brightness: Brightness.dark);
    await openBoard(tester);
    await playByTaps(tester, ['e2e4', 'd7d5', 'e4d5']);

    // Il pedone nero catturato dal Bianco: nero su sfondo scuro sparirebbe.
    final captured = find.byKey(const ValueKey('captured-black-pawn-0'));
    expect(captured, findsOneWidget);
    final chip = tester.widget<DecoratedBox>(
      find.ancestor(of: captured, matching: find.byType(DecoratedBox)).first,
    );
    final color = (chip.decoration as BoxDecoration).color!;

    // Contrasto minimo 3:1 degli elementi grafici (WCAG 1.4.11) con il nero e
    // con il bianco, i due colori dei pezzi.
    double contrast(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
    }

    expect(contrast(color, Colors.black), greaterThanOrEqualTo(3));
    expect(contrast(color, Colors.white), greaterThanOrEqualTo(3));
  });
}
