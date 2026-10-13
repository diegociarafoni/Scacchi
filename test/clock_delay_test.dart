import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/clock.dart';

import 'clock_test.dart' show FakeTime;

void main() {
  group('RF-40 etichetta e lettura della cadenza', () {
    test('senza ritardo l\'etichetta resta minuti+incremento', () {
      expect(const TimeControl(minutes: 5, increment: 3).label, '5+3');
      expect(
        TimeControl.parse('5+3'),
        const TimeControl(minutes: 5, increment: 3),
      );
    });

    test('il ritardo semplice e quello di Bronstein si riconoscono', () {
      const simple = TimeControl(minutes: 10, delay: 5);
      const bronstein = TimeControl(
        minutes: 10,
        delay: 5,
        delayType: DelayType.bronstein,
      );
      expect(simple.label, '10+0/d5');
      expect(bronstein.label, '10+0/b5');
      expect(TimeControl.parse(simple.label), simple);
      expect(TimeControl.parse(bronstein.label), bronstein);
      expect(simple, isNot(bronstein));
    });

    test('le etichette non valide non si leggono', () {
      for (final bad in ['10+0/x5', '10+0/d', '10+0/d-1', '0+0/d5', '10/d5']) {
        expect(TimeControl.parse(bad), isNull, reason: bad);
      }
    });

    test('con il ritardo una cadenza resta della stessa famiglia', () {
      expect(
        const TimeControl(minutes: 10, delay: 5).category,
        TimeCategory.rapid,
      );
    });
  });

  group('RF-40 ritardo nell\'orologio', () {
    late FakeTime time;
    ChessClock clock(TimeControl control) =>
        ChessClock(control, now: () => time.now);

    setUp(() => time = FakeTime());

    test('col ritardo semplice il tempo non scorre nei primi secondi', () {
      final c = clock(const TimeControl(minutes: 5, delay: 5))
        ..start(Side.white);
      time.advance(const Duration(seconds: 4));
      expect(c.remaining(Side.white), const Duration(minutes: 5));
      time.advance(const Duration(seconds: 6));
      expect(c.remaining(Side.white), const Duration(minutes: 5, seconds: -5));
    });

    test('il ritardo semplice non si accumula tra una mossa e l\'altra', () {
      final c = clock(const TimeControl(minutes: 5, delay: 5))
        ..start(Side.white);
      time.advance(const Duration(seconds: 3));
      c.switchAfterMove();
      time.advance(const Duration(seconds: 2));
      c.switchAfterMove();
      expect(c.remaining(Side.white), const Duration(minutes: 5));
      expect(c.remaining(Side.black), const Duration(minutes: 5));
    });

    test('una pausa non rinnova il ritardo già consumato', () {
      final c = clock(const TimeControl(minutes: 5, delay: 5))
        ..start(Side.white);
      time.advance(const Duration(seconds: 4));
      c.pause();
      c.start(Side.white);
      time.advance(const Duration(seconds: 3));
      expect(c.remaining(Side.white), const Duration(minutes: 5, seconds: -2));
    });

    test('con Bronstein si restituisce il tempo usato, fino al ritardo', () {
      final c = clock(
        const TimeControl(minutes: 5, delay: 5, delayType: DelayType.bronstein),
      )..start(Side.white);
      time.advance(const Duration(seconds: 3));
      c.switchAfterMove();
      expect(c.remaining(Side.white), const Duration(minutes: 5));
      time.advance(const Duration(seconds: 8));
      c.switchAfterMove();
      expect(c.remaining(Side.black), const Duration(minutes: 5, seconds: -3));
    });

    test('il ritardo si somma all\'incremento', () {
      final c = clock(const TimeControl(minutes: 5, increment: 2, delay: 5))
        ..start(Side.white);
      time.advance(const Duration(seconds: 3));
      c.switchAfterMove();
      expect(c.remaining(Side.white), const Duration(minutes: 5, seconds: 2));
    });

    test('il tempo non va sotto zero e la caduta della bandierina resta', () {
      final c = clock(const TimeControl(minutes: 1, delay: 5))
        ..start(Side.white);
      time.advance(const Duration(seconds: 70));
      expect(c.remaining(Side.white), Duration.zero);
      expect(c.flagged, Side.white);
    });
  });
}
