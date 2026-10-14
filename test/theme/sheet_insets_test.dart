import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/about/about_page.dart';
import 'package:scacchi/puzzles/guide_view.dart';
import 'package:scacchi/puzzles/mode_guide.dart';

import '../localized_app.dart';
import '../support/devices.dart';

void main() {
  testWidgets('la scheda a comparsa non finisce sotto i tre tasti', (
    tester,
  ) async {
    Device.phoneSmall.apply(tester, navBar: Device.threeButtonBar);
    await tester.pumpWidget(
      localizedApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPuzzleGuide(context, PuzzleGuide.theme),
              child: const Text('apri'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();

    final button = find.text('Ho capito');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(button).bottom,
      lessThanOrEqualTo(
        Device.phoneSmall.logicalSize.height - Device.threeButtonBar,
      ),
    );
  });

  testWidgets('una lista a tutta pagina scorre fino sopra i tre tasti', (
    tester,
  ) async {
    Device.phoneSmall.apply(tester, navBar: Device.threeButtonBar);
    await tester.pumpWidget(localizedApp(home: const AboutPage()));
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    final last = tester.getRect(find.byType(ListTile).last);
    expect(
      last.bottom,
      lessThanOrEqualTo(
        Device.phoneSmall.logicalSize.height - Device.threeButtonBar,
      ),
    );
  });

  test('ogni scheda a comparsa passa da showRokkoSheet', () {
    final raw = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('theme/sheets.dart')) continue;
      if (f.readAsStringSync().contains('showModalBottomSheet')) {
        raw.add(f.path);
      }
    }
    expect(
      raw,
      isEmpty,
      reason: 'usa showRokkoSheet, che rispetta i tasti di sistema',
    );
  });
}
