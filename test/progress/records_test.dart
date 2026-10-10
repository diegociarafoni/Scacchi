import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_tracker.dart';
import 'package:scacchi/progress/records.dart';

void main() {
  final tracker = ProgressTracker();
  const settings = ProgressSettings();
  final now = DateTime(2026, 10, 5, 12);

  ProgressUpdate rec(ProgressState s, Activity a) =>
      tracker.record(s, a, now, settings);

  test('RG-08 bot più forte battuto', () {
    var u = rec(
      ProgressState.initial,
      const GamePlayed(result: GameResult.win, opponentElo: 1200),
    );
    expect(u.newRecords, [RecordKind.strongestBot]);
    expect(u.state.records.strongestBot, 1200);
    u = rec(
      u.state,
      const GamePlayed(result: GameResult.win, opponentElo: 1000),
    );
    expect(u.newRecords, isEmpty);
    u = rec(
      u.state,
      const GamePlayed(result: GameResult.loss, opponentElo: 2000),
    );
    expect(u.state.records.strongestBot, 1200);
  });

  test('RG-08 vittoria più rapida', () {
    var u = rec(
      ProgressState.initial,
      const GamePlayed(result: GameResult.win, moveCount: 30),
    );
    expect(u.newRecords, contains(RecordKind.fastestWin));
    u = rec(u.state, const GamePlayed(result: GameResult.win, moveCount: 40));
    expect(u.newRecords, isEmpty);
    u = rec(u.state, const GamePlayed(result: GameResult.win, moveCount: 12));
    expect(u.state.records.fastestWin, 12);
  });

  test('RG-08 precisione migliore in revisione', () {
    var u = rec(ProgressState.initial, const ReviewCompleted(accuracy: 72.5));
    expect(u.newRecords, [RecordKind.bestAccuracy]);
    u = rec(u.state, const ReviewCompleted(accuracy: 70));
    expect(u.state.records.bestAccuracy, 72.5);
  });

  test('RG-08 punteggio migliore per modalità a tempo', () {
    var u = rec(
      ProgressState.initial,
      const PuzzleRunFinished(mode: 'rush5', score: 14),
    );
    expect(u.newRecords, [RecordKind.puzzleRun]);
    u = rec(u.state, const PuzzleRunFinished(mode: 'storm3', score: 9));
    expect(u.newRecords, [RecordKind.puzzleRun]);
    u = rec(u.state, const PuzzleRunFinished(mode: 'rush5', score: 10));
    expect(u.newRecords, isEmpty);
    expect(u.state.records.puzzleRuns, {'rush5': 14, 'storm3': 9});
  });

  test('RG-08 punteggio puzzle massimo', () {
    var u = rec(ProgressState.initial, const PuzzleSolved(rating: 1400));
    expect(u.newRecords, [RecordKind.puzzleRating]);
    u = rec(u.state, const PuzzleSolved(rating: 1300));
    expect(u.state.records.puzzleRating, 1400);
  });

  test('i record sopravvivono al salvataggio', () {
    final u = rec(
      ProgressState.initial,
      const PuzzleRunFinished(mode: 'streak', score: 7),
    );
    final json = u.state.toJson();
    expect(ProgressState.fromJson(json), u.state);
  });

  test('uno stato salvato prima di sfide e record si legge ancora', () {
    final old = {'xp': 120, 'gamesPlayed': 3};
    final s = ProgressState.fromJson(old);
    expect(s.xp, 120);
    expect(s.records, const PersonalRecords());
  });
}
