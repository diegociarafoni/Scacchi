import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/docs_check.dart';

const _map = '''
| Cartella | Documenti |
|---|---|
| `lib/game/` | [regole.md](regole.md) |
''';

const _index =
    '[regole.md](regole.md) [mappa-del-codice.md](mappa-del-codice.md)';

List<String> _check(
  Map<String, String> extra, {
  Set<String> files = const {},
  List<String> libDirs = const ['lib/game/'],
}) {
  final docs = {
    'docs/README.md': _index,
    'docs/mappa-del-codice.md': _map,
    'docs/regole.md': '# Regole\n\n## Arrocco lungo\n',
    ...extra,
  };
  return checkDocs(
    docs: docs,
    exists: (p) => docs.containsKey(p) || p == 'lib/game' || files.contains(p),
    libDirs: libDirs,
  );
}

void main() {
  group('ancore dei titoli', () {
    test('come GitHub, con accenti e punteggiatura', () {
      expect(
        headingSlug('Senza hook: `tool/verifica.sh`'),
        'senza-hook-toolverificash',
      );
      expect(headingSlug('Perché sì'), 'perché-sì');
    });

    test('titoli duplicati con suffisso', () {
      expect(headingAnchors('# A\n## A\n```\n# non titolo\n```\n'), {
        'a',
        'a-1',
      });
    });
  });

  test('documentazione coerente', () {
    expect(
      _check(
        {'README.md': '[docs](docs/README.md) [web](https://example.org)'},
        files: {'lib/game/clock.dart', 'lib/game'},
      ),
      isEmpty,
    );
  });

  group('link', () {
    test('file inesistente', () {
      expect(_check({'docs/regole.md': '[x](manca.md)'}), [
        'docs/regole.md:1 link rotto: manca.md',
      ]);
    });

    test('ancora inesistente, nello stesso file o in un altro', () {
      expect(
        _check({
          'docs/regole.md':
              '# Regole\n[ok](#regole) [ko](#arrocco) [altro](README.md#x)',
        }),
        [
          'docs/regole.md:2 ancora inesistente: #arrocco',
          'docs/regole.md:2 ancora inesistente: README.md#x',
        ],
      );
    });

    test('ancora verso un altro documento', () {
      expect(
        _check({
          'docs/mappa-del-codice.md': '$_map\n[a](regole.md#arrocco-lungo)',
        }),
        isEmpty,
      );
    });

    test('fuori dal repository', () {
      expect(_check({'README.md': '[x](../fuori.md)'}), [
        'README.md:1 link fuori dal repository: ../fuori.md',
      ]);
    });

    test('nei blocchi di codice si ignorano', () {
      expect(_check({'docs/regole.md': '```\n[x](manca.md)\n```'}), isEmpty);
    });
  });

  group('percorsi citati', () {
    test('file e riga esistenti', () {
      expect(
        _check(
          {'docs/regole.md': '`lib/game/clock.dart:42` e `lib/game/`'},
          files: {'lib/game/clock.dart', 'lib/game'},
        ),
        isEmpty,
      );
    });

    test('file inesistente', () {
      expect(_check({'docs/regole.md': 'In `lib/game/orologio.dart`.'}), [
        'docs/regole.md:1 percorso inesistente: lib/game/orologio.dart',
      ]);
    });

    test('segnaposto, glob, comandi e radici non controllate', () {
      expect(
        _check({
          'docs/regole.md':
              '`lib/l10n/app_<codice>.arb` `test/**/*.dart` '
              '`flutter test test/x.dart` `build/app.apk` `games.json`',
        }),
        isEmpty,
      );
    });
  });

  test('documento non indicizzato', () {
    expect(_check({'docs/nuovo.md': '# Nuovo'}), [
      "docs/README.md: nuovo.md non è nell'indice",
    ]);
  });

  group('mappa del codice', () {
    test('cartella senza riga', () {
      expect(_check({}, libDirs: ['lib/game/', 'lib/exchange/']), [
        'docs/mappa-del-codice.md: manca la riga per lib/exchange/, '
            'con il documento che la descrive',
      ]);
    });

    test('cartella che non esiste più', () {
      expect(_check({}, libDirs: []), [
        'docs/mappa-del-codice.md: lib/game/ non esiste più in lib/',
      ]);
    });

    test('riga senza documento', () {
      expect(
        _check({'docs/mappa-del-codice.md': '| `lib/game/` | da scrivere |'}),
        ['docs/mappa-del-codice.md:1 lib/game/ senza documento'],
      );
    });

    test('mappa mancante', () {
      final docs = {'docs/README.md': ''};
      expect(
        checkDocs(docs: docs, exists: docs.containsKey, libDirs: const []),
        ['docs/mappa-del-codice.md manca'],
      );
    });
  });
}
