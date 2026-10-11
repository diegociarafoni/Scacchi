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

final List<Achievement> achievements = [..._base, ..._more];

final List<Achievement> _base = [
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

int _mateThemes(ProgressState s) => s.puzzleThemes.entries
    .where((e) => isMateTheme(e.key))
    .fold(0, (sum, e) => sum + e.value);

int _bestRun(ProgressState s) => s.records.puzzleRuns.values.fold(0, max);

final List<Achievement> _more = [
  Achievement(
    id: 'wins_10',
    title: 'Dieci vittorie',
    description: 'Vinci 10 partite.',
    category: AchievementCategory.game,
    test: (s, _) => s.wins >= 10,
  ),
  Achievement(
    id: 'wins_50',
    title: 'Cinquanta vittorie',
    description: 'Vinci 50 partite.',
    category: AchievementCategory.game,
    test: (s, _) => s.wins >= 50,
  ),
  Achievement(
    id: 'win_black',
    title: 'Dal lato oscuro',
    description: 'Vinci una partita con il nero.',
    category: AchievementCategory.game,
    test: (_, a) => _wonWith(a, (g) => g.playerSide == Side.black),
  ),
  Achievement(
    id: 'miniature',
    title: 'Miniatura',
    description: 'Dai scacco matto in meno di 20 mosse.',
    category: AchievementCategory.game,
    test: (_, a) => _wonWith(a, (g) => g.checkmate && (g.moveCount ?? 99) < 20),
  ),
  Achievement(
    id: 'beat_1500',
    title: 'Sfida seria',
    description: 'Batti un bot da 1500 Elo o più.',
    category: AchievementCategory.game,
    test: (s, _) => (s.records.strongestBot ?? 0) >= 1500,
  ),
  Achievement(
    id: 'beat_2000',
    title: 'Ammazzagiganti',
    description: 'Batti un bot da 2000 Elo o più.',
    category: AchievementCategory.game,
    test: (s, _) => (s.records.strongestBot ?? 0) >= 2000,
  ),
  Achievement(
    id: 'brilliant',
    title: 'Brillante!',
    description: 'Trova una mossa brillante in una tua partita.',
    category: AchievementCategory.tactics,
    test: (s, _) => s.brilliantFound >= 1,
  ),
  Achievement(
    id: 'puzzle_fork_10',
    title: 'Forchettone',
    description: 'Risolvi 10 puzzle di forchetta.',
    category: AchievementCategory.tactics,
    test: (s, _) => (s.puzzleThemes['fork'] ?? 0) >= 10,
  ),
  Achievement(
    id: 'puzzle_mate_10',
    title: 'Scacco matto!',
    description: 'Risolvi 10 puzzle di matto.',
    category: AchievementCategory.tactics,
    test: (s, _) => _mateThemes(s) >= 10,
  ),
  Achievement(
    id: 'puzzle_rating_1500',
    title: 'Tattico',
    description: 'Raggiungi 1500 di punteggio puzzle.',
    category: AchievementCategory.tactics,
    test: (s, _) => (s.records.puzzleRating ?? 0) >= 1500,
  ),
  Achievement(
    id: 'puzzle_run_20',
    title: 'In corsa',
    description: 'Fai 20 punti in una modalità a tempo o a serie.',
    category: AchievementCategory.tactics,
    test: (s, _) => _bestRun(s) >= 20,
  ),
  Achievement(
    id: 'challenges_all',
    title: 'Giornata perfetta',
    description: 'Completa tutte e tre le sfide del giorno.',
    category: AchievementCategory.consistency,
    test: (s, _) => s.perfectDays >= 1,
  ),
  Achievement(
    id: 'challenges_10',
    title: 'Sfidante',
    description: 'Completa 10 sfide giornaliere.',
    category: AchievementCategory.consistency,
    test: (s, _) => s.challengesCompleted >= 10,
  ),
  Achievement(
    id: 'reviews_10',
    title: 'Autocritica',
    description: 'Rivedi 10 partite.',
    category: AchievementCategory.curiosity,
    test: (s, _) => s.reviewsCompleted >= 10,
  ),
  Achievement(
    id: 'accuracy_90',
    title: 'Chirurgico',
    description: 'Gioca una partita con precisione del 90% o più.',
    category: AchievementCategory.curiosity,
    test: (s, _) => (s.records.bestAccuracy ?? 0) >= 90,
  ),
  Achievement(
    id: 'lessons_10',
    title: 'Studente',
    description: 'Completa 10 lezioni.',
    category: AchievementCategory.curiosity,
    test: (s, _) => s.lessonsCompleted >= 10,
  ),
  Achievement(
    id: 'coordinates_20',
    title: 'Occhio di lince',
    description: 'Trova 20 coordinate in una sessione a tempo.',
    category: AchievementCategory.curiosity,
    test: (s, _) => (s.records.minigames[Minigame.coordinates.id] ?? 0) >= 20,
  ),
  Achievement(
    id: 'minigames_all',
    title: 'Giocoliere',
    description: 'Prova tutti i minigiochi.',
    category: AchievementCategory.curiosity,
    test: (s, _) =>
        Minigame.values.every((m) => s.records.minigames.containsKey(m.id)),
  ),
  Achievement(
    id: 'tournament_done',
    title: 'Torneista',
    description: 'Porta a termine un torneo contro i bot.',
    category: AchievementCategory.game,
    test: (_, a) => a is TournamentFinished,
  ),
  Achievement(
    id: 'tournament_won',
    title: 'Coppa in bacheca',
    description: 'Vinci un torneo contro i bot.',
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
