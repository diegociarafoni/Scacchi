import '../settings/settings.dart';
import 'achievements.dart';
import 'avatar.dart';
import 'progress_state.dart';
import 'xp.dart';

/// Condizione per sbloccare una ricompensa estetica.
sealed class Requirement {
  const Requirement();

  bool isMet(ProgressState state);

  /// Testo breve per l'utente, per esempio "Livello 4".
  String get label;
}

class LevelRequirement extends Requirement {
  const LevelRequirement(this.level, {this.keptAchievement});

  final int level;

  /// Traguardo che un tempo sbloccava la ricompensa: chi lo ha già la tiene.
  final String? keptAchievement;

  @override
  bool isMet(ProgressState state) =>
      levelForXp(state.xp) >= level ||
      (keptAchievement != null && state.unlocked.contains(keptAchievement));

  @override
  String get label => 'Livello $level';

  @override
  bool operator ==(Object other) =>
      other is LevelRequirement &&
      other.level == level &&
      other.keptAchievement == keptAchievement;

  @override
  int get hashCode => Object.hash(level, keptAchievement);
}

class AchievementRequirement extends Requirement {
  const AchievementRequirement(this.id);

  final String id;

  @override
  bool isMet(ProgressState state) => state.unlocked.contains(id);

  @override
  String get label => 'Traguardo «${achievementById(id)!.title}»';

  @override
  bool operator ==(Object other) =>
      other is AchievementRequirement && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Testi dell'interruttore che rende disponibili tutte le ricompense (RV-01).
const unlockAllTitle = 'Sblocca tutto';
const unlockAllSubtitle =
    'Temi, pezzi e avatar disponibili senza doverli sbloccare';

/// Ricompense sbloccabili; tutto ciò che non è qui è disponibile da subito.
const Map<Enum, Requirement> _requirements = {
  BoardTheme.sand: LevelRequirement(2),
  BoardTheme.ocean: LevelRequirement(4),
  BoardTheme.coral: LevelRequirement(6),
  BoardTheme.night: AchievementRequirement('streak_7'),
  BoardTheme.gold: AchievementRequirement('tournament_won'),
  PieceStyle.celtic: LevelRequirement(3),
  PieceStyle.shapes: AchievementRequirement('puzzles_10'),
  PieceStyle.firi: LevelRequirement(5),
  PieceStyle.mpchess: AchievementRequirement('first_review'),
  PieceStyle.kiwenSuwi: AchievementRequirement('minigames_all'),
  PieceStyle.totoy: AchievementRequirement('wins_10'),
  PieceStyle.rhosgfx: LevelRequirement(8),
  Avatar.bishop: LevelRequirement(2),
  Avatar.rook: LevelRequirement(4),
  Avatar.queen: LevelRequirement(7),
  Avatar.king: LevelRequirement(11, keptAchievement: 'tournament_won'),
  Avatar.eagle: LevelRequirement(11),
  Avatar.wolf: LevelRequirement(12),
  Avatar.flower: LevelRequirement(3),
  Avatar.owl: LevelRequirement(5),
  Avatar.astroCat: LevelRequirement(8),
  Avatar.rabbit: LevelRequirement(9),
  Avatar.dragon: LevelRequirement(10),
  Avatar.star: LevelRequirement(13),
  AvatarFrame.bronze: LevelRequirement(3),
  AvatarFrame.silver: LevelRequirement(6),
  AvatarFrame.gold: LevelRequirement(10),
  AvatarFrame.flame: LevelRequirement(8, keptAchievement: 'streak_30'),
  AvatarFrame.laurel: LevelRequirement(
    12,
    keptAchievement: 'puzzle_rating_1500',
  ),
};

/// Tutte le ricompense con una condizione di sblocco.
Iterable<Enum> get rewardItems => _requirements.keys;

Requirement? requirementOf(Enum item) => _requirements[item];

/// Disponibile se senza condizione, già meritato, con "Sblocca tutto" attivo o
/// con la gamification spenta (nessun progresso da cui dipendere).
bool isUnlocked(Enum item, ProgressState state, ProgressSettings settings) {
  final r = _requirements[item];
  return r == null || !settings.enabled || settings.unlockAll || r.isMet(state);
}

/// Ricompense meritate passando da [before] ad [after].
List<Enum> newRewards(ProgressState before, ProgressState after) => [
  for (final MapEntry(key: item, value: r) in _requirements.entries)
    if (!r.isMet(before) && r.isMet(after)) item,
];

/// Nome della ricompensa con la sua categoria, per esempio "tema Sabbia".
String rewardName(Enum item) => switch (item) {
  BoardTheme(:final label) => 'tema $label',
  PieceStyle(:final label) => 'pezzi $label',
  Avatar(:final label) => 'avatar $label',
  AvatarFrame(:final label) => 'cornice $label',
  _ => item.name,
};
