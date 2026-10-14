import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/clock.dart';
import 'package:rokko/game/handicap.dart';

void main() {
  String fen(Handicap h, [Side human = Side.white]) =>
      h.startPosition(human).fen;

  group('RF-27 posizione iniziale', () {
    test('senza pezzo la posizione è quella classica', () {
      const h = Handicap(giverMinutes: 3);
      expect(fen(h), Chess.initial.fen);
    });

    test('chi gioca col Bianco e dà la donna', () {
      const h = Handicap(piece: HandicapPiece.queen);
      expect(
        fen(h),
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNB1KBNR w KQkq - 0 1',
      );
    });

    test('chi gioca col Nero e dà il cavallo: il Bianco è intero', () {
      const h = Handicap(piece: HandicapPiece.knight);
      expect(
        fen(h, Side.black),
        'r1bqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
    });

    test('l\'avversario del Bianco dà il pedone f', () {
      const h = Handicap(
        piece: HandicapPiece.fPawn,
        giver: HandicapGiver.opponent,
      );
      expect(
        fen(h),
        'rnbqkbnr/ppppp1pp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
    });

    test('senza la torre di donna cade l\'arrocco lungo di chi la dà', () {
      const white = Handicap(piece: HandicapPiece.rook);
      expect(fen(white), contains(' w Kkq '));
      expect(fen(white), startsWith('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/'));
      const black = Handicap(
        piece: HandicapPiece.rook,
        giver: HandicapGiver.opponent,
      );
      expect(
        fen(black),
        '1nbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQk - 0 1',
      );
    });

    test('ogni posizione è valida e il Bianco muove', () {
      for (final piece in HandicapPiece.values) {
        for (final giver in HandicapGiver.values) {
          for (final human in Side.values) {
            final pos = Handicap(
              piece: piece,
              giver: giver,
            ).startPosition(human);
            expect(pos.turn, Side.white);
            expect(pos.legalMoves, isNotEmpty);
          }
        }
      }
    });
  });

  group('RF-27 tempo', () {
    const control = TimeControl(minutes: 10);

    test('chi dà il vantaggio parte con meno minuti', () {
      const h = Handicap(giverMinutes: 3, giver: HandicapGiver.opponent);
      expect(h.startTimes(control, Side.white), {
        Side.white: const Duration(minutes: 10),
        Side.black: const Duration(minutes: 3),
      });
      expect(h.startTimes(control, Side.black), {
        Side.white: const Duration(minutes: 3),
        Side.black: const Duration(minutes: 10),
      });
    });

    test('senza handicap di tempo i lati sono pari', () {
      const h = Handicap(piece: HandicapPiece.queen);
      expect(h.startTimes(control, Side.white).values.toSet(), {
        const Duration(minutes: 10),
      });
    });

    test('l\'orologio parte dai tempi indicati', () {
      final clock = ChessClock(
        control,
        startTimes: {
          Side.white: const Duration(minutes: 3),
          Side.black: const Duration(minutes: 10),
        },
      );
      expect(clock.remaining(Side.white), const Duration(minutes: 3));
      expect(clock.remaining(Side.black), const Duration(minutes: 10));
    });
  });

  group('RF-27 intestazione PGN', () {
    test('pezzo e tempo', () {
      const h = Handicap(piece: HandicapPiece.queen, giverMinutes: 3);
      expect(h.pgnValue(Side.white), 'White gives queen; White time 3 min');
      expect(h.pgnValue(Side.black), 'Black gives queen; Black time 3 min');
    });

    test('solo tempo, dato dall\'avversario', () {
      const h = Handicap(giverMinutes: 2, giver: HandicapGiver.opponent);
      expect(h.pgnValue(Side.white), 'Black time 2 min');
    });
  });

  group('RF-27 handicap applicabile', () {
    const both = Handicap(piece: HandicapPiece.rook, giverMinutes: 3);

    test('con cadenza maggiore resta tutto', () {
      expect(
        both.usable(control: const TimeControl(minutes: 5), standard: true),
        both,
      );
    });

    test('un tempo non inferiore alla cadenza cade', () {
      final h = both.usable(
        control: const TimeControl(minutes: 3),
        standard: true,
      );
      expect(h, const Handicap(piece: HandicapPiece.rook));
    });

    test('senza orologio resta il solo pezzo', () {
      expect(
        both.usable(control: null, standard: true),
        const Handicap(piece: HandicapPiece.rook),
      );
    });

    test('in una variante cade il pezzo', () {
      expect(
        both.usable(control: const TimeControl(minutes: 5), standard: false),
        const Handicap(giverMinutes: 3),
      );
    });

    test('se non resta nulla non c\'è handicap', () {
      expect(both.usable(control: null, standard: false), isNull);
    });
  });

  group('RF-27 tempi dall\'intestazione PGN', () {
    const control = TimeControl(minutes: 10);

    test('si ricostruiscono dal valore scritto in partita', () {
      const h = Handicap(
        piece: HandicapPiece.queen,
        giverMinutes: 3,
        giver: HandicapGiver.opponent,
      );
      expect(
        Handicap.startTimesFromPgn(h.pgnValue(Side.white), control),
        h.startTimes(control, Side.white),
      );
      expect(
        Handicap.startTimesFromPgn(h.pgnValue(Side.black), control),
        h.startTimes(control, Side.black),
      );
    });

    test('senza tempo nell\'intestazione o senza intestazione: nulla', () {
      expect(Handicap.startTimesFromPgn('White gives rook', control), isNull);
      expect(Handicap.startTimesFromPgn(null, control), isNull);
      expect(Handicap.startTimesFromPgn('White time 3 min', null), isNull);
    });
  });

  test('ChessClock espone i tempi iniziali', () {
    final clock = ChessClock(
      const TimeControl(minutes: 10),
      startTimes: {Side.white: const Duration(minutes: 3)},
    );
    expect(clock.startTimes, {
      Side.white: const Duration(minutes: 3),
      Side.black: const Duration(minutes: 10),
    });
  });
}
