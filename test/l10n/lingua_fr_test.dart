import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/app_language.dart';

import '../../tool/src/l10n_merge.dart';

Map<String, String> _messages(String locale) {
  final json = jsonDecode(
    mergeArbs(locale, readSources(Directory('lib/l10n'))[locale]!),
  ) as Map<String, Object?>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@')) e.key: e.value! as String,
  };
}

/// Argomenti reali di un messaggio ICU, esclusi i rami di `plural` e `select`.
Set<String> _arguments(String message) => {
  for (final m in RegExp(r'(?<![\w=])\{(\w+)\s*[,}]').allMatches(message))
    m.group(1)!,
};

void main() {
  final it = _messages('it');
  final en = _messages('en');
  final fr = _messages('fr');

  group('francese', () {
    test('ha tutte le chiavi dell\'italiano, né di più né di meno', () {
      expect(fr.keys.toSet(), it.keys.toSet());
    });

    test('nessun testo vuoto', () {
      for (final e in fr.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
      }
    });

    test('stessi argomenti dell\'italiano in ogni messaggio', () {
      for (final key in it.keys) {
        expect(_arguments(fr[key]!), _arguments(it[key]!), reason: key);
      }
    });

    test('i plurali hanno one e other, e one non è il numero 1', () {
      var plurals = 0;
      for (final e in fr.entries) {
        if (!en[e.key]!.contains(', plural,')) continue;
        plurals++;
        expect(e.value, contains('other{'), reason: e.key);
        expect(e.value, contains('one{'), reason: e.key);
        // `one` copre anche lo zero: il numero va scritto con il segnaposto.
        expect(e.value, isNot(contains(RegExp(r'one\{1[ }]'))), reason: e.key);
      }
      expect(plurals, greaterThan(40));
    });

    test('la punteggiatura segue le regole tipografiche francesi', () {
      for (final e in fr.entries) {
        expect(
          e.value,
          isNot(contains(RegExp(r'[^\s\u202f][;!?]\s'))),
          reason: e.key,
        );
        expect(e.value, isNot(contains(RegExp(r'\w:\s'))), reason: e.key);
        expect(e.value, isNot(contains('“')), reason: e.key);
      }
    });

    test('il generatore la conosce e risolve i testi', () {
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('fr'),
      );
      expect(lookupAppLocalizations(const Locale('fr')).appTitle, 'Rokko');
    });
  });

  test('il telefono in francese, anche belga, usa la traduzione fr', () {
    expect(
      resolveAppLocale(const [
        Locale('fr', 'BE'),
      ], AppLocalizations.supportedLocales),
      const Locale('fr'),
    );
    expect(AppLanguage.french.nativeName, 'Français');
  });
}
