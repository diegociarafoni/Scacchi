import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/puzzles/glicko2.dart';

void main() {
  group('RF-81 punteggio Glicko-2', () {
    test('riproduce l\'esempio dell\'articolo di Glickman', () {
      const player = Glicko2Rating(deviation: 200);
      final updated = player.update(const [
        GameResult(opponent: 1400, opponentDeviation: 30, score: 1),
        GameResult(opponent: 1550, opponentDeviation: 100, score: 0),
        GameResult(opponent: 1700, opponentDeviation: 300, score: 0),
      ], tau: 0.5);
      expect(updated.rating, closeTo(1464.06, 0.05));
      expect(updated.deviation, closeTo(151.52, 0.05));
      expect(updated.volatility, closeTo(0.05999, 0.0001));
    });

    test('vincere contro un puzzle difficile fa salire il punteggio', () {
      const player = Glicko2Rating(deviation: 150);
      final up = player.update(const [
        GameResult(opponent: 1900, opponentDeviation: 75, score: 1),
      ]);
      final down = player.update(const [
        GameResult(opponent: 1100, opponentDeviation: 75, score: 0),
      ]);
      expect(up.rating, greaterThan(1550));
      expect(down.rating, lessThan(1450));
    });

    test('la deviazione non scende sotto il minimo', () {
      var r = const Glicko2Rating(deviation: 60);
      for (var i = 0; i < 50; i++) {
        r = r.update(const [
          GameResult(opponent: 1500, opponentDeviation: 75, score: 0.5),
        ]);
      }
      expect(r.deviation, greaterThanOrEqualTo(Glicko2Rating.minDeviation));
    });

    test('serializza in JSON e ritorno', () {
      const r = Glicko2Rating(rating: 1612.5, deviation: 88, volatility: 0.07);
      expect(Glicko2Rating.fromJson(r.toJson()), r);
    });
  });
}
