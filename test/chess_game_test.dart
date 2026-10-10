import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/chess_game.dart';

void playAll(ChessGame game, List<String> uci) {
  for (final m in uci) {
    expect(game.play(Move.parse(m)!), isTrue, reason: m);
  }
}

void main() {
  test('registra le mosse in notazione algebrica', () {
    final game = ChessGame();
    playAll(game, ['e2e4', 'e7e5', 'g1f3']);
    expect(game.moves.map((m) => m.san), ['e4', 'e5', 'Nf3']);
    expect(game.position.turn, Side.black);
  });

  test('rifiuta le mosse illegali', () {
    final game = ChessGame();
    expect(game.play(Move.parse('e2e5')!), isFalse);
    expect(game.moves, isEmpty);
  });

  test('riconosce lo scacco matto (matto del barbiere)', () {
    final game = ChessGame();
    playAll(game, ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7']);
    expect(game.endReason, GameEndReason.checkmate);
    expect(game.outcome, Outcome.whiteWins);
    expect(game.play(Move.parse('e8f7')!), isFalse);
  });

  test('riconosce lo stallo', () {
    final game = ChessGame(
      initial: Chess.fromSetup(
        Setup.parseFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'),
      ),
    );
    expect(game.endReason, GameEndReason.stalemate);
    expect(game.outcome, Outcome.draw);
  });

  test('riconosce la triplice ripetizione', () {
    final game = ChessGame();
    playAll(game, ['g1f3', 'g8f6', 'f3g1', 'f6g8', 'g1f3', 'g8f6', 'f3g1']);
    expect(game.isOver, isFalse);
    playAll(game, ['f6g8']);
    expect(game.endReason, GameEndReason.threefoldRepetition);
  });

  test('applica la regola delle 50 mosse', () {
    final game = ChessGame(
      initial: Chess.fromSetup(
        Setup.parseFen('4k3/8/8/8/8/8/R7/4K3 w - - 99 80'),
      ),
    );
    expect(game.isOver, isFalse);
    playAll(game, ['a2a3']);
    expect(game.endReason, GameEndReason.fiftyMoveRule);
  });

  test('annulla le mosse e l\'abbandono', () {
    final game = ChessGame();
    playAll(game, ['e2e4', 'e7e5']);
    game.undo();
    expect(game.moves.length, 1);
    game.resign(Side.black);
    expect(game.outcome, Outcome.whiteWins);
    game.undo();
    expect(game.isOver, isFalse);
  });
}
