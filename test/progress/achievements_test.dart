import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/achievements.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_tracker.dart';

void main() {
  final tracker = ProgressTracker();
  const settings = ProgressSettings();
  final now = DateTime(2026, 10, 5, 12);

  List<String> unlockedBy(Activity a, [ProgressState? s]) => tracker
      .record(s ?? ProgressState.initial, a, now, settings)
      .unlocked
      .map((a) => a.id)
      .toList();

  test('RG-05 almeno 30 traguardi in quattro categorie', () {
    expect(achievements.length, greaterThanOrEqualTo(30));
    expect(
      achievements.map((a) => a.category).toSet(),
      AchievementCategory.values.toSet(),
    );
  });

  test('vittoria con il nero', () {
    expect(
      unlockedBy(
        const GamePlayed(result: GameResult.win, playerSide: Side.black),
      ),
      contains('win_black'),
    );
  });

  test('miniatura: vittoria in meno di 20 mosse', () {
    expect(
      unlockedBy(
        const GamePlayed(
          result: GameResult.win,
          moveCount: 15,
          checkmate: true,
        ),
      ),
      contains('miniature'),
    );
    expect(
      unlockedBy(const GamePlayed(result: GameResult.win, moveCount: 15)),
      isNot(contains('miniature')),
    );
    expect(
      unlockedBy(const GamePlayed(result: GameResult.win, moveCount: 25)),
      isNot(contains('miniature')),
    );
  });

  test('bot forti battuti', () {
    expect(
      unlockedBy(const GamePlayed(result: GameResult.win, opponentElo: 1600)),
      contains('beat_1500'),
    );
  });

  test('brillante trovata', () {
    expect(
      unlockedBy(const ReviewCompleted(brilliantMoves: 1)),
      contains('brilliant'),
    );
  });

  test('precisione del 90%', () {
    expect(
      unlockedBy(const ReviewCompleted(accuracy: 91)),
      contains('accuracy_90'),
    );
  });

  test('10 puzzle di forchetta', () {
    var s = ProgressState.initial;
    final ids = <String>[];
    for (var i = 0; i < 10; i++) {
      final u = tracker.record(
        s,
        const PuzzleSolved(themes: {'fork'}),
        now,
        settings,
      );
      s = u.state;
      ids.addAll(u.unlocked.map((a) => a.id));
    }
    expect(ids, contains('puzzle_fork_10'));
  });

  test('serie di 20 in una modalità a tempo', () {
    expect(
      unlockedBy(const PuzzleRunFinished(mode: 'streak', score: 20)),
      contains('puzzle_run_20'),
    );
  });

  test('RG-10 venti coordinate in una sessione', () {
    expect(
      unlockedBy(const MinigameFinished(game: 'coordinate', score: 19)),
      isNot(contains('coordinates_20')),
    );
    expect(
      unlockedBy(const MinigameFinished(game: 'coordinate', score: 20)),
      contains('coordinates_20'),
    );
  });

  test('RG-10 tutti i minigiochi provati', () {
    var s = ProgressState.initial;
    final ids = <String>[];
    for (final game in ['coordinate', 'cattura', 'cieca', 'materiale']) {
      final u = tracker.record(
        s,
        MinigameFinished(game: game, score: 1),
        now,
        settings,
      );
      ids.addAll(u.unlocked.map((a) => a.id));
      s = u.state;
    }
    expect(ids.where((id) => id == 'minigames_all'), hasLength(1));
  });
}
