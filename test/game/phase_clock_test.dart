import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/saved_game.dart';
import 'package:rokko/game/chess_game.dart';
import 'package:rokko/game/clock.dart';
import 'package:rokko/review/move_time.dart';

const classical = TimeControl(
  minutes: 90,
  increment: 30,
  phaseMoves: 40,
  phaseMinutes: 30,
);

class FakeTime {
  DateTime now = DateTime(2026);
  void advance(Duration d) => now = now.add(d);
}

void main() {
  group('cadenza a due fasi', () {
    test('etichetta e lettura vanno e vengono', () {
      expect(classical.label, '90+30@40:30');
      expect(TimeControl.parse('90+30@40:30'), classical);
      expect(
        TimeControl.parse('90+0/b5@40:30'),
        const TimeControl(
          minutes: 90,
          delay: 5,
          delayType: DelayType.bronstein,
          phaseMoves: 40,
          phaseMinutes: 30,
        ),
      );
      expect(TimeControl.parse('10+5')!.hasPhase, isFalse);
      expect(TimeControl.parse('10+5')!.label, '10+5');
    });

    test('una fase incompleta o nulla non si legge', () {
      expect(TimeControl.parse('90+30@0:30'), isNull);
      expect(TimeControl.parse('90+30@40:0'), isNull);
      expect(TimeControl.parse('90+30@40'), isNull);
      expect(TimeControl.parse('90+30@:30'), isNull);
    });

    test('cadenze con fasi diverse non sono uguali', () {
      const other = TimeControl(
        minutes: 90,
        increment: 30,
        phaseMoves: 40,
        phaseMinutes: 15,
      );
      expect(classical, isNot(other));
      expect(classical, isNot(const TimeControl(minutes: 90, increment: 30)));
      expect(classical.hashCode, isNot(other.hashCode));
    });

    test('la mossa che completa la fase aggiunge i minuti', () {
      final time = FakeTime();
      final clock = ChessClock(classical, now: () => time.now)
        ..start(Side.white);
      expect(
        clock.remainingAfterMove(Side.white, moves: 39),
        const Duration(minutes: 90, seconds: 30),
      );
      expect(
        clock.remainingAfterMove(Side.white, moves: 40),
        const Duration(minutes: 120, seconds: 30),
      );
      time.advance(const Duration(seconds: 10));
      clock.switchAfterMove(moves: 40);
      // 90 min - 10 s + 30 s di incremento + 30 min della seconda fase.
      expect(
        clock.remaining(Side.white),
        const Duration(minutes: 120, seconds: 20),
      );
      expect(clock.remaining(Side.black), const Duration(minutes: 90));
    });

    test('le altre mosse non aggiungono nulla, nemmeno la 41', () {
      final time = FakeTime();
      final clock = ChessClock(classical, now: () => time.now)
        ..start(Side.black);
      clock.switchAfterMove(moves: 41);
      expect(
        clock.remaining(Side.black),
        const Duration(minutes: 90, seconds: 30),
      );
    });

    test('senza fase il numero di mosse non conta', () {
      final time = FakeTime();
      final clock = ChessClock(
        const TimeControl(minutes: 5, increment: 2),
        now: () => time.now,
      )..start(Side.white);
      clock.switchAfterMove(moves: 40);
      expect(
        clock.remaining(Side.white),
        const Duration(minutes: 5, seconds: 2),
      );
    });

    test('il tempo speso per mossa tiene conto della fase', () {
      // Bianco muove per primo; ogni mossa costa 10 s. Con la fase alla 2ª mossa
      // di ciascun lato l'orologio di chi la completa guadagna 30 minuti.
      const control = TimeControl(minutes: 90, phaseMoves: 2, phaseMinutes: 30);
      const start = Duration(minutes: 90);
      final clocks = <Duration?>[
        start - const Duration(seconds: 10),
        start - const Duration(seconds: 10),
        start - const Duration(seconds: 20) + const Duration(minutes: 30),
        start - const Duration(seconds: 20) + const Duration(minutes: 30),
      ];
      final spent = timeSpent(clocks, first: Side.white, control: control);
      expect(spent, everyElement(const Duration(seconds: 10)));
    });
  });

  test('il PGN scrive le due fasi come da specifica', () {
    String pgnOf(String tc) => SavedGame.fromGame(
      ChessGame(),
      id: '1',
      white: 'A',
      black: 'B',
      mode: SavedGame.computer,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      timeControl: tc,
    ).pgn;
    expect(
      pgnOf('90+30@40:30'),
      contains('[TimeControl "40/5400+30:1800+30"]'),
    );
    expect(pgnOf('5+3'), contains('[TimeControl "300+3"]'));
  });
}
