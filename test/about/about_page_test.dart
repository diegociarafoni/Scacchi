import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/about/about_page.dart';
import 'package:rokko/about/credits.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/settings/settings_page.dart';

import '../localized_app.dart';
import '../settings/settings_nav.dart';

void main() {
  Future<void> show(WidgetTester tester, {String locale = 'it'}) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(home: const AboutPage(), locale: Locale(locale)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dice licenza, sorgenti e assenza di tracciamento', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('Rokko'), findsWidgets);
    expect(find.textContaining('GPL-3.0'), findsWidgets);
    expect(find.text(sourceCodeUrl), findsOneWidget);
    expect(find.textContaining('Nessun dato'), findsOneWidget);
  });

  testWidgets('in inglese i testi sono tradotti', (tester) async {
    await show(tester, locale: 'en');
    expect(find.text('About'), findsOneWidget);
    expect(find.textContaining('No data'), findsOneWidget);
  });

  testWidgets('copia l\'indirizzo dei sorgenti', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await show(tester);
    await tester.tap(find.byKey(const Key('about-source')));
    await tester.pumpAndSettle();
    expect(copied, sourceCodeUrl);
    expect(find.text('Indirizzo copiato'), findsOneWidget);
  });

  testWidgets('apre la pagina delle licenze del sistema', (tester) async {
    await show(tester);
    await tester.tap(find.byKey(const Key('about-licenses')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('elenca i crediti, compreso il motore', (tester) async {
    await show(tester);
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.textContaining('Stockfish'),
      200,
      scrollable: list,
    );
    expect(find.textContaining('Stockfish'), findsWidgets);
  });

  test('ogni credito ha nome e licenza', () {
    expect(credits, isNotEmpty);
    for (final c in credits) {
      expect(c.name, isNotEmpty);
      expect(c.license, isNotEmpty);
    }
    expect(credits.map((c) => c.name), contains(startsWith('Stockfish')));
  });

  test('i crediti con attribuzione obbligatoria sono quelli di CREDITS.md', () {
    final rows = File('CREDITS.md')
        .readAsLinesSync()
        .where((l) => l.startsWith('|') && l.contains('CC BY'));
    expect(rows, isNotEmpty);
    for (final row in rows) {
      final key = RegExp('"([^"]+)"').firstMatch(row)?.group(1);
      expect(key, isNotNull, reason: row);
      expect(
        credits.any((c) => c.name.startsWith(key!)),
        isTrue,
        reason: '$key manca in lib/about/credits.dart',
      );
    }
  });

  testWidgets('si apre dal menu delle Impostazioni', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: SettingsPage(controller: SettingsController.defaults()),
      ),
    );
    await openSection(tester, SettingsSection.about);
    expect(find.byType(AboutPage), findsOneWidget);
  });
}
