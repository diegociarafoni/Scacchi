import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/backup/backup_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/minigames/minigames_page.dart';
import 'package:scacchi/settings/app_language.dart';

import '../tool/src/l10n_merge.dart';
import 'localized_app.dart';

Map<String, String> _messages(String locale) {
  final json = jsonDecode(
    mergeArbs(locale, readSources(Directory('lib/l10n'))[locale]!),
  ) as Map<String, Object?>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@')) e.key: e.value! as String,
  };
}

Set<String> _placeholders(String message) => {
  for (final m in RegExp(r'(?<![\w=])\{(\w+)\s*[,}]').allMatches(message))
    m.group(1)!,
};

void main() {
  final en = _messages('en');
  final id = _messages('id');

  group('RP-05 indonesiano', () {
    test('stesse chiavi dell\'inglese', () {
      expect(id.keys.toSet(), en.keys.toSet());
    });

    test('nessuna traduzione vuota', () {
      for (final e in id.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
      }
    });

    test('stessi segnaposto dell\'inglese', () {
      for (final key in en.keys) {
        expect(_placeholders(id[key]!), _placeholders(en[key]!), reason: key);
      }
    });

    test('i plurali hanno i rami one e other come l\'inglese', () {
      for (final e in en.entries.where((e) => e.value.contains(', plural,'))) {
        final text = id[e.key]!;
        expect(text, contains(', plural,'), reason: e.key);
        expect(text, contains('other{'), reason: e.key);
        expect(
          RegExp(r'(?<![\w=])one\{').hasMatch(text),
          RegExp(r'(?<![\w=])one\{').hasMatch(e.value),
          reason: e.key,
        );
      }
    });

    test('la lingua è registrata e supportata', () {
      expect(AppLanguage.indonesian.locale, const Locale('id'));
      expect(AppLanguage.indonesian.nativeName, 'Bahasa Indonesia');
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        contains('id'),
      );
    });
  });

  testWidgets('RP-05 schermate campione in indonesiano', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('id'));
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('id'),
        home: BackupPage(
          directory: () async => Directory.systemTemp,
          preferences: () => const {},
          share: (_, _) async {},
        ),
      ),
    );
    expect(find.text(en['backupTitle'] ?? ''), findsNothing);
    expect(find.text(l10n.backupTitle), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      localizedApp(locale: const Locale('id'), home: const MinigamesPage()),
    );
    expect(find.text(l10n.minigamesTitle), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
