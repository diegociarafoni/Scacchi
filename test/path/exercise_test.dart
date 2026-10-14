import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/path/exercise.dart';

void main() {
  group('esercizi a stelle', () {
    const rook = StarsExercise(
      role: Role.rook,
      start: Square.a1,
      stars: [Square.a8, Square.h8, Square.h1],
    );

    test('il minimo di mosse si calcola da solo', () {
      expect(rook.optimalMoves, 3);
    });

    test('mosse della torre su scacchiera vuota', () {
      final run = StarsRun(rook);
      expect(run.validMoves, hasLength(14));
      expect(run.validMoves, contains(Square.a8));
      expect(run.validMoves, isNot(contains(Square.b2)));
    });

    test('raccoglie le stelle e finisce', () {
      final run = StarsRun(rook);
      expect(run.move(Square.b2), isFalse);
      expect(run.move(Square.a8), isTrue);
      expect(run.remaining, [Square.h8, Square.h1]);
      run
        ..move(Square.h8)
        ..move(Square.h1);
      expect(run.done, isTrue);
      expect(run.moves, 3);
      expect(run.stars, 3);
    });

    test('più mosse del minimo valgono meno stelle', () {
      final run = StarsRun(rook)
        ..move(Square.a4)
        ..move(Square.a8)
        ..move(Square.h8)
        ..move(Square.h1);
      expect(run.stars, 2);
      final slow = StarsRun(rook)
        ..move(Square.a2)
        ..move(Square.a3)
        ..move(Square.a4)
        ..move(Square.a8)
        ..move(Square.h8)
        ..move(Square.h1);
      expect(slow.stars, 1);
    });

    test('il pedone avanza di uno o di due dalla seconda e promuove', () {
      const pawn = StarsExercise(
        role: Role.pawn,
        start: Square.e2,
        stars: [Square.e8],
      );
      final run = StarsRun(pawn);
      expect(run.validMoves, {Square.e3, Square.e4});
      run.move(Square.e4);
      expect(run.validMoves, {Square.e5});
      run
        ..move(Square.e5)
        ..move(Square.e6)
        ..move(Square.e7)
        ..move(Square.e8);
      expect(run.done, isTrue);
      expect(run.role, Role.queen);
      expect(pawn.optimalMoves, 5);
    });
  });

  group('esercizi a linea', () {
    const backRank = LineExercise(
      fen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1',
      steps: ['a1a8'],
      goal: LineGoal.mate,
    );

    test('mossa giusta: matto e tre stelle', () {
      final run = LineRun(backRank);
      expect(run.play(Move.parse('a1a8')!), MoveVerdict.solved);
      expect(run.position.isCheckmate, isTrue);
      expect(run.stars, 3);
    });

    test('mossa sbagliata: errore e posizione invariata', () {
      final run = LineRun(backRank);
      expect(run.play(Move.parse('a1a7')!), MoveVerdict.wrong);
      expect(run.position.fen, backRank.fen);
      expect(run.mistakes, 1);
      expect(run.play(Move.parse('a1a8')!), MoveVerdict.solved);
      expect(run.stars, 2);
    });

    test('con l\'obiettivo matto vale anche un altro matto', () {
      const two = LineExercise(
        fen: '6k1/5ppp/8/8/8/8/8/RQ4K1 w - - 0 1',
        steps: ['a1a8'],
        goal: LineGoal.mate,
      );
      expect(LineRun(two).play(Move.parse('b1b7')!), MoveVerdict.wrong);
      expect(LineRun(two).play(Move.parse('b1b8')!), MoveVerdict.solved);
    });

    test('risposta automatica dell\'avversario e mosse alternative', () {
      const develop = LineExercise(
        fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        steps: ['g1f3|b1c3', 'b8c6', 'f1c4'],
        goal: LineGoal.line,
      );
      final run = LineRun(develop);
      expect(run.play(Move.parse('b1c3')!), MoveVerdict.correct);
      expect(run.lastReply, isNotNull);
      expect(run.position.board.roleAt(Square.c6), Role.knight);
      expect(run.play(Move.parse('f1c4')!), MoveVerdict.solved);
    });

    test('l\'arrocco si riconosce in entrambe le forme', () {
      const castle = LineExercise(
        fen: 'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
        steps: ['e1g1'],
        goal: LineGoal.line,
      );
      expect(LineRun(castle).play(Move.parse('e1h1')!), MoveVerdict.solved);
      expect(LineRun(castle).play(Move.parse('e1g1')!), MoveVerdict.solved);
    });

    test('con l\'obiettivo scacco vale ogni scacco dello stesso pezzo', () {
      const check = LineExercise(
        fen: '4k3/p7/8/8/8/3B4/7P/1R2K3 w - - 0 1',
        steps: ['d3b5'],
        goal: LineGoal.check,
      );
      // Lo scacco va dato con il pezzo dell'esercizio.
      expect(LineRun(check).play(Move.parse('b1b8')!), MoveVerdict.wrong);
      expect(LineRun(check).play(Move.parse('d3e2')!), MoveVerdict.wrong);
      expect(LineRun(check).play(Move.parse('d3h7')!), MoveVerdict.wrong);
      expect(LineRun(check).play(Move.parse('d3g6')!), MoveVerdict.solved);
      expect(LineRun(check).play(Move.parse('d3b5')!), MoveVerdict.solved);
    });

    test('tre errori o più valgono una stella', () {
      final run = LineRun(backRank);
      for (var i = 0; i < 3; i++) {
        run.play(Move.parse('a1a2')!);
      }
      run.play(Move.parse('a1a8')!);
      expect(run.stars, 1);
    });
  });

  group('obiettivo difendere', () {
    // Cavallo d2 attaccato dall'alfiere b4: lo difendono Td1 e Ta2, non Tf1.
    const defend = LineExercise(
      fen: '6k1/8/8/8/1b6/8/3N4/R5K1 w - - 0 1',
      steps: ['a1d1'],
      goal: LineGoal.defend,
      guard: Square.d2,
    );

    test('vale ogni mossa che difende il pezzo', () {
      expect(LineRun(defend).play(Move.parse('a1d1')!), MoveVerdict.solved);
      expect(LineRun(defend).play(Move.parse('a1a2')!), MoveVerdict.solved);
    });

    test('una mossa di torre che non difende è sbagliata', () {
      final run = LineRun(defend);
      expect(run.play(Move.parse('a1f1')!), MoveVerdict.wrong);
      expect(run.savedWithoutDefending, isFalse);
      expect(run.play(Move.parse('a1a8')!), MoveVerdict.wrong);
      expect(run.savedWithoutDefending, isFalse);
    });

    test('mettere in salvo il pezzo senza difenderlo ha un esito a parte', () {
      for (final uci in ['d2f3', 'd2b3', 'd2e4', 'd2f1', 'd2b1']) {
        final run = LineRun(defend);
        expect(run.play(Move.parse(uci)!), MoveVerdict.wrong, reason: uci);
        expect(run.savedWithoutDefending, isTrue, reason: uci);
      }
    });

    test('l\'esito a parte si azzera alla mossa seguente', () {
      final run = LineRun(defend);
      run.play(Move.parse('d2f3')!);
      run.play(Move.parse('a1f1')!);
      expect(run.savedWithoutDefending, isFalse);
    });

    test('dopo la cattura di un cavallo difeso il pezzo non è in salvo', () {
      const capture = LineExercise(
        fen: '6k1/8/8/4p3/3n4/5R2/8/Q3K3 w - - 0 1',
        steps: ['a1a3'],
        goal: LineGoal.defend,
        guard: Square.f3,
      );
      final run = LineRun(capture);
      // Il cavallo è difeso dal pedone: Dxd4 perde la donna, non salva nulla.
      expect(run.play(Move.parse('a1d4')!), MoveVerdict.wrong);
      expect(run.savedWithoutDefending, isFalse);
      for (final uci in ['a1a3', 'a1c3', 'a1d1', 'a1a8', 'e1f2']) {
        expect(
          LineRun(capture).play(Move.parse(uci)!),
          MoveVerdict.solved,
          reason: uci,
        );
      }
    });
  });
}
