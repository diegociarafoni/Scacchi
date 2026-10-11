import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/review/win_probability.dart';

void main() {
  group('RF-61 probabilità di vittoria', () {
    test('posizione pari vale 50%', () {
      expect(winPercent(const EngineScore.cp(0)), closeTo(50, 1e-9));
    });

    test('è simmetrica rispetto al cambio di prospettiva', () {
      final w = winPercent(const EngineScore.cp(230));
      final b = winPercent(const EngineScore.cp(-230));
      expect(w + b, closeTo(100, 1e-9));
    });

    test('cresce con il vantaggio e satura nelle posizioni decise', () {
      final a = winPercent(const EngineScore.cp(100));
      final b = winPercent(const EngineScore.cp(300));
      expect(a, greaterThan(50));
      expect(b, greaterThan(a));
      // Mille o duemila centipedoni sono entrambi partita vinta.
      expect(
        winPercent(const EngineScore.cp(2000)) -
            winPercent(const EngineScore.cp(1000)),
        lessThan(0.5),
      );
    });

    test('un pezzo di vantaggio vale circa il 75%', () {
      expect(winPercent(const EngineScore.cp(300)), inInclusiveRange(70, 80));
    });

    test('il matto a favore vale 100%, a sfavore 0%', () {
      expect(winPercent(const EngineScore.mate(3)), 100);
      expect(winPercent(const EngineScore.mate(-2)), 0);
      expect(winPercent(const EngineScore.mate(0)), 0);
    });
  });
}
