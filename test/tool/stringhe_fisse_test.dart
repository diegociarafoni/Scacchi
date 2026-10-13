import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/fixed_strings.dart';

void main() {
  group('riconoscimento dei testi italiani nel codice', () {
    test('trova una frase italiana tra apici singoli e doppi', () {
      final hits = findFixedStrings(
        "final a = 'Dai scacco matto in una mossa.';\n"
        'final b = "Hai vinto tu, bravissimo!";\n',
      );
      expect(hits.map((h) => h.line), [1, 2]);
      expect(hits.first.text, 'Dai scacco matto in una mossa.');
    });

    test('ignora identificatori, percorsi, FEN e mosse', () {
      expect(
        findFixedStrings(
          "const a = 'queen-mate';\n"
          "const b = 'assets/pieces/noto';\n"
          "const c = '8/8/8/4k3/8/8/8/4K2Q w - - 0 1';\n"
          "const d = 'Nf3';\n"
          "const e = 'lib/l10n';\n",
        ),
        isEmpty,
      );
    });

    test('ignora import, part e commenti', () {
      expect(
        findFixedStrings(
          "import 'package:flutter/material.dart';\n"
          "// 'Dai scacco matto in una mossa.'\n"
          "/// Mostra 'la partita è finita'\n",
        ),
        isEmpty,
      );
    });

    test('il marcatore l10n-ok esclude la riga', () {
      expect(
        findFixedStrings("final s = 'Scacchiera fisica'; // l10n-ok\n"),
        isEmpty,
      );
    });

    test('ignora i testi senza parole italiane', () {
      expect(
        findFixedStrings("final a = 'Stockfish engine ready';\n"),
        isEmpty,
      );
    });

    test('riconosce le lettere accentate in una frase', () {
      expect(findFixedStrings("final a = 'Così non va';\n"), hasLength(1));
    });

    test('conta più testi sulla stessa riga', () {
      expect(
        findFixedStrings(
          "final l = ['Pensaci con calma.', 'Hai vinto tu!'];\n",
        ),
        hasLength(2),
      );
    });
  });

  group('cricchetto sui testi fissi', () {
    test('countByFolder somma per cartella di lib/', () {
      final counts = countByFolder({
        'lib/path/a.dart': "final a = 'Dai scacco matto in una mossa.';",
        'lib/path/b.dart': "final a = 'Hai vinto tu, bravissimo!';",
        'lib/game/c.dart': "final a = 'Pensaci con calma.';",
        'lib/l10n/it/x.dart': "final a = 'Dai scacco matto in una mossa.';",
      });
      expect(counts, {'path': 2, 'game': 1});
    });

    test('regressions: segnala solo le cartelle che salgono', () {
      expect(
        regressions({'path': 3, 'game': 1, 'new': 2}, {'path': 3, 'game': 2}),
        {'new': 2},
      );
      expect(regressions({'path': 4}, {'path': 3}), {'path': 4});
    });

    test('lib/ non supera la base registrata', () {
      final base = (jsonDecode(
        File('tool/stringhe_fisse_base.json').readAsStringSync(),
      ) as Map).cast<String, int>();
      final sources = {
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart'))
            f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
      };
      expect(regressions(countByFolder(sources), base), isEmpty);
    });
  });
}
