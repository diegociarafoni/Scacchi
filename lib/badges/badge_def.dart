import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../masters/master_games.dart';
import '../path/curriculum.dart';
import '../progress/activity.dart';
import '../progress/progress_state.dart';
import '../puzzles/puzzle_run.dart';
import '../puzzles/themes.dart';
import '../story/story.dart';
import 'badge_sources.dart';

enum BadgeFamily { learn, puzzles, games, story, habit }

/// Gradino dei badge in scala (serie, giorni di gioco). Solo estetico.
enum BadgeTier { none, bronze, silver, gold }

/// Dati da cui dipendono i badge: i progressi e gli avanzamenti degli altri
/// salvataggi.
class BadgeFacts {
  const BadgeFacts(this.state, [this.sources = BadgeSources.empty]);

  final ProgressState state;
  final BadgeSources sources;

  int tally(String key) => state.tally[key] ?? 0;
}

/// Un badge: si ottiene quando [value] raggiunge [target]. Quelli che
/// dipendono da un solo evento hanno soglia 1. Vedi docs/badge.md.
class BadgeDef {
  BadgeDef._(
    this.id,
    this.family,
    this.icon,
    this._value, {
    required this.target,
    this.tier = BadgeTier.none,
    int? quoted,
  }) : quoted = quoted ?? target;

  /// Badge a contatore: [value] cresce fino a [target].
  factory BadgeDef.counter(
    String id,
    BadgeFamily family,
    IconData icon, {
    required int target,
    required int Function(BadgeFacts) value,
    BadgeTier tier = BadgeTier.none,
  }) => BadgeDef._(id, family, icon, value, target: target, tier: tier);

  /// Badge che dipende da un solo evento; [quoted] è il numero citato nella
  /// descrizione, se ce n'è uno.
  factory BadgeDef.event(
    String id,
    BadgeFamily family,
    IconData icon, {
    required bool Function(BadgeFacts) when,
    int? quoted,
  }) => BadgeDef._(
    id,
    family,
    icon,
    (f) => when(f) ? 1 : 0,
    target: 1,
    quoted: quoted,
  );

  /// Identificativo stabile, salvato nei progressi: non cambiarlo.
  final String id;
  final BadgeFamily family;
  final IconData icon;
  final int target;
  final BadgeTier tier;

  /// Numero citato nella descrizione («Risolvi 500 puzzle»).
  final int quoted;
  final int Function(BadgeFacts) _value;

  /// Avanzamento, mai oltre la soglia.
  int value(BadgeFacts facts) => min(max(_value(facts), 0), target);

  /// Una soglia vuota (contenuto assente) non regala il badge.
  bool isMet(BadgeFacts facts) => target > 0 && _value(facts) >= target;

  /// Vero se ha senso mostrare «3 / 10».
  bool get hasProgress => target > 1;
}

BadgeDef _event(
  String id,
  BadgeFamily family,
  IconData icon,
  String tallyKey, {
  int? quoted,
}) => BadgeDef.event(
  id,
  family,
  icon,
  when: (f) => f.tally(tallyKey) >= 1,
  quoted: quoted,
);

BadgeDef _tally(
  String id,
  BadgeFamily family,
  IconData icon,
  String key,
  int target, {
  BadgeTier tier = BadgeTier.none,
}) => BadgeDef.counter(
  id,
  family,
  icon,
  target: target,
  value: (f) => f.tally(key),
  tier: tier,
);

BadgeDef _theme(String id, IconData icon, String theme, int target) =>
    BadgeDef.counter(
      id,
      BadgeFamily.puzzles,
      icon,
      target: target,
      value: (f) => f.state.puzzleThemes[theme] ?? 0,
    );

BadgeDef _streak(String id, int days, BadgeTier tier, IconData icon) =>
    BadgeDef.counter(
      id,
      BadgeFamily.habit,
      icon,
      target: days,
      value: (f) => f.state.bestStreak,
      tier: tier,
    );

BadgeDef _chapter(String chapterId, IconData icon) {
  assert(
    storyChapters.any((c) => c.pathChapterId == chapterId),
    'il capitolo $chapterId non fa parte della Storia',
  );
  final chapter = curriculum.firstWhere((c) => c.id == chapterId);
  return BadgeDef.counter(
    'chapter_$chapterId',
    BadgeFamily.learn,
    icon,
    target: chapter.stages.where((s) => !s.isGuardian).length,
    value: (f) => f.sources.lessonsByChapter[chapterId] ?? 0,
  );
}

BadgeDef _story(String chapterId, IconData icon) => BadgeDef.event(
  'story_$chapterId',
  BadgeFamily.story,
  icon,
  when: (f) => f.sources.storyBeaten.contains(chapterId),
);

String _gameKey(GameHighlight h) => 'game:${h.name}';

/// Chiave del contatore dei matti dati con un pezzo.
String mateKey(Role role) => 'mate:${role.name}';

const _matePieces = [
  Role.queen,
  Role.rook,
  Role.bishop,
  Role.knight,
  Role.pawn,
];

/// Tutti i badge, nell'ordine mostrato.
final List<BadgeDef> badges = [
  // Le lezioni si imparano nella Storia: un badge per ogni suo capitolo.
  _chapter('moves', Icons.open_with),
  _chapter('pieces', Icons.swap_horiz),
  _chapter('rules', Icons.gavel),
  _chapter('mates', Icons.my_location),
  _chapter('tactics', Icons.bolt),
  _chapter('endgames', Icons.hourglass_bottom),
  _chapter('openings', Icons.meeting_room),
  BadgeDef.counter(
    'guardians_3',
    BadgeFamily.learn,
    Icons.shield,
    target: 3,
    value: (f) => f.sources.guardiansBeaten,
  ),
  BadgeDef.counter(
    'story_puzzles_all',
    BadgeFamily.learn,
    Icons.lightbulb,
    target: BadgeSources.storyPuzzleTotal,
    value: (f) => f.sources.storyPuzzles,
  ),
  BadgeDef.counter(
    'endgames_all',
    BadgeFamily.learn,
    Icons.emoji_events,
    target: BadgeSources.endgameTotal,
    value: (f) => f.sources.endgamesDone,
  ),
  BadgeDef.counter(
    'masters_all',
    BadgeFamily.learn,
    Icons.visibility,
    target: masterGames.length,
    value: (f) => f.sources.mastersDone,
  ),
  BadgeDef.counter(
    'reviews_25',
    BadgeFamily.learn,
    Icons.fact_check,
    target: 25,
    value: (f) => f.state.reviewsCompleted,
  ),

  BadgeDef.counter(
    'puzzles_500',
    BadgeFamily.puzzles,
    Icons.extension,
    target: 500,
    value: (f) => f.state.puzzlesSolved,
  ),
  BadgeDef.counter(
    'themes_10',
    BadgeFamily.puzzles,
    Icons.explore,
    target: 10,
    // Le etichette di durata e livello di Lichess non sono temi.
    value: (f) => f.state.puzzleThemes.entries
        .where((e) => e.value > 0 && puzzleThemeLabels.containsKey(e.key))
        .length,
  ),
  _theme('pin_10', Icons.push_pin, 'pin', 10),
  _theme('skewer_5', Icons.kebab_dining, 'skewer', 5),
  _theme('discovered_5', Icons.flip, 'discoveredAttack', 5),
  _theme('sacrifice_10', Icons.favorite, 'sacrifice', 10),
  _theme('smothered_1', Icons.water_drop, 'smotheredMate', 1),
  BadgeDef.counter(
    'rating_1800',
    BadgeFamily.puzzles,
    Icons.trending_up,
    target: 1800,
    value: (f) => f.state.records.puzzleRating ?? 0,
  ),
  BadgeDef.counter(
    'streak_run_10',
    BadgeFamily.puzzles,
    Icons.local_fire_department,
    target: 10,
    value: (f) => f.state.records.puzzleRuns[PuzzleRunMode.streak.name] ?? 0,
  ),

  _event(
    'scholars_mate',
    BadgeFamily.games,
    Icons.content_cut,
    _gameKey(GameHighlight.scholarsMate),
  ),
  _event(
    'fools_mate',
    BadgeFamily.games,
    Icons.sentiment_very_satisfied,
    _gameKey(GameHighlight.foolsMate),
  ),
  BadgeDef.counter(
    'all_pieces_mate',
    BadgeFamily.games,
    Icons.category,
    target: _matePieces.length,
    value: (f) => _matePieces.where((r) => f.tally(mateKey(r)) > 0).length,
  ),
  _event(
    'en_passant',
    BadgeFamily.games,
    Icons.swap_horiz,
    _gameKey(GameHighlight.enPassant),
  ),
  _event(
    'underpromotion',
    BadgeFamily.games,
    Icons.pets,
    _gameKey(GameHighlight.underpromotion),
  ),
  _event(
    'stalemate',
    BadgeFamily.games,
    Icons.lock,
    _gameKey(GameHighlight.stalemate),
  ),
  _event(
    'marathon',
    BadgeFamily.games,
    Icons.directions_run,
    _gameKey(GameHighlight.marathon),
    quoted: GameHighlight.marathonMoves,
  ),
  BadgeDef.counter(
    'wins_100',
    BadgeFamily.games,
    Icons.military_tech,
    target: 100,
    value: (f) => f.state.wins,
    tier: BadgeTier.gold,
  ),
  _event('podium', BadgeFamily.games, Icons.workspace_premium, 'podium'),
  _tally(
    'tournaments_5',
    BadgeFamily.games,
    Icons.event_repeat,
    'tournaments',
    5,
  ),

  _story('prologue', Icons.directions_walk),
  _story('village', Icons.cottage),
  _story('gates', Icons.fence),
  _story('tower', Icons.castle),
  _story('forest', Icons.forest),
  _story('castle', Icons.fort),
  _story('crown', Icons.auto_awesome),
  BadgeDef.counter(
    'story_all',
    BadgeFamily.story,
    Icons.menu_book,
    target: storyChapters.length,
    value: (f) =>
        storyChapters.where((c) => f.sources.storyBeaten.contains(c.id)).length,
  ),

  _streak('streak_14', 14, BadgeTier.bronze, Icons.calendar_view_week),
  _streak('streak_60', 60, BadgeTier.silver, Icons.calendar_month),
  _streak('streak_100', 100, BadgeTier.gold, Icons.filter_9_plus),
  _streak('streak_365', 365, BadgeTier.gold, Icons.cake),
  _tally(
    'days_30',
    BadgeFamily.habit,
    Icons.event_available,
    'days',
    30,
    tier: BadgeTier.bronze,
  ),
  _tally(
    'days_100',
    BadgeFamily.habit,
    Icons.home,
    'days',
    100,
    tier: BadgeTier.silver,
  ),
  _event(
    'comeback',
    BadgeFamily.habit,
    Icons.waving_hand,
    'comeback',
    quoted: comebackDays,
  ),
  BadgeDef.counter(
    'perfect_7',
    BadgeFamily.habit,
    Icons.stars,
    target: 7,
    value: (f) => f.state.perfectDays,
  ),
  _tally('minigames_25', BadgeFamily.habit, Icons.timer, 'minigames', 25),
];

/// Giorni senza attività dopo i quali tornare vale «Bentornato!».
const comebackDays = 14;

/// Giocatori minimi di un torneo perché il podio conti.
const podiumMinPlayers = 4;

BadgeDef? badgeById(String id) {
  for (final b in badges) {
    if (b.id == id) return b;
  }
  return null;
}
