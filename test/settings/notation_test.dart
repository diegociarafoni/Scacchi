import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/settings/notation.dart';

void main() {
  group('RF-76 notazione delle mosse', () {
    test('inglese lascia la SAN com\'è', () {
      expect(formatSan('Nf3', MoveNotation.english), 'Nf3');
      expect(formatSan('exd5', MoveNotation.english), 'exd5');
    });

    test('italiana usa R, D, T, A, C', () {
      const n = MoveNotation.italian;
      expect(formatSan('Nf3', n), 'Cf3');
      expect(formatSan('Bb5+', n), 'Ab5+');
      expect(formatSan('Rxe5', n), 'Txe5');
      expect(formatSan('Qd1', n), 'Dd1');
      expect(formatSan('Kg1', n), 'Rg1');
      expect(formatSan('Nbd7', n), 'Cbd7');
      expect(formatSan('e8=Q#', n), 'e8=D#');
    });

    test('figurativa mette il simbolo del pezzo al posto della lettera', () {
      const n = MoveNotation.figurine;
      expect(formatSan('Nf3', n), '♞f3');
      expect(formatSan('Bb5+', n), '♝b5+');
      expect(formatSan('Rxe5', n), '♜xe5');
      expect(formatSan('Qd1', n), '♛d1');
      expect(formatSan('Kg1', n), '♚g1');
      expect(formatSan('exd5', n), 'exd5');
      expect(formatSan('e8=Q', n), 'e8=♛');
      expect(formatSan('bxa8=N+', n), 'bxa8=♞+');
    });

    test('pedoni, arrocchi e vuoto non cambiano', () {
      for (final n in MoveNotation.values) {
        expect(formatSan('e4', n), 'e4');
        expect(formatSan('O-O', n), 'O-O');
        expect(formatSan('O-O-O+', n), 'O-O-O+');
        expect(formatSan('', n), '');
      }
    });

    test('un testo di mosse converte ogni mossa e lascia i numeri', () {
      expect(
        formatMoveText('1. e4 e5 2. Nf3 Nc6', MoveNotation.italian),
        '1. e4 e5 2. Cf3 Cc6',
      );
      expect(formatMoveText('1. Nf3', MoveNotation.figurine), '1. ♞f3');
    });
  });
}
