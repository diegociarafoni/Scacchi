import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/theme/motion.dart';
import 'package:rokko/theme/sheets.dart';

import '../localized_app.dart';

void main() {
  Future<void> open(WidgetTester tester, {required bool reduce}) async {
    final settings = SettingsController.defaults()..setReduceMotion(reduce);
    await tester.pumpWidget(
      SettingsScope(
        controller: settings,
        child: localizedApp(
          home: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    animationStyle: motionStyle(context),
                    builder: (_) => const AlertDialog(title: Text('Dialogo')),
                  ),
                  child: const Text('dialogo'),
                ),
                TextButton(
                  onPressed: () => showRokkoSheet<void>(
                    context: context,
                    builder: (_) => const Text('Foglio'),
                  ),
                  child: const Text('foglio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('con meno animazioni il dialogo compare subito', (tester) async {
    await open(tester, reduce: true);
    await tester.tap(find.text('dialogo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Dialogo'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('con meno animazioni il foglio compare subito', (tester) async {
    await open(tester, reduce: true);
    await tester.tap(find.text('foglio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final top = tester.getTopLeft(find.text('Foglio')).dy;
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(find.text('Foglio')).dy, top);
  });

  testWidgets('di norma il dialogo si anima', (tester) async {
    await open(tester, reduce: false);
    await tester.tap(find.text('dialogo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Dialogo'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, lessThan(1));
  });

  test('ogni dialogo dell\'app rispetta la riduzione delle animazioni', () {
    final missing = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final text = f.readAsStringSync();
      for (final m in RegExp(r'showDialog<[^>]*>\(').allMatches(text)) {
        final end = (m.end + 120).clamp(0, text.length);
        if (!text.substring(m.end, end).contains('motionStyle')) {
          missing.add(f.path);
        }
      }
    }
    expect(missing, isEmpty);
  });
}
