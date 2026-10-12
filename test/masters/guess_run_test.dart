import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/masters/guess_run.dart';
import 'package:scacchi/masters/master_game.dart';

const _game = MasterGame(
  id: 'legal',
  white: 'Légal',
  black: 'Saint-Brie',
  event: 'Parigi',
  year: 1750,
  result: '1-0',
  intro: 'Il matto di Légal.',
  moves: [
    'e4',
    'e5',
    'Nf3',
    'd6',
    'Bc4',
    'Bg4',
    'Nc3',
    'g6',
    'Nxe5',
    'Bxd1',
    'Bxf7+',
    'Ke7',
    'Nd5#',
  ],
);

Move _m(String uci) => NormalMove.fromUci(uci);

/// Una mossa legale diversa da quella del maestro, se ce n'è una.
Move _otherThan(GuessRun run) {
  for (final entry in makeLegalMoves(run.position).entries) {
    for (final to in entry.value) {
      final move = NormalMove(from: entry.key, to: to);
      if (move != run.expected) return move;
    }
  }
  return run.expected; // mossa obbligata
}

void main() {
  test('RF-88 con il Bianco si parte dalla prima mossa', () {
    final run = GuessRun(_game, Side.white);
    expect(run.userToMove, isTrue);
    expect(run.expected, _m('e2e4'));
    expect(run.total, 7);
  });

  test('RF-88 con il Nero la prima mossa del Bianco è già giocata', () {
    final run = GuessRun(_game, Side.black);
    expect(run.userToMove, isFalse);
    expect(run.playOpponent(), _m('e2e4'));
    expect(run.userToMove, isTrue);
    expect(run.expected, _m('e7e5'));
    expect(run.total, 6);
  });

  test('RF-88 mossa uguale a quella del maestro: punto', () {
    final run = GuessRun(_game, Side.white);
    final r = run.submit(_m('e2e4'));
    expect(r.matched, isTrue);
    expect(r.master, _m('e2e4'));
    expect(run.correct, 1);
    expect(run.userToMove, isFalse);
  });

  test(
    'RF-88 mossa diversa: nessun punto, si prosegue con quella del maestro',
    () {
      final run = GuessRun(_game, Side.white);
      final r = run.submit(_m('d2d4'));
      expect(r.matched, isFalse);
      expect(r.master, _m('e2e4'));
      expect(run.correct, 0);
      expect(run.position.fen, contains('4P3'));
      expect(run.playOpponent(), _m('e7e5'));
    },
  );

  test('RF-88 una mossa illegale non conta', () {
    final run = GuessRun(_game, Side.white);
    expect(() => run.submit(_m('e2e5')), throwsArgumentError);
    expect(run.attempts, 0);
  });

  test('RF-88 la partita finisce con punteggio e stelle', () {
    final run = GuessRun(_game, Side.white);
    while (!run.finished) {
      if (run.userToMove) {
        run.submit(run.expected);
      } else {
        run.playOpponent();
      }
    }
    expect(run.correct, 7);
    expect(run.percent, 100);
    expect(run.stars, 3);
  });

  test('RF-88 il Nero che gioca fino al matto del Bianco finisce', () {
    final run = GuessRun(_game, Side.black);
    while (!run.finished) {
      if (run.userToMove) {
        run.submit(_otherThan(run));
      } else {
        run.playOpponent();
      }
    }
    expect(run.total, 6);
    expect(run.correct, lessThan(run.total));
    expect(run.stars, 1);
  });

  test('RF-88 le stelle seguono le soglie', () {
    expect(guessStars(100), 3);
    expect(guessStars(70), 3);
    expect(guessStars(69), 2);
    expect(guessStars(50), 2);
    expect(guessStars(49), 1);
    expect(guessStars(0), 1);
  });

  test('RF-88 l\'arrocco dell\'utente vale come quello del maestro', () {
    const g = MasterGame(
      id: 'c',
      white: 'A',
      black: 'B',
      event: 'E',
      year: 1900,
      result: '1-0',
      intro: 'i',
      moves: ['e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Bc5', 'O-O', 'Nf6', 'Re1'],
    );
    final run = GuessRun(g, Side.white);
    for (var i = 0; i < 6; i++) {
      if (run.userToMove) {
        run.submit(run.expected);
      } else {
        run.playOpponent();
      }
    }
    expect(run.submit(_m('e1g1')).matched, isTrue);
  });
}
