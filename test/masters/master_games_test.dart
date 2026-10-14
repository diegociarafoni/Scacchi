import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/content.dart';
import 'package:rokko/masters/master_game.dart';
import 'package:rokko/masters/master_games.dart';

void main() {
  test('RF-87 la raccolta ha partite con identificativi unici', () {
    expect(masterGames.length, greaterThanOrEqualTo(6));
    final ids = masterGames.map((g) => g.id).toSet();
    expect(ids.length, masterGames.length);
  });

  test('RF-87 la raccolta è in ordine cronologico', () {
    final years = masterGames.map((g) => g.year).toList();
    expect(years, [...years]..sort());
  });

  test('RF-87 ci sono le partite di Capablanca da Chess Fundamentals', () {
    final byId = {for (final g in masterGames) g.id: g};
    final burn = byId['capablanca-burn-1911'];
    final teichmann = byId['capablanca-teichmann-1913'];
    final marshall = byId['marshall-capablanca-1918'];
    expect(burn, isNotNull);
    expect(teichmann, isNotNull);
    expect(marshall, isNotNull);
    expect(
      (burn!.white, burn.result, burn.moves.length),
      ('Capablanca', '1-0', 91),
    );
    expect(
      (teichmann!.white, teichmann.result, teichmann.moves.length),
      ('Capablanca', '1-0', 75),
    );
    expect(
      (marshall!.black, marshall.result, marshall.moves.length),
      ('Capablanca', '0-1', 78),
    );
    // L'ultima mossa del libro: il re nero prende il pedone in f4.
    expect(marshall.moves.last, 'Kxf4');
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
        final plies = [
          for (final id in Content.of('masters').ids)
            if (id.startsWith('${game.id}.note'))
              int.parse(id.substring('${game.id}.note'.length)),
        ];
        expect(plies, isNotEmpty);
        for (final ply in plies) {
          expect(ply, inInclusiveRange(1, game.moves.length));
          expect(game.noteAt(ply), isNotEmpty);
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
      year: 1900,
      result: '1-0',
      moves: ['e4', 'e4'],
    );
    expect(() => bad.positions, throwsFormatException);
  });
}
