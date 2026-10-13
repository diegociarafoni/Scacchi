import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_nav.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('RP-07 la modalità zen è spenta di default e si salva', () async {
    final settings = await SettingsController.load();
    expect(settings.value.zenMode, isFalse);
    await settings.update(settings.value.copyWith(zenMode: true));
    expect((await SettingsController.load()).value.zenMode, isTrue);
    expect(settings.value, isNot(AppSettings()));
  });

  testWidgets('RP-07 la modalità zen si accende dalle Impostazioni', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final settings = SettingsController.defaults();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: SettingsPage(controller: settings),
      ),
    );
    await tester.pumpAndSettle();
    await openSection(tester, SettingsSection.accessibility);
    final toggle = find.byKey(const Key('zenMode'));
    await tester.scrollUntilVisible(toggle, 200);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    expect(find.text('Modalità zen'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.value.zenMode, isTrue);
  });
}
