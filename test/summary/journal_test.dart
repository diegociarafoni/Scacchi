import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/summary/week_log.dart';

void main() {
  final now = DateTime(2026, 10, 12, 9);
  late Directory dir;
  late File weekFile;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('journal');
    weekFile = File('${dir.path}/week.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  ProgressController controller() => ProgressController(
    ProgressStore(File('${dir.path}/p.json')),
    clock: () => now,
    journal: WeekLogStore(weekFile),
  );

  test('RG-16 ogni attività registrata entra nel diario e nel file', () async {
    final c = controller();
    await c.load();
    await c.record(const PuzzleSolved());
    await c.record(
      const ReviewCompleted(gameId: 'a', errorThemes: {'allowedPin': 2}),
    );
    expect(c.weekLog.dayOf(now)!.puzzles, 1);

    final again = controller();
    await again.load();
    expect(again.weekLog.dayOf(now)!.errors, {'allowedPin': 2});
  });

  test('RG-12 con i progressi disattivati il diario non registra', () async {
    final c = controller();
    await c.load();
    await c.updateSettings(const ProgressSettings(enabled: false));
    await c.record(const PuzzleSolved());
    expect(c.weekLog.isEmpty, isTrue);
  });
}
