import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/chess_game.dart';

List<Move> moves(List<String> uci) => [for (final m in uci) Move.parse(m)!];

void main() {
  test('ricostruisce una partita da mosse già giocate', () {
    final game = ChessGame.replay(Chess.initial, moves(['e2e4', 'e7e5']));
    expect(game?.moves.map((m) => m.san), ['e4', 'e5']);
  });

  test('continua oltre una triplice ripetizione non reclamata', () {
    final game = ChessGame.replay(
      Chess.initial,
      moves([
        ...['g1f3', 'g8f6', 'f3g1', 'f6g8'],
        ...['g1f3', 'g8f6', 'f3g1', 'f6g8'],
        'e2e4',
      ]),
    );
    expect(game?.moves, hasLength(9));
    expect(game?.isOver, isFalse);
  });

  test('una mossa illegale restituisce null', () {
    expect(ChessGame.replay(Chess.initial, moves(['e2e5'])), isNull);
  });

  test('nessuna mossa dopo il matto', () {
    final mate = moves(['f2f3', 'e7e5', 'g2g4', 'd8h4', 'a2a3']);
    expect(ChessGame.replay(Chess.initial, mate), isNull);
  });
}
