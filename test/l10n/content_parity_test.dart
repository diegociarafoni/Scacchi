import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/content.dart';

import '../../tool/src/content_parity.dart';

/// Lingue dei contenuti che devono coincidere con l'italiano; ogni lingua
/// nuova si aggiunge qui.
const _checked = ['en', 'pt', 'fr', 'es', 'de', 'pl', 'id', 'ru', 'nl', 'tr'];

/// File che una lingua non deve avere: in inglese i nomi delle aperture sono
/// quelli del libro, quindi `opening_names.json` esiste solo per le lingue che
/// li traducono.
const _notNeeded = {
  'en': {'opening_names.json'},
};

void main() {
  group('confronto dei contenuti', () {
    test('elenca gli id che mancano e quelli in più', () {
      final r = compareContent(
        {'a': 'x', 'b': 'y', 'c': 'z'},
        {'a': 'x', 'd': 'w'},
      );
      expect(r.missing, ['b', 'c']);
      expect(r.extra, ['d']);
      expect(r.isOk, isFalse);
    });

    test('confronta i segnaposto, senza badare all\'ordine', () {
      final r = compareContent(
        {
          'a': 'Muovi {pezzo} {n} volte',
          'b': ['Ciao {nome}', 'Eccomi'],
          'c': 'senza',
        },
        {
          'a': 'Move the {n} {pezzo}',
          'b': ['Hi {altro}', 'Here I am'],
          'c': 'none {n}',
        },
      );
      expect(r.placeholders, ['b', 'c']);
      expect(r.missing, isEmpty);
    });

    test('segnala testi vuoti e tipo diverso (testo contro lista)', () {
      final r = compareContent(
        {
          'a': 'x',
          'b': ['uno'],
          'c': 'z',
        },
        {
          'a': '  ',
          'b': 'uno',
          'c': ['z'],
        },
      );
      expect(r.empty, ['a']);
      expect(r.kind, ['b', 'c']);
    });

    test('una lista vuota o con una frase vuota è vuota', () {
      final r = compareContent(
        {
          'a': ['x'],
          'b': ['y'],
        },
        {
          'a': <String>[],
          'b': ['ok', ''],
        },
      );
      expect(r.empty, ['a', 'b']);
    });

    test('la lista può avere un numero diverso di frasi', () {
      final r = compareContent(
        {
          'a': ['uno', 'due', 'tre'],
        },
        {
          'a': ['one'],
        },
      );
      expect(r.isOk, isTrue);
    });

    test('describe nomina gli id', () {
      final r = compareContent({'a': 'x', 'b': 'y'}, {'a': 'x'});
      expect(r.describe('en/demo.json'), contains('en/demo.json'));
      expect(r.describe('en/demo.json'), contains('manca: b'));
    });
  });

  group('parità dei contenuti con l\'italiano', () {
    final root = Directory('assets/content');
    final italian = Directory('assets/content/it');
    final files = [
      if (italian.existsSync())
        for (final f in italian.listSync().whereType<File>())
          if (f.path.endsWith('.json')) f.uri.pathSegments.last,
    ]..sort();

    Map<String, Object> read(String lang, String file) => ContentText.parse(
      File('${root.path}/$lang/$file').readAsStringSync(),
      '$lang/$file',
    );

    for (final lang in _checked) {
      for (final file in files) {
        if (_notNeeded[lang]?.contains(file) ?? false) continue;
        test('$lang/$file ha gli stessi id e segnaposto di it', () {
          expect(
            File('${root.path}/$lang/$file').existsSync(),
            isTrue,
            reason: '$lang/$file non esiste',
          );
          final report = compareContent(read('it', file), read(lang, file));
          expect(report.isOk, isTrue, reason: report.describe('$lang/$file'));
        });
      }
    }

    test('nessun file di una lingua senza il corrispondente italiano', () {
      if (!root.existsSync()) return;
      for (final dir in root.listSync().whereType<Directory>()) {
        for (final f in dir.listSync().whereType<File>()) {
          final name = f.uri.pathSegments.last;
          if (!name.endsWith('.json')) continue;
          expect(files, contains(name), reason: '${dir.path}/$name');
        }
      }
    });
  });
}
