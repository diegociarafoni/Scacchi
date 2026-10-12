import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/backup/backup_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/main.dart';
import 'package:scacchi/minigames/minigames_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/src/l10n_merge.dart';
import 'localized_app.dart';

Map<String, String> _messages(String locale) {
  // Dalle sorgenti, non dal file generato (che può essere di un altro ramo).
  final json = jsonDecode(
    mergeArbs(locale, readSources(Directory('lib/l10n'))[locale]!),
  ) as Map<String, Object?>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@')) e.key: e.value! as String,
  };
}

/// Nomi dei segnaposto usati in un messaggio ICU, esclusi i selettori dei
/// plurali come `one{...}`.
Set<String> _placeholders(String message) => {
  for (final m in RegExp(r'(?<![\w=])\{(\w+)\s*[,}]').allMatches(message))
    m.group(1)!,
};

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

  group('RP-05 file di traduzione', () {
    final it = _messages('it');
    final en = _messages('en');

    test('stesse chiavi in italiano e in inglese', () {
      expect(en.keys.toSet(), it.keys.toSet());
      expect(it.length, greaterThan(1));
    });

    test('nessuna traduzione vuota', () {
      for (final messages in [it, en]) {
        for (final e in messages.entries) {
          expect(e.value.trim(), isNotEmpty, reason: e.key);
        }
      }
    });

    test('stessi segnaposto in italiano e in inglese', () {
      for (final key in it.keys) {
        expect(
          _placeholders(en[key] ?? ''),
          _placeholders(it[key]!),
          reason: key,
        );
      }
    });
  });

  testWidgets('RP-05 una schermata migrata si mostra in inglese', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: BackupPage(
          directory: () async => Directory.systemTemp,
          preferences: () => const {},
          share: (_, _) async {},
        ),
      ),
    );
    expect(find.text('Backup and restore'), findsOneWidget);
    expect(find.text('Share the backup'), findsOneWidget);

    await tester.pumpWidget(
      localizedApp(locale: const Locale('en'), home: const MinigamesPage()),
    );
    expect(find.text('Minigames'), findsOneWidget);
    expect(find.text('Timed coordinates'), findsOneWidget);
  });
}
