import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/l10n_merge.dart';

String _arb(Map<String, Object?> entries) => jsonEncode(entries);

void main() {
  group('unione dei file di una lingua', () {
    test('mette @@locale per primo e tiene l\'ordine dei file', () {
      final merged = mergeArbs('it', {
        'b.arb': _arb({
          'beta': 'B',
          '@beta': {'description': 'd'},
        }),
        'a.arb': _arb({'alfa': 'A'}),
      });
      final json = jsonDecode(merged) as Map<String, Object?>;
      expect(json.keys, ['@@locale', 'alfa', 'beta', '@beta']);
      expect(json['@@locale'], 'it');
    });

    test('segnaposto e plurali restano intatti', () {
      final merged = mergeArbs('it', {
        'a.arb': _arb({
          'conta': '{n, plural, one{1 cosa} other{{n} cose}}',
          '@conta': {
            'placeholders': {
              'n': {'type': 'int'},
            },
          },
        }),
      });
      final json = jsonDecode(merged) as Map<String, Object?>;
      expect(json['conta'], '{n, plural, one{1 cosa} other{{n} cose}}');
      expect(json['@conta'], isA<Map<String, Object?>>());
    });

    test('una chiave in due file è un errore con i nomi dei file', () {
      expect(
        () => mergeArbs('it', {
          'a.arb': _arb({'x': '1'}),
          'b.arb': _arb({'x': '2'}),
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'messaggio',
            allOf(contains('"x"'), contains('a.arb'), contains('b.arb')),
          ),
        ),
      );
    });

    test('@@locale dentro un file è un errore', () {
      expect(
        () => mergeArbs('it', {
          'a.arb': _arb({'@@locale': 'it', 'x': '1'}),
        }),
        throwsFormatException,
      );
    });

    test('JSON non valido indica il file', () {
      expect(
        () => mergeArbs('it', {'a.arb': '{'}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'messaggio',
            contains('a.arb'),
          ),
        ),
      );
    });
  });

  group('coerenza tra le lingue', () {
    test('nessun problema se file e chiavi coincidono', () {
      expect(
        checkLocales({
          'it': {
            'a.arb': _arb({'x': '1', '@x': {}}),
          },
          'en': {
            'a.arb': _arb({'x': 'one'}),
          },
        }),
        isEmpty,
      );
    });

    test('segnala i file presenti in una sola lingua', () {
      final problems = checkLocales({
        'it': {
          'a.arb': _arb({'x': '1'}),
          'b.arb': _arb({'y': '1'}),
        },
        'en': {
          'a.arb': _arb({'x': 'one'}),
        },
      });
      expect(problems, hasLength(1));
      expect(problems.single, allOf(contains('b.arb'), contains('en')));
    });

    test('segnala le chiavi diverse nello stesso file', () {
      final problems = checkLocales({
        'it': {
          'a.arb': _arb({'x': '1', 'y': '2'}),
        },
        'en': {
          'a.arb': _arb({'x': 'one', 'z': 'three'}),
        },
      });
      expect(problems.join('\n'), allOf(contains('"y"'), contains('"z"')));
    });
  });

  group('file reali in lib/l10n', () {
    test('le sorgenti sono coerenti e senza duplicati', () {
      final sources = readSources(Directory('lib/l10n'));
      expect(sources.keys, containsAll(['it', 'en']));
      expect(checkLocales(sources), isEmpty);
      for (final entry in sources.entries) {
        expect(() => mergeArbs(entry.key, entry.value), returnsNormally);
      }
    });
  });
}
