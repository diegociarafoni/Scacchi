import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/settings/settings_page.dart';

/// Apre la pagina di [section] dal menu delle Impostazioni.
Future<void> openSection(WidgetTester tester, SettingsSection section) async {
  final tile = find.byKey(Key('section-${section.name}'));
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

/// Torna al menu dalla pagina di una sezione.
Future<void> backToMenu(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}
