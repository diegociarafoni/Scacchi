import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/game/clock.dart';

class FakeTime {
  DateTime now = DateTime(2026);
  void advance(Duration d) => now = now.add(d);
}

void main() {
  test('RF-40 cadenze predefinite', () {
    final names = TimeControl.presets.map((t) => t.label).toList();
    expect(
      names,
      containsAll([
        '1+0',
        '1+1',
        '2+1',
        '3+0',
        '3+2',
        '5+0',
        '10+0',
        '15+10',
        '30+0',
      ]),
    );
    expect(
      TimeControl.parse('3+2'),
      const TimeControl(minutes: 3, increment: 2),
    );
  });

  test('RF-40 il tempo scorre solo per chi ha il tratto', () {
    final t = FakeTime();
    final clock = ChessClock(
      const TimeControl(minutes: 3, increment: 2),
      now: () => t.now,
    );
    expect(clock.remaining(Side.white), const Duration(minutes: 3));
    clock.start(Side.white);
    t.advance(const Duration(seconds: 10));
    expect(
      clock.remaining(Side.white),
      const Duration(minutes: 2, seconds: 50),
    );
    expect(clock.remaining(Side.black), const Duration(minutes: 3));

    clock.switchAfterMove();
    expect(
      clock.remaining(Side.white),
      const Duration(minutes: 2, seconds: 52),
      reason: 'incremento di 2 secondi',
    );
    t.advance(const Duration(seconds: 5));
    expect(
      clock.remaining(Side.black),
      const Duration(minutes: 2, seconds: 55),
    );
    expect(
      clock.remaining(Side.white),
      const Duration(minutes: 2, seconds: 52),
    );
  });

  test('RF-40 caduta della bandierina', () {
    final t = FakeTime();
    final clock = ChessClock(const TimeControl(minutes: 1), now: () => t.now);
    clock.start(Side.white);
    t.advance(const Duration(seconds: 61));
    expect(clock.remaining(Side.white), Duration.zero);
    expect(clock.flagged, Side.white);
  });

  test('RF-40 pausa e ripresa', () {
    final t = FakeTime();
    final clock = ChessClock(const TimeControl(minutes: 1), now: () => t.now);
    clock.start(Side.white);
    t.advance(const Duration(seconds: 5));
    clock.pause();
    t.advance(const Duration(seconds: 30));
    expect(clock.remaining(Side.white), const Duration(seconds: 55));
    clock.start(Side.white);
    t.advance(const Duration(seconds: 5));
    expect(clock.remaining(Side.white), const Duration(seconds: 50));
  });

  test('RF-41 formato e avvisi', () {
    expect(formatClock(const Duration(minutes: 3)), '3:00');
    expect(formatClock(const Duration(minutes: 1, seconds: 5)), '1:05');
    expect(
      formatClock(const Duration(seconds: 19, milliseconds: 470)),
      '0:19.4',
    );
    expect(isLowTime(const Duration(seconds: 9)), isTrue);
    expect(isLowTime(const Duration(seconds: 10)), isFalse);
  });

  test('RF-25 tempo scaduto: vince l\'avversario', () {
    final game = ChessGame();
    game.play(Move.parse('e2e4')!);
    game.flag(Side.black);
    expect(game.endReason, GameEndReason.timeout);
    expect(game.outcome, Outcome.whiteWins);
  });

  test('RF-25 tempo scaduto con avversario senza materiale: patta', () {
    final game = ChessGame(
      initial: Chess.fromSetup(
        Setup.parseFen('4k3/8/8/8/8/8/8/4K2r w - - 0 1'),
      ),
    );
    game.flag(Side.black);
    expect(game.endReason, GameEndReason.timeout);
    expect(game.outcome, Outcome.draw);
  });

  test('RF-40 istantanea e ripristino per annullare una mossa', () {
    final t = FakeTime();
    final clock = ChessClock(
      const TimeControl(minutes: 1, increment: 10),
      now: () => t.now,
    );
    clock.start(Side.white);
    t.advance(const Duration(seconds: 5));
    final before = clock.snapshot();
    clock.switchAfterMove();
    t.advance(const Duration(seconds: 3));
    clock.restore(before, Side.white);
    expect(clock.remaining(Side.white), const Duration(seconds: 55));
    expect(clock.remaining(Side.black), const Duration(minutes: 1));
    expect(clock.active, Side.white);
  });

  test('RF-41 avviso di poco tempo una volta per discesa, poi riarmato', () {
    final alarm = LowTimeAlarm();
    expect(alarm.check(Side.white, const Duration(seconds: 12)), isFalse);
    expect(alarm.check(Side.white, const Duration(seconds: 9)), isTrue);
    expect(alarm.check(Side.white, const Duration(seconds: 8)), isFalse);
    expect(alarm.check(Side.black, const Duration(seconds: 9)), isTrue);
    expect(alarm.check(Side.white, const Duration(seconds: 11)), isFalse);
    expect(alarm.check(Side.white, const Duration(seconds: 9)), isTrue);
    alarm.reset();
    expect(alarm.check(Side.black, const Duration(seconds: 9)), isTrue);
  });
}
