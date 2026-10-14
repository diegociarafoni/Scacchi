import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/puzzles/puzzle_session.dart';

import 'fixtures.dart';

void main() {
  group('RF-81 risoluzione di un puzzle', () {
    test('parte dopo la mossa dell\'avversario', () {
      final s = PuzzleSession(hangingQueen);
      expect(s.lastMove, Move.parse('f2g3'));
      expect(s.position.turn, Side.white);
      expect(s.state, PuzzleState.playing);
    });

    test(
      'mossa giusta: risponde l\'avversario e si prosegue fino alla fine',
      () {
        final s = PuzzleSession(hangingQueen);
        expect(s.tryMove(Move.parse('e6e7')!), PuzzleMoveResult.correct);
        expect(s.playReply(), Move.parse('b2b1'));
        expect(s.tryMove(Move.parse('b3c1')!), PuzzleMoveResult.correct);
        expect(s.playReply(), Move.parse('b1c1'));
        expect(s.tryMove(Move.parse('h6c1')!), PuzzleMoveResult.solved);
        expect(s.state, PuzzleState.solved);
        expect(s.firstTry, isTrue);
      },
    );

    test(
      'mossa sbagliata: non viene giocata e il puzzle conta come fallito',
      () {
        final s = PuzzleSession(hangingQueen);
        final before = s.position.fen;
        expect(s.tryMove(Move.parse('h6h7')!), PuzzleMoveResult.wrong);
        expect(s.position.fen, before);
        expect(s.firstTry, isFalse);
        expect(s.tryMove(Move.parse('e6e7')!), PuzzleMoveResult.correct);
      },
    );

    test('accetta un matto alternativo all\'ultima mossa', () {
      final s = PuzzleSession(backRank);
      expect(s.tryMove(Move.parse('b1b8')!), PuzzleMoveResult.solved);
      expect(s.firstTry, isTrue);
    });

    test('riconosce l\'arrocco sia come re-torre sia come re di due case', () {
      expect(
        PuzzleSession(castle).tryMove(Move.parse('e1g1')!),
        PuzzleMoveResult.solved,
      );
      expect(
        PuzzleSession(castle).tryMove(Move.parse('e1h1')!),
        PuzzleMoveResult.solved,
      );
    });

    test('ignora le mosse illegali', () {
      final s = PuzzleSession(hangingQueen);
      expect(s.tryMove(Move.parse('a1a8')!), PuzzleMoveResult.illegal);
      expect(s.firstTry, isTrue);
    });
  });

  group('RF-83 suggerimento e soluzione', () {
    test('il suggerimento indica la casa del pezzo da muovere', () {
      final s = PuzzleSession(hangingQueen);
      expect(s.hint(), Square.e6);
    });

    test('mostrare la soluzione gioca la mossa e fa fallire il puzzle', () {
      final s = PuzzleSession(hangingQueen);
      expect(s.showNextMove(), Move.parse('e6e7'));
      expect(s.firstTry, isFalse);
      s.playReply();
      s.showNextMove();
      s.playReply();
      s.showNextMove();
      expect(s.state, PuzzleState.solved);
    });
  });
}
