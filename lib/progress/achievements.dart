import 'package:dartchess/dartchess.dart';

import 'activity.dart';
import 'progress_state.dart';
import 'xp.dart';

enum AchievementCategory { game, tactics, consistency, curiosity }

/// Traguardo sbloccabile una sola volta.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.test,
  });

  final String id;
  final String title;
  final String description;
  final AchievementCategory category;

  /// Vero se lo stato aggiornato dopo [activity] merita il traguardo.
  final bool Function(ProgressState state, Activity? activity) test;
}

bool _wonWith(Activity? a, bool Function(GamePlayed g) check) =>
    a is GamePlayed && a.result == GameResult.win && check(a);

final List<Achievement> achievements = [
  Achievement(
    id: 'first_game',
    title: 'Prima partita',
    description: 'Gioca la tua prima partita.',
    category: AchievementCategory.game,
    test: (s, _) => s.gamesPlayed >= 1,
  ),
  Achievement(
    id: 'first_win',
    title: 'Prima vittoria',
    description: 'Vinci una partita.',
    category: AchievementCategory.game,
    test: (s, _) => s.wins >= 1,
  ),
  Achievement(
    id: 'first_draw',
    title: 'Stretta di mano',
    description: 'Pareggia una partita.',
    category: AchievementCategory.game,
    test: (s, _) => s.draws >= 1,
  ),
  Achievement(
    id: 'games_10',
    title: 'Dieci partite',
    description: 'Gioca 10 partite.',
    category: AchievementCategory.game,
    test: (s, _) => s.gamesPlayed >= 10,
  ),
  Achievement(
    id: 'games_100',
    title: 'Cento partite',
    description: 'Gioca 100 partite.',
    category: AchievementCategory.game,
    test: (s, _) => s.gamesPlayed >= 100,
  ),
  Achievement(
    id: 'knight_mate',
    title: 'Cavaliere',
    description: 'Dai scacco matto con il cavallo.',
    category: AchievementCategory.tactics,
    test: (_, a) => _wonWith(a, (g) => g.matedWith == Role.knight),
  ),
  Achievement(
    id: 'pawn_mate',
    title: 'Umile eroe',
    description: 'Dai scacco matto con un pedone.',
    category: AchievementCategory.tactics,
    test: (_, a) => _wonWith(a, (g) => g.matedWith == Role.pawn),
  ),
  Achievement(
    id: 'long_castle_win',
    title: 'Lato di donna',
    description: 'Vinci una partita in cui hai arroccato lungo.',
    category: AchievementCategory.game,
    test: (_, a) => _wonWith(a, (g) => g.castledLong),
  ),
  Achievement(
    id: 'puzzles_10',
    title: 'Occhio tattico',
    description: 'Risolvi 10 puzzle.',
    category: AchievementCategory.tactics,
    test: (s, _) => s.puzzlesSolved >= 10,
  ),
  Achievement(
    id: 'puzzles_100',
    title: 'Cacciatore di tattiche',
    description: 'Risolvi 100 puzzle.',
    category: AchievementCategory.tactics,
    test: (s, _) => s.puzzlesSolved >= 100,
  ),
  Achievement(
    id: 'streak_3',
    title: 'Tre di fila',
    description: 'Raggiungi l\'obiettivo 3 giorni di fila.',
    category: AchievementCategory.consistency,
    test: (s, _) => s.bestStreak >= 3,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Una settimana',
    description: 'Raggiungi l\'obiettivo 7 giorni di fila.',
    category: AchievementCategory.consistency,
    test: (s, _) => s.bestStreak >= 7,
  ),
  Achievement(
    id: 'streak_30',
    title: 'Un mese',
    description: 'Raggiungi l\'obiettivo 30 giorni di fila.',
    category: AchievementCategory.consistency,
    test: (s, _) => s.bestStreak >= 30,
  ),
  Achievement(
    id: 'first_lesson',
    title: 'A lezione',
    description: 'Completa una lezione.',
    category: AchievementCategory.curiosity,
    test: (s, _) => s.lessonsCompleted >= 1,
  ),
  Achievement(
    id: 'first_review',
    title: 'Allo specchio',
    description: 'Rivedi una partita.',
    category: AchievementCategory.curiosity,
    test: (s, _) => s.reviewsCompleted >= 1,
  ),
  Achievement(
    id: 'level_5',
    title: 'Livello 5',
    description: 'Raggiungi il livello 5.',
    category: AchievementCategory.consistency,
    test: (s, _) => levelForXp(s.xp) >= 5,
  ),
  Achievement(
    id: 'level_10',
    title: 'Livello 10',
    description: 'Raggiungi il livello 10.',
    category: AchievementCategory.consistency,
    test: (s, _) => levelForXp(s.xp) >= 10,
  ),
];

Achievement? achievementById(String id) {
  for (final a in achievements) {
    if (a.id == id) return a;
  }
  return null;
}
