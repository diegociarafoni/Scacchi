import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/l10n_merge.dart';

String _arb(Map<String, Object?> entries) => jsonEncode(entries);

Map<String, Map<String, String>> _sources() => {
  'it': {
    'a.arb': _arb({
      'x': 'uno',
      '@x': {'description': 'd'},
      'y': 'due',
    }),
    'b.arb': _arb({'z': 'tre'}),
  },
  'en': {
    'a.arb': _arb({'x': 'one', 'y': 'two'}),
    'b.arb': _arb({'z': 'three'}),
  },
  'es': {
    'a.arb': _arb({'x': 'uno'}),
  },
};

void main() {
  group('lingue ancora in lavorazione', () {
    test('mancanze di chiavi e file sono ammesse', () {
      expect(checkLocales(_sources(), tolerant: {'es'}), isEmpty);
    });

    test('senza deroga le mancanze sono errori', () {
      final problems = checkLocales(_sources());
      expect(problems.join('\n'), allOf(contains('es/a.arb'), contains('"y"')));
      expect(problems.join('\n'), contains('b.arb manca in es'));
    });

    test('una chiave in più non esiste in nessuna lingua base: errore', () {
      final sources = _sources();
      sources['es']!['a.arb'] = _arb({'x': 'uno', 'extra': 'no'});
      final problems = checkLocales(sources, tolerant: {'es'});
      expect(problems.join('\n'), contains('"extra"'));
    });

    test('la deroga non vale per le lingue complete', () {
      final sources = _sources();
      sources['en']!.remove('b.arb');
      expect(checkLocales(sources, tolerant: {'es'}), isNotEmpty);
    });
  });

  group('ripiego sull\'inglese', () {
    test(
      'le chiavi mancanti si riempiono dall\'inglese con la loro @chiave',
      () {
        final merged = mergeArbs(
          'es',
          _sources()['es']!,
          fallback: {
            'a.arb': _arb({
              'x': 'one',
              'y': 'two',
              '@y': {'description': 'd'},
            }),
            'b.arb': _arb({'z': 'three'}),
          },
        );
        final json = jsonDecode(merged) as Map<String, Object?>;
        expect(json['x'], 'uno');
        expect(json['y'], 'two');
        expect(json['z'], 'three');
        expect(json['@y'], isA<Map<String, Object?>>());
      },
    );

    test('senza ripiego l\'unione non cambia', () {
      final merged = mergeArbs('es', _sources()['es']!);
      expect((jsonDecode(merged) as Map).keys, ['@@locale', 'x']);
    });
  });

  group('copertura', () {
    test('conta le chiavi presenti rispetto alla lingua base', () {
      final result = coverage(_sources(), base: 'it');
      expect(result['it']!.total, 3);
      expect(result['it']!.translated, 3);
      expect(result['en']!.translated, 3);
      expect(result['es']!.translated, 1);
      expect(result['es']!.percent, closeTo(33.3, 0.1));
    });

    test('le chiavi mancanti sono elencate per file', () {
      final es = coverage(_sources(), base: 'it')['es']!;
      expect(es.missing, {
        'a.arb': ['y'],
        'b.arb': ['z'],
      });
    });
  });

  group('stato delle lingue', () {
    test('legge tool/lingue.json', () {
      final stati = parseLanguageStates(
        '{"it":"base","en":"pronta","es":"in lavorazione","fr":"beta"}',
      );
      expect(stati['fr'], LanguageState.beta);
      expect(tolerantLocales(stati), {'es', 'fr'});
    });

    test('uno stato sconosciuto è un errore', () {
      expect(
        () => parseLanguageStates('{"es":"quasi"}'),
        throwsFormatException,
      );
    });

    test('il file reale dichiara it come base e en come pronta', () {
      final stati = parseLanguageStates(
        File('tool/lingue.json').readAsStringSync(),
      );
      expect(stati['it'], LanguageState.base);
      expect(stati['en'], LanguageState.ready);
    });

    test('le lingue in lib/l10n sono dichiarate in tool/lingue.json', () {
      final stati = parseLanguageStates(
        File('tool/lingue.json').readAsStringSync(),
      );
      final sources = readSources(Directory('lib/l10n'));
      expect(stati.keys, containsAll(sources.keys));
    });
  });
}
