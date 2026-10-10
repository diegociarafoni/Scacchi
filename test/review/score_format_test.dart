import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/review/score_format.dart';

void main() {
  group('RF-50 valore numerico della valutazione', () {
    test('centipedoni in pedoni con segno', () {
      expect(formatScore(const EngineScore.cp(34)), '+0.3');
      expect(formatScore(const EngineScore.cp(-250)), '−2.5');
      expect(formatScore(const EngineScore.cp(0)), '0.0');
    });

    test('matto in N', () {
      expect(formatScore(const EngineScore.mate(3)), 'M3');
      expect(formatScore(const EngineScore.mate(-2)), '−M2');
    });

    test('scacco matto avvenuto', () {
      expect(formatScore(const EngineScore.mate(0)), '#');
    });

    test('descrizione per i lettori di schermo', () {
      expect(describeScore(const EngineScore.cp(150)), 'Bianco avanti di 1.5');
      expect(describeScore(const EngineScore.cp(-40)), 'Nero avanti di 0.4');
      expect(describeScore(const EngineScore.cp(5)), 'Parità');
      expect(
        describeScore(const EngineScore.mate(2)),
        'Matto in 2 per il Bianco',
      );
      expect(
        describeScore(const EngineScore.mate(-1)),
        'Matto in 1 per il Nero',
      );
    });
  });
}
