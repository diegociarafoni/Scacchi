import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/settings/settings_page.dart';
import 'package:rokko/storage/key_value_store.dart';

import '../tool/src/l10n_merge.dart';
import 'game/game_qr_test.dart' show tapMove;
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

/// Corpo di ogni `{variabile, plural, ...}` di un messaggio ICU.
Iterable<(String, String)> _pluralBodies(String message) sync* {
  final start = RegExp(r'\{(\w+),\s*plural,');
  for (final m in start.allMatches(message)) {
    var depth = 1;
    var i = m.end;
    while (depth > 0 && i < message.length) {
      final c = message[i++];
      if (c == '{') depth++;
      if (c == '}') depth--;
    }
    yield (m.group(1)!, message.substring(m.end, i - 1));
  }
}

void main() {
  final it = _messages('it');
  final pl = _messages('pl');

  test('il polacco ha le stesse chiavi e nessun testo vuoto', () {
    expect(pl.keys.toSet(), it.keys.toSet());
    for (final e in pl.entries) {
      expect(e.value.trim(), isNotEmpty, reason: e.key);
    }
  });

  test('i segnaposto del polacco coincidono con quelli italiani', () {
    final names = RegExp(r'(?<![\w=])\{(\w+)\s*[,}]');
    for (final key in it.keys) {
      expect(
        {for (final m in names.allMatches(pl[key]!)) m.group(1)},
        {for (final m in names.allMatches(it[key]!)) m.group(1)},
        reason: key,
      );
    }
  });

  test('ogni plurale polacco ha le forme one, few, many e other', () {
    var plurals = 0;
    for (final e in pl.entries) {
      for (final (variable, body) in _pluralBodies(e.value)) {
        plurals++;
        for (final form in ['few', 'many', 'other']) {
          final start = RegExp('(^|\\s)$form\\{').firstMatch(body)!.end;
          expect(
            body.substring(start).contains('{$variable}'),
            isTrue,
            reason: '${e.key}: $form senza {$variable}',
          );
        }
        for (final form in ['one', 'few', 'many', 'other']) {
          expect(
            RegExp('(^|\\s)$form\\{').hasMatch(body),
            isTrue,
            reason: '${e.key}: manca $form',
          );
        }
      }
    }
    expect(plurals, greaterThan(50));
  });

  test('i plurali scelgono la forma giusta (1, 2-4, 5-21, 22)', () {
    final l = lookupAppLocalizations(const Locale('pl'));
    // Le forme sono nelle chiavi: confronto con il testo di ogni categoria.
    String form(int n) => l.progressGoalGames(n);
    final one = form(1);
    final few = form(2);
    final many = form(5);
    expect(form(3), few.replaceFirst('2', '3'));
    expect(form(4), few.replaceFirst('2', '4'));
    expect(form(12), many.replaceFirst('5', '12'));
    expect(form(14), many.replaceFirst('5', '14'));
    expect(form(22), few.replaceFirst('2', '22'));
    expect(form(24), few.replaceFirst('2', '24'));
    expect(form(25), many.replaceFirst('5', '25'));
    expect(form(112), many.replaceFirst('5', '112'));
    expect({one, few, many}.length, 3);
  });

  // Telefono piccolo, medio e grande: nulla deve sforare con le parole lunghe.
  const sizes = {
    'piccolo': Size(720, 1280),
    'medio': Size(1170, 2532),
    'grande': Size(1440, 3120),
  };
  for (final e in sizes.entries) {
    testWidgets('partita e Impostazioni in polacco, telefono ${e.key}', (
      tester,
    ) async {
      tester.view.physicalSize = e.value;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final l = lookupAppLocalizations(const Locale('pl'));

      await tester.pumpWidget(
        localizedApp(
          locale: const Locale('pl'),
          home: GamePage(
            settings: SettingsController.defaults(),
            store: MemoryStore(),
            now: () => DateTime(2026, 10, 13, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l.gameFirstMoveHint), findsOneWidget);
      await tapMove(tester, 'e2e4');
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        localizedApp(
          locale: const Locale('pl'),
          home: SettingsPage(controller: SettingsController.defaults()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l.settingsTitle), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
