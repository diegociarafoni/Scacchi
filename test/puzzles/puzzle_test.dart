import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/puzzles/puzzle.dart';

import 'fixtures.dart';

void main() {
  group('RF-80 formato dei puzzle Lichess', () {
    test('legge id, posizione, mosse, punteggio e temi', () {
      expect(hangingQueen.id, '00008');
      expect(hangingQueen.rating, 1913);
      expect(hangingQueen.moves, hasLength(6));
      expect(hangingQueen.themes, contains('hangingPiece'));
    });

    test('la prima mossa è dell\'avversario: il giocatore muove dopo', () {
      expect(hangingQueen.start.turn, Side.white);
      expect(hangingQueen.playerSide, Side.white);
      expect(hangingQueen.opponentMove, Move.parse('f2g3'));
      expect(hangingQueen.solution.first, Move.parse('e6e7'));
    });

    test('rifiuta righe malformate', () {
      expect(() => Puzzle.parseCsv('x,y'), throwsFormatException);
    });

    test('legge un intero file CSV saltando intestazione e righe vuote', () {
      final list = Puzzle.parseCsvFile(
        'id,fen,moves,rating,themes\n'
        '00008,r6k/pp2r2p/4Rp1Q/3p4/8/1N1P2R1/PqP2bPP/7K b - - 0 24,'
        'f2g3 e6e7 b2b1 b3c1 b1c1 h6c1,1913,crushing\n\n',
      );
      expect(list.single.id, '00008');
    });
  });
}
