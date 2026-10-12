import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/tablebase/tablebase.dart';
import 'package:scacchi/tablebase/tb_material.dart';
import 'package:scacchi/tablebase/tb_set.dart';
import 'package:scacchi/tablebase/tb_table.dart';

Position _pos(String fen) => Chess.fromSetup(Setup.parseFen(fen));

/// Posizione casuale con il materiale dato, o nulla se non è legale.
Position? _random(Random rng, String name) {
  final material = TbMaterial.parse(name);
  final squares = <int>{};
  int pick() {
    while (true) {
      final s = rng.nextInt(64);
      if (squares.add(s)) return s;
    }
  }

  final pieces = <(int, String)>[
    (pick(), 'K'),
    (pick(), 'k'),
    for (final r in material.white) (pick(), TbRole.letters[r]),
    for (final r in material.black) (pick(), TbRole.letters[r].toLowerCase()),
  ];
  final rows = <String>[];
  for (var rank = 7; rank >= 0; rank--) {
    var row = '';
    var empty = 0;
    for (var file = 0; file < 8; file++) {
      final hit = pieces.where((p) => p.$1 == rank * 8 + file);
      if (hit.isEmpty) {
        empty++;
      } else {
        if (empty > 0) row += '$empty';
        empty = 0;
        row += hit.first.$2;
      }
    }
    if (empty > 0) row += '$empty';
    rows.add(row);
  }
  final turn = rng.nextBool() ? 'w' : 'b';
  try {
    return _pos('${rows.join('/')} $turn - - 0 1');
  } on PositionSetupException {
    return null;
  }
}

void main() {
  final tables = TbSet();
  final tb = Tablebase(tables);

  group('materiale', () {
    test('RF-97 il nome si legge e si scrive uguale', () {
      expect(TbMaterial.parse('KQvKR').name, 'KQvKR');
      expect(TbMaterial.parse('KRNvK').name, 'KRNvK');
      expect(TbMaterial.parse('KvK').pieces, 2);
    });

    test('RF-97 i Bianchi sono il lato più forte dell\'archivio', () {
      expect(TbMaterial.parse('KvKQ').needsSwap, isTrue);
      expect(TbMaterial.parse('KvKQ').canonical.name, 'KQvK');
      expect(TbMaterial.parse('KRvKN').needsSwap, isFalse);
      expect(TbMaterial.parse('KBvKN').needsSwap, isFalse);
      expect(TbMaterial.parse('KNvKB').canonical.name, 'KBvKN');
      expect(TbMaterial.parse('KQvKQ').needsSwap, isFalse);
    });

    test(
      'RF-97 si gestiscono fino a quattro pezzi, senza pedoni contrapposti',
      () {
        expect(TbMaterial.parse('KQvKR').supported, isTrue);
        expect(TbMaterial.parse('KPvK').supported, isTrue);
        expect(TbMaterial.parse('KQRvK').supported, isTrue);
        expect(TbMaterial.parse('KQRvKR').supported, isFalse);
        expect(TbMaterial.parse('KPvKP').supported, isFalse);
        expect(TbMaterial.parse('KQPvK').supported, isFalse);
      },
    );

    test('catture e promozioni portano a materiali più piccoli', () {
      final deps = TbSet.dependencies(TbMaterial.parse('KPvK'))
          .map((m) => m.name)
          .toSet();
      expect(deps, {'KvK', 'KQvK', 'KRvK', 'KBvK', 'KNvK'});
    });
  });

  group('tre pezzi', () {
    setUpAll(() {
      for (final name in ['KQvK', 'KRvK', 'KBvK', 'KNvK', 'KPvK']) {
        tables.ensure(TbMaterial.parse(name));
      }
    });

    int longestWin(String name) {
      var longest = 0;
      for (final v in tables.table(TbMaterial.parse(name))!.values) {
        if (TbValue.isWin(v) && v > longest) longest = v;
      }
      return longest;
    }

    test(
      'RF-97 il matto più lungo con donna è in 10 mosse, con torre in 16',
      () {
        expect(longestWin('KQvK'), 19);
        expect(longestWin('KRvK'), 31);
      },
    );

    test('RF-97 il re e re contro un pezzo minore è sempre patta', () {
      for (final name in ['KBvK', 'KNvK']) {
        final values = tables.table(TbMaterial.parse(name))!.values;
        expect(
          values.every(
            (v) =>
                v == TbValue.illegal ||
                v == TbValue.draw ||
                TbValue.isLoss(v) && v == 0,
          ),
          isTrue,
        );
      }
    });

    test('RF-97 il matto in una mossa è riconosciuto con la mossa giusta', () {
      final pos = _pos('7k/8/6K1/8/8/1Q6/8/8 w - - 0 1');
      final eval = tb.probe(pos)!;
      expect(eval, const TbEvaluation(TbOutcome.win, 1));
      expect(eval.mateInMoves, 1);
      expect(tb.bestMove(pos), Move.parse('b3b8'));
    });

    test('RF-97 una posizione di matto vale sconfitta in zero semimosse', () {
      final pos = _pos('7k/6Q1/6K1/8/8/8/8/8 b - - 0 1');
      expect(pos.isCheckmate, isTrue);
      expect(tb.probe(pos), const TbEvaluation(TbOutcome.loss, 0));
    });

    test('RF-97 lo stallo è patta', () {
      final pos = _pos('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
      expect(pos.isStalemate, isTrue);
      expect(tb.probe(pos), const TbEvaluation(TbOutcome.draw));
    });

    test('RF-97 la mossa migliore evita lo stallo e porta al matto', () {
      final pos = _pos('7k/8/6K1/8/8/8/5Q2/8 w - - 0 1');
      final ranked = tb.rankedMoves(pos);
      expect(ranked.first.evaluation.outcome, TbOutcome.win);
      final stalemate = ranked.firstWhere(
        (m) => pos.playUnchecked(m.move).isStalemate,
      );
      expect(stalemate.evaluation.outcome, TbOutcome.draw);
      expect(ranked.first.evaluation.outcome, TbOutcome.win);
    });

    test(
      'RF-97 re e pedone: la casa chiave vince, il pedone di torre pareggia',
      () {
        expect(
          tb.probe(_pos('4k3/8/4K3/4P3/8/8/8/8 w - - 0 1'))!.outcome,
          TbOutcome.win,
        );
        expect(
          tb.probe(_pos('k7/8/8/8/8/8/P7/K7 w - - 0 1'))!.outcome,
          TbOutcome.draw,
        );
      },
    );

    test('RF-97 la promozione del pedone porta alla donna', () {
      final pos = _pos('8/P7/8/8/8/2k5/8/K7 w - - 0 1');
      expect(tb.probe(pos)!.outcome, TbOutcome.win);
      expect(tb.bestMove(pos)!.toString(), contains('a7'));
    });

    test('RF-97 una posizione specchiata dà lo stesso risultato', () {
      final a = tb.probe(_pos('4k3/8/4K3/4P3/8/8/8/8 w - - 0 1'));
      final b = tb.probe(_pos('3k4/8/3K4/3P4/8/8/8/8 w - - 0 1'));
      expect(a, b);
    });

    test('RF-97 con i colori scambiati vale lo stesso', () {
      final white = tb.probe(_pos('7k/8/6K1/8/8/1Q6/8/8 w - - 0 1'));
      final black = tb.probe(_pos('8/8/1q6/8/8/6k1/8/7K b - - 0 1'));
      expect(black, white);
    });

    test('oltre i quattro pezzi o senza archivio non c\'è risposta', () {
      expect(tb.probe(Chess.initial), isNull);
      expect(Tablebase.covers(Chess.initial), isFalse);
      expect(
        Tablebase(TbSet()).probe(_pos('7k/8/6K1/8/8/1Q6/8/8 w - - 0 1')),
        isNull,
      );
    });
  });

  group('quattro pezzi', () {
    setUpAll(() {
      for (final name in ['KBNvK', 'KQvKR', 'KBBvK', 'KRvKB']) {
        tables.ensure(TbMaterial.parse(name));
      }
    });

    int longestWin(String name) {
      var longest = 0;
      for (final v in tables.table(TbMaterial.parse(name))!.values) {
        if (TbValue.isWin(v) && v > longest) longest = v;
      }
      return longest;
    }

    test('RF-97 le distanze massime coincidono con quelle note', () {
      expect(longestWin('KBNvK'), 65);
      expect(longestWin('KQvKR'), 69);
      expect(longestWin('KBBvK'), 37);
    });

    for (final name in ['KBNvK', 'KQvKR', 'KRvKB']) {
      test('RF-97 $name: ogni valore è coerente con le mosse successive', () {
        final rng = Random(7);
        var checked = 0;
        while (checked < 400) {
          final pos = _random(rng, name);
          if (pos == null) continue;
          final eval = tb.probe(pos);
          if (eval == null) continue;
          checked++;
          final ranked = tb.rankedMoves(pos);
          if (ranked.isEmpty) {
            expect(pos.isCheckmate || pos.isStalemate, isTrue);
            expect(
              eval,
              pos.isCheckmate
                  ? const TbEvaluation(TbOutcome.loss, 0)
                  : const TbEvaluation(TbOutcome.draw),
            );
            continue;
          }
          expect(
            ranked.first.evaluation,
            eval,
            reason: '${pos.fen}: la migliore mossa deve confermare il valore',
          );
          if (eval.outcome == TbOutcome.draw) {
            expect(
              ranked.every((m) => m.evaluation.outcome != TbOutcome.win),
              isTrue,
            );
          }
          if (eval.outcome == TbOutcome.loss) {
            expect(
              ranked.every((m) => m.evaluation.outcome == TbOutcome.loss),
              isTrue,
            );
          }
        }
      });
    }

    test('RF-97 giocando le mosse migliori il matto arriva alla distanza '
        'prevista', () {
      final rng = Random(11);
      var played = 0;
      while (played < 20) {
        final first = _random(rng, 'KBNvK');
        if (first == null) continue;
        var pos = first;
        final start = tb.probe(pos)!;
        if (start.outcome != TbOutcome.win) continue;
        played++;
        var plies = 0;
        while (!pos.isGameOver) {
          pos = pos.playUnchecked(tb.bestMove(pos)!);
          plies++;
          expect(plies, lessThanOrEqualTo(start.plies!));
        }
        expect(pos.isCheckmate, isTrue);
        expect(plies, start.plies);
      }
    });

    test('RF-97 col materiale scambiato i colori non contano', () {
      final rng = Random(3);
      var checked = 0;
      while (checked < 100) {
        final pos = _random(rng, 'KQvKR');
        if (pos == null) continue;
        checked++;
        final rows = pos.board.fen
            .split('/')
            .reversed
            .map(
              (r) => r
                  .split('')
                  .map(
                    (c) => c == c.toUpperCase()
                        ? c.toLowerCase()
                        : c.toUpperCase(),
                  )
                  .join(),
            )
            .join('/');
        final flipped = _pos(
          '$rows ${pos.turn == Side.white ? 'b' : 'w'} - - 0 1',
        );
        expect(tb.probe(flipped), tb.probe(pos), reason: pos.fen);
      }
    });
  });
}
