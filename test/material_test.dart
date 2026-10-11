import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/game/material.dart';

ChessGame _game(List<String> uci, {String? fen}) {
  final game = ChessGame(
    initial: fen == null ? null : Chess.fromSetup(Setup.parseFen(fen)),
  );
  for (final m in uci) {
    expect(game.play(Move.parse(m)!), isTrue, reason: m);
  }
  return game;
}

void main() {
  test('RF-11 posizione iniziale senza catture né vantaggio', () {
    final m = MaterialBalance.of(_game([]));
    expect(m.capturedBy(Side.white), isEmpty);
    expect(m.capturedBy(Side.black), isEmpty);
    expect(m.advantage(Side.white), 0);
    expect(m.advantage(Side.black), 0);
  });

  test('RF-11 cattura di un pedone', () {
    final m = MaterialBalance.of(_game(['e2e4', 'd7d5', 'e4d5']));
    expect(m.capturedBy(Side.white), [Role.pawn]);
    expect(m.capturedBy(Side.black), isEmpty);
    expect(m.advantage(Side.white), 1);
    expect(m.advantage(Side.black), -1);
  });

  test('RF-11 catture ordinate dal pezzo di valore maggiore', () {
    final m = MaterialBalance.of(
      _game(['e2e4', 'd7d5', 'e4d5', 'd8d5', 'b1c3', 'd5a2', 'a1a2']),
    );
    expect(m.capturedBy(Side.white), [Role.queen, Role.pawn]);
    expect(m.capturedBy(Side.black), [Role.pawn, Role.pawn]);
    expect(m.advantage(Side.white), 8);
  });

  test('RF-11 cattura en passant', () {
    final m = MaterialBalance.of(
      _game(['e2e4', 'a7a6', 'e4e5', 'd7d5', 'e5d6']),
    );
    expect(m.capturedBy(Side.white), [Role.pawn]);
  });

  test('RF-11 la promozione non è una cattura ma conta nel vantaggio', () {
    final m = MaterialBalance.of(
      _game(['a7a8q'], fen: '7k/P7/8/8/8/8/8/4K3 w - - 0 1'),
    );
    expect(m.capturedBy(Side.black), isEmpty);
    expect(m.capturedBy(Side.white), isEmpty);
    expect(m.advantage(Side.white), 9);
  });

  test('RF-11 un pezzo promosso catturato conta come tale', () {
    final m = MaterialBalance.of(
      _game(['a7a8q', 'b8a8'], fen: '1r5k/P7/8/8/8/8/8/4K3 w - - 0 1'),
    );
    expect(m.capturedBy(Side.black), [Role.queen]);
  });
}
