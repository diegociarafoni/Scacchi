import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/openings/opening_book.dart';

List<Move> uci(String moves) =>
    moves.split(' ').map((m) => Move.parse(m)!).toList();

void main() {
  const tsv =
      'eco\tname\tuci\n'
      'C20\tKing\'s Pawn Game\te2e4 e7e5\n'
      'C40\tKing\'s Knight Opening\te2e4 e7e5 g1f3\n'
      'C44\tKing\'s Pawn Game: Tayler Opening\te2e4 e7e5 g1f3 b8c6 f1e2\n'
      'C60\tRuy Lopez\te2e4 e7e5 g1f3 b8c6 f1b5\n'
      'C60\tRuy Lopez: Cozio Defense\te2e4 e7e5 g1f3 b8c6 f1b5 g8e7\n'
      'B20\tSicilian Defense\te2e4 c7c5\n'
      'A40\tQueen\'s Pawn Game\td2d4\n';
  final book = OpeningBook.parseTsv(tsv);

  group('RF-90 riconoscimento dell\'apertura', () {
    test('trova il nome della posizione più avanzata del libro', () {
      final o = book.classify(uci('e2e4 e7e5 g1f3 b8c6 f1b5 a7a6 b5a4'));
      expect(o?.name, 'Ruy Lopez');
      expect(o?.eco, 'C60');
    });

    test('riconosce le trasposizioni dalla posizione, non dalle mosse', () {
      // Cf3 prima di e5: stessa posizione dopo 1.e4 e5 2.Cf3.
      final o = book.classify(uci('g1f3 e7e5 e2e4'));
      expect(o?.name, 'King\'s Knight Opening');
    });

    test('nessun nome se la partita non è mai entrata nel libro', () {
      expect(book.classify(uci('a2a3')), isNull);
      expect(book.classify(const []), isNull);
    });

    test('divide famiglia e variante', () {
      final o = book.classify(uci('e2e4 e7e5 g1f3 b8c6 f1b5 g8e7'))!;
      expect(o.family, 'Ruy Lopez');
      expect(o.variation, 'Cozio Defense');
    });
  });

  group('RF-91 mosse di libro', () {
    test('conta le mosse iniziali che restano nel libro', () {
      expect(book.bookPlies(uci('e2e4 e7e5 g1f3 b8c6 f1b5 a7a6')), 5);
      expect(book.bookPlies(uci('e2e4 e7e5 g1f3 b8c6 f1b5 g8e7')), 6);
      expect(book.bookPlies(uci('a2a3 e7e5')), 0);
    });

    test('dopo l\'uscita dal libro non si rientra', () {
      expect(book.bookPlies(uci('e2e4 a7a6 d2d4')), 1);
    });
  });

  group('RF-92 explorer ridotto', () {
    test('elenca le continuazioni con il numero di varianti del libro', () {
      final moves = book.continuations(uci('e2e4 e7e5 g1f3 b8c6'));
      expect(moves.map((c) => c.san), ['Bb5', 'Be2']);
      expect(moves.first.lines, 2);
      expect(moves.first.opening?.name, 'Ruy Lopez');
      expect(moves.first.share, closeTo(2 / 3, 0.001));
    });

    test('dalla posizione iniziale le prime mosse del libro', () {
      final moves = book.continuations(const []);
      expect(moves.first.san, 'e4');
      expect(moves.map((c) => c.san), containsAll(['e4', 'd4']));
    });

    test('nessuna continuazione fuori dal libro', () {
      expect(book.continuations(uci('a2a3')), isEmpty);
    });
  });

  test('accetta file con fine riga Windows', () {
    final crlf = OpeningBook.parseTsv(tsv.replaceAll('\n', '\r\n'));
    expect(crlf.classify(uci('e2e4 c7c5'))?.name, 'Sicilian Defense');
  });

  test('riconosce le aperture anche da posizioni già calcolate', () {
    final positions = OpeningBook.replay(uci('e2e4 c7c5'));
    expect(book.classifyPositions(positions)?.eco, 'B20');
    expect(book.continuationsAt(positions.first).first.san, 'e4');
  });

  test('il dataset incluso è completo e valido', () {
    final real = OpeningBook.parseTsv(
      io.File('assets/openings/openings.tsv').readAsStringSync(),
    );
    expect(real.size, greaterThan(3000));
    expect(
      real
          .classify(uci('e2e4 c7c5 g1f3 d7d6 d2d4 c5d4 f3d4 g8f6 b1c3 a7a6'))
          ?.name,
      'Sicilian Defense: Najdorf Variation',
    );
  });
}
