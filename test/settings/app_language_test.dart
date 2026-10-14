import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/main.dart';
import 'package:rokko/settings/app_language.dart';
import 'package:rokko/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const supported = AppLocalizations.supportedLocales;

  group('lingua del dispositivo', () {
    test('si usa la prima lingua supportata, anche con una regione', () {
      expect(
        resolveAppLocale(const [Locale('en', 'US')], supported),
        const Locale('en'),
      );
      expect(
        resolveAppLocale(const [Locale('fr', 'BE')], supported),
        const Locale('fr'),
      );
      expect(
        resolveAppLocale(const [Locale('it', 'CH')], supported),
        const Locale('it'),
      );
    });

    test('salta le lingue non supportate e ripiega sull\'italiano', () {
      expect(
        resolveAppLocale(const [Locale('ja'), Locale('en')], supported),
        const Locale('en'),
      );
      expect(
        resolveAppLocale(const [Locale('ja')], supported),
        const Locale('it'),
      );
      expect(resolveAppLocale(null, supported), const Locale('it'));
      expect(resolveAppLocale(const [], supported), const Locale('it'));
    });
  });

  group('scelta nelle Impostazioni', () {
    test('predefinita: come il telefono', () {
      expect(AppSettings().language, AppLanguage.system);
      expect(AppLanguage.system.locale, isNull);
      expect(AppLanguage.italian.locale, const Locale('it'));
      expect(AppLanguage.english.locale, const Locale('en'));
      expect(AppLanguage.french.locale, const Locale('fr'));
    });

    test('si salva e si ritrova', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await SettingsController.load();
      await c.update(c.value.copyWith(language: AppLanguage.english));
      await Future<void>.delayed(Duration.zero);
      final again = await SettingsController.load();
      expect(again.value.language, AppLanguage.english);
    });

    test('un valore sconosciuto torna a «come il telefono»', () async {
      SharedPreferences.setMockInitialValues({'language': 'klingon'});
      final c = await SettingsController.load();
      expect(c.value.language, AppLanguage.system);
    });
  });

  group('app', () {
    testWidgets('segue il telefono in inglese', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(RokkoApp(contentLoader: (_) async {}));
      await tester.pumpAndSettle();
      expect(find.text('Learn'), findsWidgets);
      expect(find.text('Impara'), findsNothing);
    });

    testWidgets('un telefono in una lingua non supportata usa l\'italiano', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(RokkoApp(contentLoader: (_) async {}));
      await tester.pumpAndSettle();
      expect(find.text('Impara'), findsWidgets);
    });

    testWidgets('la scelta nelle Impostazioni vince sul telefono', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'language': 'english'});
      tester.platformDispatcher.localesTestValue = const [Locale('it', 'IT')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(RokkoApp(contentLoader: (_) async {}));
      await tester.pumpAndSettle();
      expect(find.text('Impara'), findsNothing);
      expect(find.text('Learn'), findsWidgets);
    });
  });
}
