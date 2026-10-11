import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('RP-05 italiano predefinito, anche per i testi di sistema', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context).languageCode, 'it');
    expect(MaterialLocalizations.of(context).backButtonTooltip, 'Indietro');
    expect(AppLocalizations.of(context).appTitle, 'Rokko');
  });

  test('RP-05 struttura pronta per altre lingue', () {
    final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode);
    expect(codes, containsAll(['it', 'en']));
    expect(lookupAppLocalizations(const Locale('en')).appTitle, 'Rokko');
  });
}
