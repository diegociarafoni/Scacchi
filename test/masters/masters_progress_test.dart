import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/masters/masters_controller.dart';
import 'package:scacchi/masters/masters_progress.dart';
import 'package:scacchi/progress/activity.dart';

void main() {
  test('RF-88 si tiene il risultato migliore', () {
    final p = const MastersProgress()
        .record('a', 80)
        .record('a', 40)
        .record('b', 55);
    expect(p.bestPercent('a'), 80);
    expect(p.bestPercent('b'), 55);
    expect(p.bestPercent('zzz'), isNull);
    expect(p.starsFor('a'), 3);
    expect(p.starsFor('b'), 2);
    expect(p.starsFor('zzz'), 0);
  });

  test('JSON andata e ritorno', () {
    final p = const MastersProgress().record('a', 61);
    expect(MastersProgress.fromJson(p.toJson()).bestPercent('a'), 61);
  });

  group('controller', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('maestri'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('RF-88 salva e registra l\'attività solo la prima volta', () async {
      final events = <Activity>[];
      final file = File('${dir.path}/masters.json');
      final c = MastersController(
        file,
        recordActivity: (e) async {
          events.add(e);
        },
      );
      await c.load();
      await c.finish('a', 40, const Duration(minutes: 3));
      await c.finish('a', 90, const Duration(minutes: 3));
      expect(events.length, 1);
      expect(events.single, isA<LessonCompleted>());
      expect(c.progress.bestPercent('a'), 90);

      final again = MastersController(file);
      await again.load();
      expect(again.progress.bestPercent('a'), 90);
    });

    test(
      'RF-88 il risultato si salva anche se i progressi falliscono',
      () async {
        final file = File('${dir.path}/masters.json');
        final c = MastersController(
          file,
          recordActivity: (_) async {
            throw StateError('progressi non scrivibili');
          },
        );
        await c.load();
        await c.finish('a', 75, const Duration(minutes: 1));
        final again = MastersController(file);
        await again.load();
        expect(again.progress.bestPercent('a'), 75);
      },
    );
  });
}
