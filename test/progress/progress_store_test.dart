import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/progress/activity.dart';
import 'package:rokko/progress/daily_goal.dart';
import 'package:rokko/progress/progress_state.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/progress/progress_tracker.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('progress');
    file = File('${dir.path}/progress.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('senza file restituisce lo stato iniziale', () async {
    final data = await ProgressStore(file).load();
    expect(data.state, ProgressState.initial);
    expect(data.settings, const ProgressSettings());
  });

  test('salva e ricarica stato e impostazioni', () async {
    const settings = ProgressSettings(
      enabled: false,
      goal: DailyGoal(GoalKind.minutes, 10),
      restDay: DateTime.sunday,
    );
    final state = ProgressTracker()
        .record(
          ProgressState.initial,
          const GamePlayed(result: GameResult.win),
          DateTime(2026, 10, 5),
          const ProgressSettings(),
        )
        .state;
    await ProgressStore(file).save(ProgressData(state, settings));
    final loaded = await ProgressStore(file).load();
    expect(loaded.state, state);
    expect(loaded.settings, settings);
  });

  test('un file illeggibile non blocca l\'app', () async {
    file.writeAsStringSync('{non json');
    final data = await ProgressStore(file).load();
    expect(data.state, ProgressState.initial);
  });

  test('un file illeggibile viene conservato a parte', () async {
    file.writeAsStringSync('{non json');
    await ProgressStore(file).load();
    final backups = dir.listSync().where((f) => f.path.contains('.bad'));
    expect(backups, hasLength(1));
    expect(File(backups.single.path).readAsStringSync(), '{non json');
  });

  test('una versione futura dello schema non viene sovrascritta', () async {
    file.writeAsStringSync('{"version":99,"state":{},"settings":{}}');
    final data = await ProgressStore(file).load();
    expect(data.state, ProgressState.initial);
    expect(dir.listSync().where((f) => f.path.contains('.bad')), hasLength(1));
  });

  test('salvataggi ravvicinati non si sovrappongono', () async {
    final store = ProgressStore(file);
    await Future.wait([
      for (var i = 1; i <= 5; i++)
        store.save(
          ProgressData(ProgressState(xp: i), const ProgressSettings()),
        ),
    ]);
    expect((await store.load()).state.xp, 5);
  });

  test('il file porta la versione dello schema', () async {
    await ProgressStore(file)
        .save(const ProgressData(ProgressState.initial, ProgressSettings()));
    expect(file.readAsStringSync(), contains('"version":1'));
  });
}
