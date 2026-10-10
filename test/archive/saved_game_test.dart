import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/game/chess_game.dart';

void main() {
  final t = DateTime(2026, 10, 10, 9);

  test(
    'dati per le statistiche: colore, cadenza, Elo, precisione, apertura',
    () {
      final game = SavedGame.fromGame(
        ChessGame(),
        id: 'a',
        white: 'Io',
        black: 'Bot',
        mode: 'computer',
        createdAt: t,
        updatedAt: t,
        playerSide: Side.white,
        timeControl: '5+0',
        opponentElo: 1200,
      ).copyWith(accuracy: 81.5, opening: 'Partita Italiana');
      final back = SavedGame.fromJson(game.toJson());
      expect(back.playerSide, Side.white);
      expect(back.timeControl, '5+0');
      expect(back.opponentElo, 1200);
      expect(back.accuracy, 81.5);
      expect(back.opening, 'Partita Italiana');
      expect(back.pgn, contains('[TimeControl "300+0"]'));
    },
  );

  test('le partite salvate prima restano leggibili', () {
    final old = {
      'id': 'x',
      'createdAt': t.toIso8601String(),
      'updatedAt': t.toIso8601String(),
      'white': 'A',
      'black': 'B',
      'mode': 'locale',
      'result': '*',
      'pgn': '*',
    };
    final g = SavedGame.fromJson(old);
    expect(g.playerSide, isNull);
    expect(g.accuracy, isNull);
  });

  test('risultato dal punto di vista del giocatore', () {
    SavedGame g(String result, Side? side) => SavedGame(
      id: 'x',
      createdAt: t,
      updatedAt: t,
      white: 'A',
      black: 'B',
      mode: 'computer',
      result: result,
      pgn: '',
      playerSide: side,
    );
    expect(g('1-0', Side.white).playerScore, 1.0);
    expect(g('1-0', Side.black).playerScore, 0.0);
    expect(g('1/2-1/2', Side.black).playerScore, 0.5);
    expect(g('*', Side.black).playerScore, isNull);
    expect(g('1-0', null).playerScore, isNull);
  });
}
