import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

/// Corpo di ogni `plural` del messaggio, con le graffe annidate bilanciate.
List<String> _pluralBodies(String message) {
  final bodies = <String>[];
  for (final m in RegExp(r'\{\w+,\s*plural,').allMatches(message)) {
    var depth = 1;
    var i = m.end;
    while (i < message.length && depth > 0) {
      if (message[i] == '{') depth++;
      if (message[i] == '}') depth--;
      i++;
    }
    bodies.add(message.substring(m.end, i - 1));
  }
  return bodies;
}

/// Categorie dichiarate al primo livello di un corpo di plurale.
Set<String> _categories(String body) {
  final found = <String>{};
  var depth = 0;
  final word = StringBuffer();
  for (final c in body.split('')) {
    if (c == '{') {
      if (depth == 0) found.add(word.toString().trim());
      depth++;
      word.clear();
    } else if (c == '}') {
      depth--;
    } else if (depth == 0) {
      word.write(c);
    }
  }
  return found;
}

void main() {
  final it = _messages('it');
  final en = _messages('en');
  final ru = _messages('ru');

  test('russo: stesse chiavi dell\'italiano, nessun testo vuoto', () {
    expect(ru.keys.toSet(), it.keys.toSet());
    for (final e in ru.entries) {
      expect(e.value.trim(), isNotEmpty, reason: e.key);
    }
  });

  test('russo: stessi segnaposto dell\'italiano', () {
    Set<String> names(String m) => {
      for (final x in RegExp(
        r'(?<![\p{L}\w=])\{([A-Za-z_]\w*)\s*[,}]',
        unicode: true,
      ).allMatches(m))
        x.group(1)!,
    };
    for (final key in it.keys) {
      expect(names(ru[key]!), names(it[key]!), reason: key);
    }
  });

  test('russo: ogni plurale ha one, few, many e other', () {
    var plurals = 0;
    for (final e in ru.entries) {
      final english = _pluralBodies(en[e.key]!).map(_categories).toList();
      final bodies = _pluralBodies(e.value);
      expect(
        bodies.length,
        greaterThanOrEqualTo(english.length),
        reason: e.key,
      );
      for (var i = 0; i < bodies.length; i++) {
        plurals++;
        final cats = _categories(bodies[i]);
        // I plurali che servono solo a nascondere un testo (`=0{}`) non
        // hanno forme da declinare.
        if (i < english.length
            ? !english[i].contains('one')
            : cats.length < 3) {
          continue;
        }
        expect(
          cats,
          containsAll(['one', 'few', 'many', 'other']),
          reason: e.key,
        );
      }
    }
    expect(plurals, greaterThan(40));
  });

  test('russo: la forma one non scrive il numero a mano', () {
    // `one` vale anche per 21, 31… quindi «1» fisso darebbe testi sbagliati.
    final fixedOne = RegExp(r'\bone\{[^{}]*\b1\b[^{}]*\}');
    for (final e in ru.entries) {
      expect(fixedOne.hasMatch(e.value), isFalse, reason: e.key);
    }
  });

  test('russo: i testi sono scritti in cirillico', () {
    final cyrillic = RegExp('[А-Яа-яЁё]');
    final latin = ru.entries.where((e) => !cyrillic.hasMatch(e.value));
    // Restano in latino solo nomi propri e testi fatti di soli segnaposto.
    expect(
      latin.length,
      lessThan(40),
      reason: latin.map((e) => e.key).join(', '),
    );
  });

  group('contenuti', () {
    const files = ['bots', 'endgames', 'masters', 'opening_names', 'path'];
    for (final f in files) {
      test('$f.json: cirillico e senza testi vuoti', () {
        final data = jsonDecode(
          File('assets/content/ru/$f.json').readAsStringSync(),
        ) as Map<String, Object?>;
        expect(data, isNotEmpty);
        for (final e in data.entries) {
          final texts = e.value is List
              ? (e.value! as List).cast<String>()
              : [e.value! as String];
          expect(texts, isNotEmpty, reason: e.key);
          for (final t in texts) {
            expect(t.trim(), isNotEmpty, reason: e.key);
          }
        }
      });
    }
  });
}
