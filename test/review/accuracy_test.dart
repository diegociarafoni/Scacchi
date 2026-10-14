import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/review/accuracy.dart';

void main() {
  group('RF-63 precisione', () {
    test('una mossa che non perde nulla vale 100', () {
      expect(moveAccuracy(60, 60), closeTo(100, 0.1));
      expect(moveAccuracy(60, 70), closeTo(100, 0.1));
    });

    test('scende con la probabilità di vittoria persa', () {
      final small = moveAccuracy(60, 55);
      final big = moveAccuracy(60, 30);
      expect(small, lessThan(100));
      expect(big, lessThan(small));
      expect(moveAccuracy(100, 0), 0);
    });

    test('la precisione della partita penalizza gli errori isolati', () {
      final steady = gameAccuracy([90, 90, 90, 90]);
      final oneBlunder = gameAccuracy([100, 100, 100, 60]);
      expect(steady, closeTo(90, 0.01));
      // La media aritmetica sarebbe 90: la media armonica abbassa il voto.
      expect(oneBlunder, lessThan(90));
    });

    test('senza mosse non c\'è precisione', () {
      expect(gameAccuracy([]), isNull);
    });

    test('la stima della forza cresce con la precisione', () {
      final low = estimatedElo(55);
      final mid = estimatedElo(80);
      final high = estimatedElo(97);
      expect(low, lessThan(mid));
      expect(mid, lessThan(high));
      expect(estimatedElo(0), greaterThanOrEqualTo(100));
      expect(estimatedElo(100), lessThanOrEqualTo(3200));
    });
  });
}
