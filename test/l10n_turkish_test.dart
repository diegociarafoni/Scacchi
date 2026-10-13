import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/minigames/minigames_page.dart';

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
  final it = _messages('it');
  final tr = _messages('tr');

  group('turco: completezza dei file', () {
    test('stesse chiavi dell\'italiano', () {
      expect(tr.keys.toSet(), it.keys.toSet());
    });

    test('nessun testo vuoto', () {
      for (final e in tr.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
      }
    });

    test('stessi segnaposto dell\'italiano', () {
      for (final key in it.keys) {
        expect(_placeholders(tr[key]!), _placeholders(it[key]!), reason: key);
      }
    });

    test('ogni plurale ha il ramo other (in turco il singolare basta)', () {
      for (final e in tr.entries.where((e) => e.value.contains('plural,'))) {
        expect(e.value, contains('other{'), reason: e.key);
      }
    });
  });

  testWidgets('turco: una schermata si mostra senza testi italiani', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(locale: const Locale('tr'), home: const MinigamesPage()),
    );
    final l = lookupAppLocalizations(const Locale('tr'));
    expect(find.text(l.minigamesTitle), findsWidgets);
    expect(l.appTitle, 'Rokko');
    expect(find.text('Minigiochi'), findsNothing);
  });
}
