import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/game/move_label.dart';

ChessGame _game(Position initial, List<String> uci) {
  final game = ChessGame(initial: initial);
  for (final m in uci) {
    expect(game.play(Move.parse(m)!), isTrue);
  }
  return game;
}

void main() {
  test('numera le mosse dalla posizione iniziale standard', () {
    final game = _game(Chess.initial, ['e2e4', 'e7e5', 'g1f3']);
    expect(moveLabel(game, 0), '1. e4');
    expect(moveLabel(game, 1), 'e5');
    expect(moveLabel(game, 1, number: true), '1... e5');
    expect(moveLabel(game, 2), '2. Nf3');
  });

  test('parte dal numero di mossa e dal tratto della posizione iniziale', () {
    final start = Chess.fromSetup(
      Setup.parseFen(
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 12',
      ),
    );
    final game = _game(start, ['e7e5', 'g1f3']);
    expect(moveLabel(game, 0), '12... e5');
    expect(moveLabel(game, 1), '13. Nf3');
  });
}
