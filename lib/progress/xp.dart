import 'activity.dart';

/// XP extra il giorno in cui si raggiunge l'obiettivo giornaliero.
const int dailyGoalBonusXp = 10;

/// XP extra per una sfida giornaliera e per la sfida settimanale completate.
const int dailyChallengeBonusXp = 20;
const int weeklyChallengeBonusXp = 50;

/// XP per attività: le attività formative valgono più della sola vittoria.
int xpFor(Activity activity) => switch (activity) {
  GamePlayed(result: GameResult.win) => 15,
  GamePlayed(result: GameResult.draw) => 12,
  GamePlayed() => 10,
  PuzzleSolved() => 5,
  PuzzleRunFinished() => 10,
  // Una sessione senza punti non vale XP, per non premiare i tocchi a caso.
  MinigameFinished(:final score) => score > 0 ? 5 : 0,
  LessonCompleted() => 20,
  TournamentFinished() => 30,
  ReviewCompleted() => 20,
};

/// XP totali necessari per raggiungere [level]: 0, 100, 300, 600, 1000...
int xpForLevel(int level) => 50 * level * (level - 1);

int levelForXp(int xp) {
  var level = 1;
  while (xpForLevel(level + 1) <= xp) {
    level++;
  }
  return level;
}

/// Frazione del livello corrente già completata, tra 0 e 1.
double levelProgress(int xp) {
  final level = levelForXp(xp);
  final start = xpForLevel(level);
  return (xp - start) / (xpForLevel(level + 1) - start);
}
