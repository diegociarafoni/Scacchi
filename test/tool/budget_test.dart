import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/budget.dart';

void main() {
  group('dimensione dell\'APK', () {
    test('accetta un file entro il limite', () {
      final v = checkApkSize(60 * 1024 * 1024, maxMegabytes: 80);
      expect(v.ok, isTrue);
      expect(v.message, contains('60,0 MB'));
    });

    test('accetta esattamente il limite', () {
      expect(checkApkSize(80 * 1024 * 1024, maxMegabytes: 80).ok, isTrue);
    });

    test('rifiuta un file oltre il limite', () {
      final v = checkApkSize(80 * 1024 * 1024 + 1, maxMegabytes: 80);
      expect(v.ok, isFalse);
      expect(v.message, contains('80 MB'));
    });
  });

  group('fluidità', () {
    const budget = FrameBudget(minFrames: 50, p90BuildMs: 16, p99BuildMs: 32);

    Map<String, dynamic> report({
      num frames = 200,
      num p90 = 8,
      num p99 = 20,
    }) => {
      'frame_count': frames,
      '90th_percentile_frame_build_time_millis': p90,
      '99th_percentile_frame_build_time_millis': p99,
      'worst_frame_build_time_millis': 40,
    };

    test('nessuna violazione dentro il budget', () {
      expect(frameViolations(report(), budget), isEmpty);
    });

    test('segnala il 90° percentile troppo alto', () {
      final v = frameViolations(report(p90: 17), budget);
      expect(v, hasLength(1));
      expect(v.single, contains('90°'));
    });

    test('segnala il 99° percentile troppo alto', () {
      final v = frameViolations(report(p99: 33), budget);
      expect(v.single, contains('99°'));
    });

    test('una misura con pochi fotogrammi non è valida', () {
      final v = frameViolations(report(frames: 10), budget);
      expect(v.single, contains('fotogrammi'));
    });

    test('un rapporto senza i campi attesi non è valido', () {
      expect(frameViolations({}, budget), isNotEmpty);
    });
  });

  test('il budget si legge dalla policy', () {
    final b = FrameBudget.fromJson({
      'budget': {
        'frames': {'minFrames': 30, 'p90BuildMs': 20, 'p99BuildMs': 50},
      },
    });
    expect(b.minFrames, 30);
    expect(b.p90BuildMs, 20);
    expect(b.p99BuildMs, 50);
  });

  test('una chiave mancante nella policy dà un errore chiaro', () {
    expect(
      () => FrameBudget.fromJson({'budget': <String, dynamic>{}}),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('budget.frames.minFrames'),
        ),
      ),
    );
    expect(
      () => budgetValue(
        {
          'budget': {'apkMaxMegabytes': 'x'},
        },
        ['apkMaxMegabytes'],
      ),
      throwsFormatException,
    );
  });

  group('avvio', () {
    test('accetta un avvio entro il limite, anche esattamente al limite', () {
      expect(startupViolations({'startup_ms': 1200}, maxMs: 2000), isEmpty);
      expect(startupViolations({'startup_ms': 2000}, maxMs: 2000), isEmpty);
    });

    test('segnala un avvio troppo lento', () {
      final v = startupViolations({'startup_ms': 2001}, maxMs: 2000);
      expect(v.single, contains('2001 ms'));
      expect(v.single, contains('2000 ms'));
    });

    test('un rapporto senza il tempo di avvio non è valido', () {
      expect(startupViolations({}, maxMs: 2000), isNotEmpty);
    });
  });
}
