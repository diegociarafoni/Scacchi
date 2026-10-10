import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/game_activity.dart';

ChessGame play(List<String> uci, {Position? initial}) {
  final game = ChessGame(initial: initial);
  for (final m in uci) {
    expect(game.play(Move.parse(m)!), isTrue, reason: m);
  }
  return game;
}

const scholarsMate = ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7'];

void main() {
  test('vittoria, sconfitta e partita locale', () {
    final game = play(scholarsMate);
    expect(gameActivity(game, player: Side.white).result, GameResult.win);
    expect(gameActivity(game, player: Side.black).result, GameResult.loss);
    expect(gameActivity(game).result, GameResult.local);
  });

  test('patta', () {
    final game = play(['e2e4'])..agreeDraw();
    expect(gameActivity(game, player: Side.white).result, GameResult.draw);
  });

  test('pezzo che ha dato il matto vincente', () {
    final game = play(scholarsMate);
    expect(gameActivity(game, player: Side.white).matedWith, Role.queen);
    expect(gameActivity(game, player: Side.black).matedWith, isNull);
  });

  test('matto di cavallo', () {
    // Matto affogato: Cf7#.
    final game = play(
      ['g5f7'],
      initial: Chess.fromSetup(
        Setup.parseFen('6rk/6pp/8/6N1/8/8/8/6K1 w - - 0 1'),
      ),
    );
    expect(game.position.isCheckmate, isTrue);
    expect(gameActivity(game, player: Side.white).matedWith, Role.knight);
  });

  test('arrocco lungo del giocatore', () {
    final game = play(
      ['e1c1', 'e8g8'],
      initial: Chess.fromSetup(
        Setup.parseFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'),
      ),
    );
    expect(gameActivity(game, player: Side.white).castledLong, isTrue);
    expect(gameActivity(game, player: Side.black).castledLong, isFalse);
  });

  test('durata passata all\'attività', () {
    final a = gameActivity(
      play(scholarsMate),
      duration: const Duration(minutes: 3),
    );
    expect(a.duration, const Duration(minutes: 3));
  });
}
