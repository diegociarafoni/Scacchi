import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/levels.dart';

void main() {
  group('withinClock', () {
    test('con tempo abbondante il livello non cambia', () {
      final level = engineLevel(8);
      final timed = level.withinClock(
        const Duration(minutes: 30),
        Duration.zero,
      );
      expect(timed.movetime, level.movetime);
      expect(timed.minReply, level.minReply);
    });

    test('con poco tempo riduce riflessione e attesa', () {
      final timed = engineLevel(8)
          .withinClock(const Duration(seconds: 30), Duration.zero);
      expect(timed.movetime, const Duration(seconds: 1));
      final slow = engineLevel(1)
          .withinClock(const Duration(seconds: 3), Duration.zero);
      expect(slow.minReply, const Duration(milliseconds: 100));
    });

    test('conta l\'incremento e lascia un minimo di riflessione', () {
      expect(
        engineLevel(8)
            .withinClock(
              const Duration(seconds: 30),
              const Duration(seconds: 2),
            )
            .movetime,
        const Duration(milliseconds: 2000),
      );
      expect(
        engineLevel(8).withinClock(Duration.zero, Duration.zero).movetime,
        const Duration(milliseconds: 50),
      );
    });

    test('a 1+0 il livello 8 non esaurisce il tempo in 60 mosse', () {
      var remaining = const Duration(minutes: 1);
      for (var i = 0; i < 60; i++) {
        final level = engineLevel(8).withinClock(remaining, Duration.zero);
        remaining -= level.movetime + const Duration(milliseconds: 30);
      }
      expect(remaining, greaterThan(Duration.zero));
    });
  });

  group('engineLevelForElo', () {
    test('sceglie il livello con l\'Elo più vicino', () {
      expect(engineLevelForElo(400).id, 1);
      expect(engineLevelForElo(600).id, 1);
      expect(engineLevelForElo(1350).id, 4);
      expect(engineLevelForElo(1400).id, 4);
      expect(engineLevelForElo(5000).id, 8);
    });

    test('a pari distanza sceglie il più debole', () {
      var ties = 0;
      for (var i = 0; i + 1 < engineLevels.length; i++) {
        final low = engineLevels[i];
        final high = engineLevels[i + 1];
        final sum = low.approxElo + high.approxElo;
        if (sum.isOdd) continue;
        ties++;
        expect(engineLevelForElo(sum ~/ 2).id, low.id);
      }
      expect(ties, greaterThan(0));
    });
  });
}
