import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/app_language.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../../tool/src/l10n_merge.dart';
import '../localized_app.dart';

Map<String, String> _messages(String locale) {
  final json = jsonDecode(
    mergeArbs(locale, readSources(Directory('lib/l10n'))[locale]!),
  ) as Map<String, Object?>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@')) e.key: e.value! as String,
  };
}

/// Argomenti reali di un messaggio ICU: i nomi prima di `,` e i semplici
/// `{nome}`, esclusi i rami di `plural` e `select` come `one{...}`.
Set<String> _arguments(String message) => {
  for (final m in RegExp(r'(?<![\w=])\{(\w+)\s*[,}]').allMatches(message))
    m.group(1)!,
};

void main() {
  final it = _messages('it');
  final en = _messages('en');
  final nl = _messages('nl');

  group('olandese', () {
    test('ha tutte le chiavi dell\'italiano, né di più né di meno', () {
      expect(nl.keys.toSet(), it.keys.toSet());
    });

    test('nessun testo vuoto', () {
      for (final e in nl.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
      }
    });

    test('stessi argomenti dell\'italiano in ogni messaggio', () {
      for (final key in it.keys) {
        expect(_arguments(nl[key]!), _arguments(it[key]!), reason: key);
      }
    });

    test('i plurali hanno sempre il ramo other', () {
      var plurals = 0;
      for (final e in nl.entries) {
        if (!e.value.contains(', plural,')) continue;
        plurals++;
        expect(e.value, contains('other{'), reason: e.key);
        expect(en[e.key], contains(', plural,'), reason: e.key);
      }
      expect(plurals, greaterThan(40));
    });

    test('virgolette “…” e mai «…» nei testi', () {
      for (final e in nl.entries) {
        expect(e.value, isNot(contains('«')), reason: e.key);
      }
    });

    test('il generatore la conosce e risolve i testi', () {
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('nl'),
      );
      expect(lookupAppLocalizations(const Locale('nl')).appTitle, 'Rokko');
    });
  });

  test('il telefono in olandese, anche belga, usa la traduzione nl', () {
    const supported = AppLocalizations.supportedLocales;
    expect(
      resolveAppLocale(const [Locale('nl', 'BE')], supported),
      const Locale('nl'),
    );
    expect(AppLanguage.dutch.locale, const Locale('nl'));
    expect(AppLanguage.dutch.nativeName, 'Nederlands');
  });

  group('schermate in olandese', () {
    Future<AppLocalizations> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localizedApp(
          locale: const Locale('nl'),
          home: GamePage(
            settings: SettingsController.defaults(),
            store: MemoryStore(),
            now: () => DateTime(2026, 10, 13, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return lookupAppLocalizations(const Locale('nl'));
    }

    testWidgets('la partita mostra il suggerimento in olandese', (
      tester,
    ) async {
      final l10n = await open(tester);
      expect(find.text(l10n.gameFirstMoveHint), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('il foglio Nuova partita non taglia i testi', (tester) async {
      final l10n = await open(tester);
      await tester.tap(find.text(l10n.gameActionNew));
      await tester.pumpAndSettle();
      expect(find.text(l10n.gameNewTitle), findsOneWidget);
      expect(find.text(l10n.gameMenuFriendTitle), findsOneWidget);
      expect(find.text(l10n.gameQuickStart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
