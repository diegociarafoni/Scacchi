import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/path/path_controller.dart';
import 'package:rokko/path/path_page.dart';
import 'package:rokko/settings/app_language.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/settings/settings_page.dart';
import 'package:rokko/storage/key_value_store.dart';

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
  final es = _messages('es');

  group('spagnolo', () {
    test('ha tutte le chiavi dell\'italiano, né di più né di meno', () {
      expect(es.keys.toSet(), it.keys.toSet());
    });

    test('nessun testo vuoto', () {
      for (final e in es.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
      }
    });

    test('stessi argomenti dell\'italiano in ogni messaggio', () {
      for (final key in it.keys) {
        expect(_arguments(es[key]!), _arguments(it[key]!), reason: key);
      }
    });

    test('i plurali hanno sempre il ramo other', () {
      var plurals = 0;
      for (final e in es.entries) {
        if (!e.value.contains(', plural,')) continue;
        plurals++;
        expect(e.value, contains('other{'), reason: e.key);
        expect(e.value, contains('one{'), reason: e.key);
        expect(en[e.key], contains(', plural,'), reason: e.key);
      }
      expect(plurals, greaterThan(40));
    });

    test(
      'i punti interrogativi ed esclamativi aperti e chiusi vanno in coppia',
      () {
        for (final e in es.entries) {
          final v = e.value;
          expect(
            '¿'.allMatches(v).length,
            '?'.allMatches(v).length,
            reason: e.key,
          );
          expect(
            '¡'.allMatches(v).length,
            '!'.allMatches(v).length,
            reason: e.key,
          );
        }
      },
    );

    test('nessuna virgoletta inglese “…” nei testi', () {
      for (final e in es.entries) {
        expect(e.value, isNot(contains('“')), reason: e.key);
      }
    });

    test('il generatore la conosce e risolve i testi', () {
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('es'),
      );
      expect(lookupAppLocalizations(const Locale('es')).appTitle, 'Rokko');
    });
  });

  test(
    'il telefono in spagnolo, anche latinoamericano, usa la traduzione es',
    () {
      const supported = AppLocalizations.supportedLocales;
      expect(
        resolveAppLocale(const [Locale('es', 'MX')], supported),
        const Locale('es'),
      );
      expect(AppLanguage.spanish.locale, const Locale('es'));
      expect(AppLanguage.spanish.nativeName, 'Español');
    },
  );

  group('schermate in spagnolo', () {
    Future<AppLocalizations> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localizedApp(
          locale: const Locale('es'),
          home: GamePage(
            settings: SettingsController.defaults(),
            store: MemoryStore(),
            now: () => DateTime(2026, 10, 13, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return lookupAppLocalizations(const Locale('es'));
    }

    testWidgets('la partita mostra il suggerimento in spagnolo', (
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

    testWidgets('Ajustes y Camino a tres dimensiones de teléfono', (
      tester,
    ) async {
      final dir = Directory.systemTemp.createTempSync('es_path');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = PathController(File('${dir.path}/path.json'));
      await tester.runAsync(path.load);
      final l10n = lookupAppLocalizations(const Locale('es'));
      for (final size in const [
        Size(320, 640),
        Size(393, 852),
        Size(430, 932),
      ]) {
        tester.view
          ..physicalSize = size * 3
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          localizedApp(
            locale: const Locale('es'),
            home: SettingsPage(controller: SettingsController.defaults()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.settingsTitle), findsWidgets);
        await tester.pumpWidget(
          localizedApp(
            locale: const Locale('es'),
            home: PathPage(controller: path),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.pathTitle), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
