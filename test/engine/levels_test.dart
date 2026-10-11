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
}
