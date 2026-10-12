import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/masters/master_game.dart';
import 'package:scacchi/masters/master_games.dart';

void main() {
  test('RF-87 la raccolta ha partite con identificativi unici', () {
    expect(masterGames.length, greaterThanOrEqualTo(6));
    final ids = masterGames.map((g) => g.id).toSet();
    expect(ids.length, masterGames.length);
  });

  for (final game in masterGames) {
    group('RF-87 ${game.id}', () {
      test('tutte le mosse sono legali e il risultato torna', () {
        final positions = game.positions;
        expect(positions.length, game.moves.length + 1);
        final last = positions.last;
        expect(['1-0', '0-1', '1/2-1/2'], contains(game.result));
        // Se la partita finisce sulla scacchiera, l'esito deve coincidere;
        // altrimenti il maestro ha vinto per abbandono.
        final outcome = last.outcome;
        if (outcome != null) {
          expect(outcome.winner, switch (game.result) {
            '1-0' => Side.white,
            '0-1' => Side.black,
            _ => null,
          });
        }
      });

      test('dati e fonte documentati', () {
        expect(game.white, isNotEmpty);
        expect(game.black, isNotEmpty);
        expect(game.event, isNotEmpty);
        expect(game.intro, isNotEmpty);
        expect(game.year, inInclusiveRange(1700, 2025));
      });

      test('i commenti puntano a mosse esistenti', () {
        for (final ply in game.notes.keys) {
          expect(ply, inInclusiveRange(1, game.moves.length));
        }
      });
    });
  }

  test('RF-87 le mosse si leggono in SAN con il numero', () {
    final game = masterGames.firstWhere((g) => g.id == 'opera-1858');
    expect(game.label(1), '1. e4');
    expect(game.label(2), '1… e5');
    expect(game.moveAt(1), NormalMove.fromUci('e2e4'));
  });

  test('RF-87 una mossa illegale nel catalogo è rifiutata', () {
    const bad = MasterGame(
      id: 'x',
      white: 'A',
      black: 'B',
      event: 'E',
      year: 1900,
      result: '1-0',
      intro: 'i',
      moves: ['e4', 'e4'],
    );
    expect(() => bad.positions, throwsFormatException);
  });
}
