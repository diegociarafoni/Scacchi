import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/puzzles/puzzle_run.dart';
import 'package:rokko/puzzles/run_records.dart';
import 'package:rokko/storage/key_value_store.dart';

void main() {
  test('RG-08 salva il record per modalità e segnala quelli nuovi', () async {
    final store = MemoryStore();
    final records = await RunRecords.load(store);
    expect(records.best(PuzzleRunMode.storm), 0);
    expect(await records.submit(PuzzleRunMode.storm, 12), isTrue);
    expect(await records.submit(PuzzleRunMode.storm, 8), isFalse);
    expect(records.best(PuzzleRunMode.storm), 12);
    expect(records.best(PuzzleRunMode.streak), 0);
    expect((await RunRecords.load(store)).best(PuzzleRunMode.storm), 12);
  });
}
