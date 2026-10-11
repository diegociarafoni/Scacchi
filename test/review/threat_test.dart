import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/review/board_utils.dart';

void main() {
  group('RF-56 posizione a mossa nulla', () {
    test('passa il turno all\'avversario', () {
      final pos = Chess.initial.play(Move.parse('e2e4')!);
      final fen = threatFen(pos)!;
      expect(fen.split(' ')[1], 'w');
      expect(fen.split(' ')[0], pos.fen.split(' ')[0]);
    });

    test('toglie la presa en passant', () {
      // Dopo e2e4 il pedone nero in d4 potrebbe prendere en passant.
      final pos = Chess.fromSetup(
        Setup.parseFen('4k3/8/8/8/3p4/8/4P3/4K3 w - - 0 1'),
      ).play(Move.parse('e2e4')!);
      expect(pos.fen.split(' ')[3], 'e3');
      expect(threatFen(pos)!.split(' ')[3], '-');
    });

    test('non esiste sotto scacco', () {
      final pos = Chess.fromSetup(
        Setup.parseFen('4k3/8/8/8/8/8/4r3/4K3 w - - 0 1'),
      );
      expect(pos.isCheck, isTrue);
      expect(threatFen(pos), isNull);
    });

    test('non esiste a partita finita', () {
      final mate = Chess.fromSetup(
        Setup.parseFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'),
      );
      expect(mate.isGameOver, isTrue);
      expect(threatFen(mate), isNull);
    });
  });
}
