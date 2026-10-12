import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/clock.dart';
import 'package:scacchi/review/move_time.dart';

Duration s(int n) => Duration(seconds: n);

void main() {
  const control = TimeControl(minutes: 1, increment: 2);

  group('timeSpent con tempi iniziali diversi (RF-27)', () {
    test('la prima mossa di ogni lato parte dal suo tempo', () {
      final spent = timeSpent(
        [s(58), s(55), s(50)],
        first: Side.white,
        control: control,
        startTimes: {Side.white: s(60), Side.black: s(180)},
      );
      // Bianco 60 → 58; Nero 180 → 55; Bianco 58 + 2 − 50.
      expect(spent, [s(2), s(125), s(10)]);
    });
  });

  group('timeSpent (RF-67)', () {
    test(
      'differenza tra i tempi residui dello stesso lato più l\'incremento',
      () {
        // Bianco: 60 → 55 (5 s di riflessione) → 50; Nero: 60 → 58 → 52.
        final spent = timeSpent(
          [s(60), s(60), s(57), s(60), s(52)],
          first: Side.white,
          control: control,
        );
        // La prima mossa non incrementa: ply 0 e 1 costano 0 e 0 dal residuo
        // iniziale (60); poi 60 + 2 − 57 = 5, 60 + 2 − 60 = 2, 57 + 2 − 52 = 7.
        expect(spent, [s(0), s(0), s(5), s(2), s(7)]);
      },
    );

    test('senza orologio o senza cadenza non si sa quanto è durata', () {
      expect(timeSpent([null, null], first: Side.white, control: control), [
        null,
        null,
      ]);
      // Senza cadenza manca il tempo iniziale: la prima mossa di ogni lato è
      // ignota, le successive si calcolano (senza incremento noto).
      expect(timeSpent([s(58), s(59), s(50)], first: Side.white), [
        null,
        null,
        s(8),
      ]);
      expect(
        timeSpent(
          [s(58), s(59), s(50), s(55)],
          first: Side.white,
          control: const TimeControl(minutes: 1),
        ),
        [s(2), s(1), s(8), s(4)],
      );
    });

    test('non è mai negativo', () {
      expect(timeSpent([s(70)], first: Side.white, control: control), [
        Duration.zero,
      ]);
    });

    test('parte dal lato che muove per primo', () {
      final spent = timeSpent(
        [s(50)],
        first: Side.black,
        control: const TimeControl(minutes: 1),
      );
      expect(spent, [s(10)]);
    });
  });

  group('hastyPlies', () {
    List<Duration?> spent(List<int> seconds) => [for (final n in seconds) s(n)];

    test('errori giocati in meno del 40% del proprio tempo medio', () {
      // Bianco muove ai ply pari: media 10 s; ply 4 dura 2 s ed è un errore.
      final times = spent([10, 8, 10, 8, 2, 8, 18, 8]);
      final hasty = hastyPlies(
        times,
        sides: [for (var i = 0; i < 8; i++) i.isEven ? Side.white : Side.black],
        isError: (ply) => ply == 4 || ply == 2,
      );
      expect(hasty, [4]);
    });

    test('con poche mosse cronometrate non giudica', () {
      final times = spent([10, 8, 1]);
      expect(
        hastyPlies(
          times,
          sides: [Side.white, Side.black, Side.white],
          isError: (_) => true,
        ),
        isEmpty,
      );
    });

    test('con tempi medi molto brevi non giudica', () {
      final times = spent([1, 1, 1, 1, 0, 1, 1, 1]);
      expect(
        hastyPlies(
          times,
          sides: [
            for (var i = 0; i < 8; i++) i.isEven ? Side.white : Side.black,
          ],
          isError: (_) => true,
        ),
        isEmpty,
      );
    });

    test('ignora le mosse senza tempo', () {
      final times = <Duration?>[null, null, null, null, null, null, null, null];
      expect(
        hastyPlies(
          times,
          sides: [
            for (var i = 0; i < 8; i++) i.isEven ? Side.white : Side.black,
          ],
          isError: (_) => true,
        ),
        isEmpty,
      );
    });
  });
}
