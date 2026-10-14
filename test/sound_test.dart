import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/chess_game.dart';
import 'package:rokko/game/sounds.dart';

GameSound? _last(List<String> uci, {String? fen}) {
  final game = ChessGame(
    initial: fen == null ? null : Chess.fromSetup(Setup.parseFen(fen)),
  );
  Position before = game.position;
  for (final m in uci) {
    before = game.position;
    expect(game.play(Move.parse(m)!), isTrue, reason: m);
  }
  return soundForLastMove(game, before);
}

void main() {
  test('RP-03 mossa semplice', () {
    expect(_last(['e2e4']), GameSound.move);
  });

  test('RP-03 cattura, anche en passant', () {
    expect(_last(['e2e4', 'd7d5', 'e4d5']), GameSound.capture);
    expect(_last(['e2e4', 'a7a6', 'e4e5', 'd7d5', 'e5d6']), GameSound.capture);
  });

  test('RP-03 arrocco', () {
    expect(
      _last(['e1g1'], fen: 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'),
      GameSound.castle,
    );
  });

  test('RP-03 promozione', () {
    expect(
      _last(['a7a8q'], fen: '8/P7/7k/8/8/8/8/4K3 w - - 0 1'),
      GameSound.promote,
    );
  });

  test('RP-03 lo scacco prevale su cattura e mossa', () {
    expect(_last(['e2e4', 'f7f6', 'd1h5']), GameSound.check);
  });

  test('RP-03 la fine partita prevale su tutto', () {
    expect(
      _last(['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7']),
      GameSound.gameEnd,
    );
  });

  test('RP-03 nessun suono senza mosse', () {
    final game = ChessGame();
    expect(soundForLastMove(game, game.position), isNull);
  });
}
