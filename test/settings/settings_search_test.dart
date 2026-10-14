import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/settings/settings_page.dart';
import 'package:scacchi/settings/settings_search.dart';

import '../localized_app.dart';
import 'settings_nav.dart';

void main() {
  final it = lookupAppLocalizations(const Locale('it'));

  List<SettingsHit> hits(String query, {bool progress = true}) =>
      settingsHits(it, query, hasProgress: progress);

  group('U6 ricerca nelle impostazioni, indice', () {
    test('trova una voce per titolo e la manda alla sua sezione', () {
      final found = hits('zen');
      expect(found.map((h) => h.title), contains(it.settingsZenMode));
      expect(
        found.firstWhere((h) => h.title == it.settingsZenMode).section,
        SettingsSection.accessibility,
      );
    });

    test('maiuscole e accenti non contano', () {
      expect(hits('MODALITA ZEN'), isNotEmpty);
      expect(
        hits('Modalità zen').map((h) => h.title),
        contains('Modalità zen'),
      );
    });

    test('cerca anche nella descrizione', () {
      expect(hits('catturi').map((h) => h.title), contains(it.settingsHaptics));
    });

    test('più parole devono comparire tutte', () {
      expect(hits('coordinate fuori').map((h) => h.title), [
        it.settingsCoordinatesOutside,
      ]);
      expect(hits('zen nonesiste'), isEmpty);
    });

    test('una ricerca vuota o di soli spazi non dà risultati', () {
      expect(hits(''), isEmpty);
      expect(hits('   '), isEmpty);
    });

    test('ci sono anche le schede dello Stile e le altre sezioni', () {
      expect(
        hits('pezzi').any((h) => h.section == SettingsSection.style),
        isTrue,
      );
      expect(
        hits('bambino').any((h) => h.section == SettingsSection.kid),
        isTrue,
      );
      expect(
        hits('informazioni').any((h) => h.section == SettingsSection.about),
        isTrue,
      );
    });

    test('senza progressi non compaiono profilo, serie e sblocco', () {
      final titles = hits('profilo', progress: false).map((h) => h.title);
      expect(titles, isNot(contains(it.settingsOpenProfile)));
      expect(hits('sblocca', progress: false), isEmpty);
      expect(
        hits('sblocca').map((h) => h.title),
        contains(it.settingsUnlockAll),
      );
    });

    test('ogni voce ha un titolo e una sezione che la contiene', () {
      for (final q in ['a', 'e', 'i', 'o']) {
        for (final h in hits(q)) {
          expect(h.title, isNotEmpty);
          expect(h.sectionTitle, isNotEmpty);
        }
      }
    });
  });

  group('U6 ricerca nelle impostazioni, schermata', () {
    late SettingsController settings;
    setUp(() => settings = SettingsController.defaults());

    Future<void> show(WidgetTester tester, {String locale = 'it'}) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localizedApp(
          locale: Locale(locale),
          home: SettingsPage(controller: settings),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> search(WidgetTester tester, String text) async {
      await tester.enterText(find.byKey(const Key('settingsSearch')), text);
      await tester.pumpAndSettle();
    }

    testWidgets('senza ricerca si vede il menu delle sezioni', (tester) async {
      await show(tester);
      expect(find.byKey(const Key('section-board')), findsOneWidget);
      expect(find.byKey(const Key('settingsSearch')), findsOneWidget);
    });

    testWidgets('digitando compaiono le voci trovate al posto del menu', (
      tester,
    ) async {
      await show(tester);
      await search(tester, 'zen');
      expect(find.byKey(const Key('section-board')), findsNothing);
      expect(find.text(it.settingsZenMode), findsOneWidget);
      expect(find.text(it.settingsSectionAccessibility), findsWidgets);
    });

    testWidgets('toccare un risultato apre la sezione della voce', (
      tester,
    ) async {
      await show(tester);
      await search(tester, 'zen');
      await tester.tap(find.text(it.settingsZenMode));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('zenMode')), findsOneWidget);
    });

    testWidgets('senza risultati lo dice', (tester) async {
      await show(tester);
      await search(tester, 'xyzxyz');
      expect(find.text(it.settingsSearchEmpty), findsOneWidget);
    });

    testWidgets('cancellare la ricerca riporta il menu', (tester) async {
      await show(tester);
      await search(tester, 'zen');
      await tester.tap(find.byTooltip(it.settingsSearchClear));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('section-board')), findsOneWidget);
    });

    testWidgets('tornando dalla sezione la ricerca resta', (tester) async {
      await show(tester);
      await search(tester, 'zen');
      await tester.tap(find.text(it.settingsZenMode));
      await tester.pumpAndSettle();
      await backToMenu(tester);
      expect(find.text(it.settingsZenMode), findsOneWidget);
    });

    testWidgets('in inglese cerca nei testi inglesi', (tester) async {
      await show(tester, locale: 'en');
      final en = lookupAppLocalizations(const Locale('en'));
      await search(tester, 'vibration');
      expect(find.text(en.settingsHaptics), findsOneWidget);
    });
  });
}
