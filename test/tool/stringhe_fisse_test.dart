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

  group('sintassi delle stringhe Dart', () {
    test('legge le sequenze di escape', () {
      final hits = findFixedStrings(r"final a = 'Hai vinto\nla partita';");
      expect(hits.single.text, 'Hai vinto\nla partita');
      expect(
        findFixedStrings(r"final a = 'perch\u00e9 non vai avanti';")
            .single
            .text,
        'perché non vai avanti',
      );
    });

    test('una stringa dentro un\'interpolazione non chiude il testo', () {
      final hits = findFixedStrings(
        r"final a = 'Hai ${n == 1 ? 'mossa' : 'mosse'} da giocare';",
      );
      expect(hits, hasLength(1));
      expect(hits.single.text, contains('da giocare'));
    });

    test('stringhe su più righe e con tre apici', () {
      final hits = findFixedStrings(
        "final a = '''Hai vinto la partita\ned è finita.''';\n"
        "final b = 'Pensaci con '\n    'calma e attenzione.';\n",
      );
      expect(hits.map((h) => h.line), [1, 3, 4]);
    });

    test('le stringhe raw non interpretano il backslash', () {
      expect(
        findFixedStrings(r"final a = r'Hai vinto la partita\';"),
        hasLength(1),
      );
    });

    test('ignora i blocchi di commento su più righe', () {
      expect(
        findFixedStrings(
          "/*\n final a = 'Hai vinto la partita';\n*/\nfinal b = 1;\n",
        ),
        isEmpty,
      );
    });

    test('lettere accentate in una frase senza parole note', () {
      expect(
        findFixedStrings(
          "final a = 'Complimenti, trovato l\\'eleganza perfetta già';",
        ),
        hasLength(1),
      );
    });

    test('parole che sono anche inglesi non bastano', () {
      expect(
        findFixedStrings("final a = 'Failed to parse move in game';"),
        isEmpty,
      );
      expect(findFixedStrings("final a = 'Bot level';"), isEmpty);
    });
  });

  group('cricchetto sui testi fissi', () {
    test('i file direttamente in lib/ contano', () {
      expect(
        countByFolder({'lib/main.dart': "final a = 'Hai vinto la partita';"}),
        {'(radice)': 1},
      );
    });

    test('improvements: cartelle scese sotto la base', () {
      expect(
        improvements({'path': 3, 'game': 2}, {'path': 5, 'game': 2, 'old': 1}),
        {'path': 3, 'old': 0},
      );
    });

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
      final counts = countByFolder(sources);
      expect(regressions(counts, base), isEmpty);
      expect(
        improvements(counts, base),
        isEmpty,
        reason: 'abbassa la base con: dart tool/stringhe_fisse.dart --aggiorna',
      );
    });
  });
}
