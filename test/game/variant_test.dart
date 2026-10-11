import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/game/variant.dart';

void main() {
  group('RF-120 Chess960', () {
    test('la posizione 518 è quella classica', () {
      expect(chess960BackRank(standardChess960Id), 'RNBQKBNR');
      expect(chess960Position(518).fen, Chess.initial.fen);
    });

    test('valori noti della numerazione di Scharnagl', () {
      expect(chess960BackRank(0), 'BBQNNRKR');
      expect(chess960BackRank(959), 'RKRNNQBB');
    });

    test('960 posizioni distinte e tutte valide', () {
      final ranks = <String>{};
      for (var id = 0; id < 960; id++) {
        final rank = chess960BackRank(id);
        ranks.add(rank);
        final bishops = [
          for (var i = 0; i < 8; i++)
            if (rank[i] == 'B') i,
        ];
        expect(bishops[0].isEven != bishops[1].isEven, isTrue, reason: rank);
        final king = rank.indexOf('K');
        expect(rank.indexOf('R') < king, isTrue, reason: rank);
        expect(rank.lastIndexOf('R') > king, isTrue, reason: rank);
        expect(chess960Position(id).legalMoves, isNotEmpty);
      }
      expect(ranks, hasLength(960));
    });

    test('arrocco con il re che va sulla torre', () {
      // Posizione 3: BQNNRKRB, re in f1 e torre in g1 si scambiano di casa.
      expect(chess960BackRank(3), 'BQNNRKRB');
      final game = ChessGame(
        initial: chess960Position(3),
        variant: Variant.chess960,
      );
      expect(game.play(Move.parse('f1g1')!), isTrue);
      expect(game.moves.last.san, 'O-O');
      final board = game.position.board;
      expect(board.pieceAt(Square.g1), Piece.whiteKing);
      expect(board.pieceAt(Square.f1), Piece.whiteRook);
    });
  });

  group('RF-121 varianti', () {
    test('il re al centro vince a Re della collina', () {
      final game = ChessGame(
        initial: initialPosition(Variant.kingOfTheHill),
        variant: Variant.kingOfTheHill,
      );
      for (final uci in ['e2e4', 'a7a6', 'e1e2', 'a6a5', 'e2e3', 'a5a4']) {
        expect(game.play(Move.parse(uci)!), isTrue, reason: uci);
      }
      expect(game.isOver, isFalse);
      game.play(Move.parse('e3d4')!);
      expect(game.endReason, GameEndReason.variantEnd);
      expect(game.outcome, Outcome.whiteWins);
    });

    test('il terzo scacco vince a Tre scacchi', () {
      final game = ChessGame(
        initial: initialPosition(Variant.threeCheck),
        variant: Variant.threeCheck,
      );
      // Qxf7+, Bc4+ e Bxd5+.
      for (final uci in [
        'e2e4', 'e7e5', 'd1h5', 'b8c6', 'h5f7', 'e8f7', 'f1c4', 'd7d5', //
      ]) {
        expect(game.play(Move.parse(uci)!), isTrue, reason: uci);
      }
      expect(game.isOver, isFalse);
      game.play(Move.parse('c4d5')!);
      expect(game.endReason, GameEndReason.variantEnd);
      expect(game.outcome, Outcome.whiteWins);
    });

    test('la variante si legge dal nome PGN', () {
      expect(Variant.fromPgn(null), Variant.standard);
      expect(Variant.fromPgn('Chess960'), Variant.chess960);
      expect(Variant.fromPgn('Fischerandom'), Variant.chess960);
      expect(Variant.fromPgn('King of the Hill'), Variant.kingOfTheHill);
      expect(Variant.fromPgn('Three-check'), Variant.threeCheck);
      expect(Variant.fromPgn('Atomic'), isNull);
    });
  });
}
