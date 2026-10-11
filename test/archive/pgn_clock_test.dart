import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/pgn.dart';
import 'package:scacchi/game/chess_game.dart';

ChessGame game() {
  final g = ChessGame();
  g.play(Move.parse('e2e4')!, clock: const Duration(minutes: 4, seconds: 58));
  g.play(Move.parse('e7e5')!, clock: const Duration(minutes: 4, seconds: 55));
  g.play(Move.parse('g1f3')!);
  return g;
}

void main() {
  group('RF-67 tempo residuo a ogni mossa', () {
    test('la partita ricorda il tempo di chi ha mosso', () {
      final g = game();
      expect(g.moves[0].clock, const Duration(minutes: 4, seconds: 58));
      expect(g.moves[2].clock, isNull);
    });

    test('annullare toglie anche il tempo', () {
      final g = game()..undo();
      expect(g.moves, hasLength(2));
      g.play(Move.parse('g1f3')!, clock: const Duration(seconds: 30));
      expect(g.moves.last.clock, const Duration(seconds: 30));
    });

    test('il PGN riporta [%clk] solo dove il tempo è noto', () {
      final pgn = exportPgn(game());
      expect(pgn, contains('1. e4 { [%clk 0:04:58] }'));
      expect(pgn, contains('e5 { [%clk 0:04:55] }'));
      expect(pgn, contains('2. Nf3'));
      expect(pgn, isNot(contains('Nf3 {')));
    });

    test('senza tempi il PGN resta quello di prima', () {
      final g = ChessGame()..play(Move.parse('e2e4')!);
      expect(exportPgn(g), isNot(contains('%clk')));
    });

    test('importando si ritrovano i tempi', () {
      final back = importPgn(exportPgn(game())).games.single.game;
      expect(back.moves.map((m) => m.clock), [
        const Duration(minutes: 4, seconds: 58),
        const Duration(minutes: 4, seconds: 55),
        null,
      ]);
    });

    test('un PGN esterno con altri commenti non perde il tempo', () {
      final back = importPgn(
        '[Event "x"]\n\n1. e4 { buona apertura [%clk 1:00:05] } e5 *',
      ).games.single.game;
      expect(back.moves[0].clock, const Duration(hours: 1, seconds: 5));
      expect(back.moves[1].clock, isNull);
    });
  });
}
