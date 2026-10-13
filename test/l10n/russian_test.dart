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

/// Categoria → testo di ogni forma al primo livello di un corpo di plurale.
Map<String, String> _forms(String body) {
  final forms = <String, String>{};
  var depth = 0;
  final word = StringBuffer();
  final text = StringBuffer();
  for (final c in body.split('')) {
    if (c == '{') {
      if (depth > 0) text.write(c);
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth > 0) {
        text.write(c);
      } else {
        forms[word.toString().trim()] = text.toString();
        word.clear();
        text.clear();
      }
    } else if (depth > 0) {
      text.write(c);
    } else {
      word.write(c);
    }
  }
  return forms;
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
      for (final body in _pluralBodies(e.value)) {
        final forms = _forms(body);
        // Un plurale che serve solo a nascondere un testo (`other{}` o `=0{}`) non
        // ha forme da declinare.
        if (forms['other']!.isEmpty || forms['=0'] == '') continue;
        plurals++;
        expect(
          forms.keys,
          containsAll(['one', 'few', 'many', 'other']),
          reason: e.key,
        );
      }
    }
    expect(plurals, greaterThan(40));
  });

  test('russo: la forma one non scrive il numero a mano', () {
    // `one` vale anche per 21, 31… quindi «1» fisso darebbe testi sbagliati.
    for (final e in ru.entries) {
      for (final body in _pluralBodies(e.value)) {
        final one = _forms(body)['one'];
        if (one == null) continue;
        final text = one.replaceAll(RegExp(r'\{[^{}]*\}'), '');
        expect(
          RegExp(r'(?<![\d/])1(?![\d/])').hasMatch(text),
          isFalse,
          reason: e.key,
        );
      }
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
