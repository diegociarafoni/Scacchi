import 'package:flutter/foundation.dart';

import '../endgames/drills.dart';
import '../endgames/endgame_progress.dart';
import '../masters/master_games.dart';
import '../masters/masters_progress.dart';
import '../path/curriculum.dart';
import '../path/path_progress.dart';
import '../story/story.dart';

/// Avanzamenti che stanno nei salvataggi di Percorso, finali, partite dei
/// maestri e Storia. I badge li leggono da qui, così chi ha già finito un
/// capitolo prima dei badge lo ottiene al primo avvio.
@immutable
class BadgeSources {
  const BadgeSources({
    this.lessonsByChapter = const {},
    this.guardiansBeaten = 0,
    this.endgamesDone = 0,
    this.mastersDone = 0,
    this.storyBeaten = const {},
    this.storyPuzzles = 0,
  });

  static const empty = BadgeSources();

  /// Posizioni dell'allenatore dei finali da completare per «Re dei finali».
  static int get endgameTotal => endgameDrills.length;

  /// Puzzle da risolvere in tutti i capitoli della Storia.
  static int get storyPuzzleTotal =>
      storyChapters.fold(0, (n, c) => n + c.puzzleCount);

  factory BadgeSources.fromStores({
    PathProgress? path,
    EndgameProgress? endgames,
    MastersProgress? masters,
    StoryState? story,
  }) {
    return BadgeSources(
      lessonsByChapter: path == null
          ? const {}
          : {
              for (final c in curriculum)
                c.id: c.stages
                    .where((s) => !s.isGuardian && path.isCompleted(s.id))
                    .length,
            },
      // La Storia è il percorso di apprendimento: contano i suoi guardiani.
      guardiansBeaten: path == null
          ? 0
          : storyChapters
                .expand((c) => c.pathChapter.stages)
                .where((s) => s.isGuardian && path.isCompleted(s.id))
                .length,
      endgamesDone: endgames == null
          ? 0
          : endgameDrills.where((d) => endgames.starsFor(d.id) > 0).length,
      mastersDone: masters == null
          ? 0
          : masterGames.where((g) => masters.bestPercent(g.id) != null).length,
      storyBeaten: story?.beaten ?? const {},
      storyPuzzles: story == null
          ? 0
          : storyChapters.fold(0, (n, c) => n + story.puzzlesSolved(c.id)),
    );
  }

  /// Lezioni completate per capitolo del curriculum, guardiani esclusi.
  final Map<String, int> lessonsByChapter;
  final int guardiansBeaten;
  final int endgamesDone;
  final int mastersDone;
  final Set<String> storyBeaten;

  /// Puzzle risolti nei capitoli della Storia.
  final int storyPuzzles;

  @override
  bool operator ==(Object other) =>
      other is BadgeSources &&
      mapEquals(other.lessonsByChapter, lessonsByChapter) &&
      other.guardiansBeaten == guardiansBeaten &&
      other.endgamesDone == endgamesDone &&
      other.mastersDone == mastersDone &&
      setEquals(other.storyBeaten, storyBeaten) &&
      other.storyPuzzles == storyPuzzles;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      lessonsByChapter.entries.map((e) => (e.key, e.value)),
    ),
    guardiansBeaten,
    endgamesDone,
    mastersDone,
    Object.hashAllUnordered(storyBeaten),
    storyPuzzles,
  );
}
