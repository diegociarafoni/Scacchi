import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../minigames/minigame.dart';
import 'activity.dart';
import 'challenges.dart';
import 'progress_state.dart';
import 'xp.dart';

enum AchievementCategory { game, tactics, consistency, curiosity }

/// Traguardo sbloccabile una sola volta.
class Achievement {
  const Achievement({
    required this.id,
    required this.category,
    required this.test,
  });

  final String id;
  final AchievementCategory category;

  /// Vero se lo stato aggiornato dopo [activity] merita il traguardo.
  final bool Function(ProgressState state, Activity? activity) test;
}

bool _wonWith(Activity? a, bool Function(GamePlayed g) check) =>
    a is GamePlayed && a.result == GameResult.win && check(a);

final List<Achievement> achievements = [..._base, ..._more];

/// Traguardi che misurano il giocatore (livello, Elo, punteggi, precisione,
/// serie): nel profilo bambino non si elencano, ma si sbloccano comunque.
const kidHiddenAchievements = {
  'level_5',
  'level_10',
  'beat_1500',
  'beat_2000',
  'puzzle_rating_1500',
  'puzzle_run_20',
  'accuracy_90',
  'streak_3',
  'streak_7',
  'streak_30',
};

final List<Achievement> _base = [
  Achievement(
    id: 'first_game',
    category: AchievementCategory.game,
    test: (s, _) => s.gamesPlayed >= 1,
  ),
  Achievement(
    id: 'first_win',
    category: AchievementCategory.game,
    test: (s, _) => s.wins >= 1,
  ),
  Achievement(
    id: 'first_draw',
    category: AchievementCategory.game,
    test: (s, _) => s.draws >= 1,
  ),
  Achievement(
    id: 'games_10',
    category: AchievementCategory.game,
    test: (s, _) => s.gamesPlayed >= 10,
  ),
  Achievement(
    id: 'games_100',
    category: AchievementCategory.game,
    test: (s, _) => s.gamesPlayed >= 100,
  ),
  Achievement(
    id: 'knight_mate',
    category: AchievementCategory.tactics,
    test: (_, a) => _wonWith(a, (g) => g.matedWith == Role.knight),
  ),
  Achievement(
    id: 'pawn_mate',
    category: AchievementCategory.tactics,
    test: (_, a) => _wonWith(a, (g) => g.matedWith == Role.pawn),
  ),
  Achievement(
    id: 'long_castle_win',
    category: AchievementCategory.game,
    test: (_, a) => _wonWith(a, (g) => g.castledLong),
  ),
  Achievement(
    id: 'puzzles_10',
    category: AchievementCategory.tactics,
    test: (s, _) => s.puzzlesSolved >= 10,
  ),
  Achievement(
    id: 'puzzles_100',
    category: AchievementCategory.tactics,
    test: (s, _) => s.puzzlesSolved >= 100,
  ),
  Achievement(
    id: 'streak_3',
    category: AchievementCategory.consistency,
    test: (s, _) => s.bestStreak >= 3,
  ),
  Achievement(
    id: 'streak_7',
    category: AchievementCategory.consistency,
    test: (s, _) => s.bestStreak >= 7,
  ),
  Achievement(
    id: 'streak_30',
    category: AchievementCategory.consistency,
    test: (s, _) => s.bestStreak >= 30,
  ),
  Achievement(
    id: 'first_lesson',
    category: AchievementCategory.curiosity,
    test: (s, _) => s.lessonsCompleted >= 1,
  ),
  Achievement(
    id: 'first_review',
    category: AchievementCategory.curiosity,
    test: (s, _) => s.reviewsCompleted >= 1,
  ),
  Achievement(
    id: 'level_5',
    category: AchievementCategory.consistency,
    test: (s, _) => levelForXp(s.xp) >= 5,
  ),
  Achievement(
    id: 'level_10',
    category: AchievementCategory.consistency,
    test: (s, _) => levelForXp(s.xp) >= 10,
  ),
];

int _mateThemes(ProgressState s) => s.puzzleThemes.entries
    .where((e) => isMateTheme(e.key))
    .fold(0, (sum, e) => sum + e.value);

int _bestRun(ProgressState s) => s.records.puzzleRuns.values.fold(0, max);

final List<Achievement> _more = [
  Achievement(
    id: 'wins_10',
    category: AchievementCategory.game,
    test: (s, _) => s.wins >= 10,
  ),
  Achievement(
    id: 'wins_50',
    category: AchievementCategory.game,
    test: (s, _) => s.wins >= 50,
  ),
  Achievement(
    id: 'win_black',
    category: AchievementCategory.game,
    test: (_, a) => _wonWith(a, (g) => g.playerSide == Side.black),
  ),
  Achievement(
    id: 'miniature',
    category: AchievementCategory.game,
    test: (_, a) => _wonWith(a, (g) => g.checkmate && (g.moveCount ?? 99) < 20),
  ),
  Achievement(
    id: 'beat_1500',
    category: AchievementCategory.game,
    test: (s, _) => (s.records.strongestBot ?? 0) >= 1500,
  ),
  Achievement(
    id: 'beat_2000',
    category: AchievementCategory.game,
    test: (s, _) => (s.records.strongestBot ?? 0) >= 1850,
  ),
  Achievement(
    id: 'brilliant',
    category: AchievementCategory.tactics,
    test: (s, _) => s.brilliantFound >= 1,
  ),
  Achievement(
    id: 'puzzle_fork_10',
    category: AchievementCategory.tactics,
    test: (s, _) => (s.puzzleThemes['fork'] ?? 0) >= 10,
  ),
  Achievement(
    id: 'puzzle_mate_10',
    category: AchievementCategory.tactics,
    test: (s, _) => _mateThemes(s) >= 10,
  ),
  Achievement(
    id: 'puzzle_rating_1500',
    category: AchievementCategory.tactics,
    test: (s, _) => (s.records.puzzleRating ?? 0) >= 1500,
  ),
  Achievement(
    id: 'puzzle_run_20',
    category: AchievementCategory.tactics,
    test: (s, _) => _bestRun(s) >= 20,
  ),
  Achievement(
    id: 'challenges_all',
    category: AchievementCategory.consistency,
    test: (s, _) => s.perfectDays >= 1,
  ),
  Achievement(
    id: 'challenges_10',
    category: AchievementCategory.consistency,
    test: (s, _) => s.challengesCompleted >= 10,
  ),
  Achievement(
    id: 'reviews_10',
    category: AchievementCategory.curiosity,
    test: (s, _) => s.reviewsCompleted >= 10,
  ),
  Achievement(
    id: 'accuracy_90',
    category: AchievementCategory.curiosity,
    test: (s, _) => (s.records.bestAccuracy ?? 0) >= 90,
  ),
  Achievement(
    id: 'lessons_10',
    category: AchievementCategory.curiosity,
    test: (s, _) => s.lessonsCompleted >= 10,
  ),
  Achievement(
    id: 'coordinates_20',
    category: AchievementCategory.curiosity,
    test: (s, _) => (s.records.minigames[Minigame.coordinates.id] ?? 0) >= 20,
  ),
  Achievement(
    id: 'minigames_all',
    category: AchievementCategory.curiosity,
    test: (s, _) =>
        Minigame.values.every((m) => s.records.minigames.containsKey(m.id)),
  ),
  Achievement(
    id: 'tournament_done',
    category: AchievementCategory.game,
    test: (_, a) => a is TournamentFinished,
  ),
  Achievement(
    id: 'tournament_won',
    category: AchievementCategory.game,
    test: (_, a) => a is TournamentFinished && a.rank == 1,
  ),
];

Achievement? achievementById(String id) {
  for (final a in achievements) {
    if (a.id == id) return a;
  }
  return null;
}
