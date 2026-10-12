import '../engine/bots.dart';
import '../path/curriculum.dart';
import '../path/path_progress.dart';

/// Passi di un capitolo, nell'ordine in cui si aprono.
enum StoryStepKind { lessons, puzzles, guardian, boss }

/// Capitolo della storia: un capitolo del percorso, i puzzle di un tema e un
/// bot da battere. I testi sono in `story_l10n.dart`. Vedi docs/storia.md.
class StoryChapter {
  const StoryChapter({
    required this.id,
    required this.pathChapterId,
    required this.botId,
    required this.puzzleTheme,
    required this.puzzleCount,
    this.puzzleRating,
  });

  final String id;

  /// Capitolo di [curriculum] le cui lezioni (e il guardiano) fanno parte.
  final String pathChapterId;
  final String botId;

  /// Tema Lichess dei puzzle del capitolo e quanti risolverne.
  final String puzzleTheme;
  final int puzzleCount;

  /// Difficoltà massima dei puzzle, se il capitolo parte più in basso di
  /// quanto sia l'utente.
  final int? puzzleRating;

  Bot get bot => botById(botId)!;

  Chapter get pathChapter =>
      curriculum.firstWhere((c) => c.id == pathChapterId);
}

const storyChapters = <StoryChapter>[
  StoryChapter(
    id: 'prologue',
    pathChapterId: 'moves',
    botId: 'tino',
    puzzleTheme: 'mateIn1',
    puzzleCount: 3,
    puzzleRating: 500,
  ),
  StoryChapter(
    id: 'village',
    pathChapterId: 'pieces',
    botId: 'pino',
    puzzleTheme: 'hangingPiece',
    puzzleCount: 3,
  ),
  StoryChapter(
    id: 'gates',
    pathChapterId: 'rules',
    botId: 'chiara',
    puzzleTheme: 'promotion',
    puzzleCount: 3,
  ),
  StoryChapter(
    id: 'tower',
    pathChapterId: 'mates',
    botId: 'rocco',
    puzzleTheme: 'backRankMate',
    puzzleCount: 3,
  ),
  StoryChapter(
    id: 'forest',
    pathChapterId: 'tactics',
    botId: 'marta',
    puzzleTheme: 'fork',
    puzzleCount: 4,
  ),
  StoryChapter(
    id: 'castle',
    pathChapterId: 'endgames',
    botId: 'duilio',
    puzzleTheme: 'pawnEndgame',
    puzzleCount: 3,
  ),
  StoryChapter(
    id: 'crown',
    pathChapterId: 'openings',
    botId: 'elena',
    puzzleTheme: 'opening',
    puzzleCount: 3,
  ),
  StoryChapter(
    id: 'plain',
    pathChapterId: 'strategy',
    botId: 'massimo',
    puzzleTheme: 'advancedPawn',
    puzzleCount: 3,
  ),
  StoryChapter(
    id: 'academy',
    pathChapterId: 'capablanca',
    botId: 'stella',
    puzzleTheme: 'rookEndgame',
    puzzleCount: 3,
  ),
];

/// Parte della storia che il percorso non conosce, salvata in `story.json`.
class StoryState {
  const StoryState({this.puzzles = const {}, this.beaten = const {}});

  /// Puzzle risolti per capitolo e capitoli con il bot battuto.
  final Map<String, int> puzzles;
  final Set<String> beaten;

  int puzzlesSolved(String chapterId) => puzzles[chapterId] ?? 0;

  bool isBossBeaten(String chapterId) => beaten.contains(chapterId);

  StoryState withPuzzleSolved(String chapterId, int goal) => StoryState(
    puzzles: {
      ...puzzles,
      chapterId: (puzzlesSolved(chapterId) + 1).clamp(0, goal),
    },
    beaten: beaten,
  );

  StoryState withBossBeaten(String chapterId) =>
      StoryState(puzzles: puzzles, beaten: {...beaten, chapterId});

  Map<String, Object?> toJson() => {
    'puzzles': puzzles,
    'beaten': [...beaten],
  };

  /// Ignora capitoli sconosciuti e valori illeggibili: si riparte da zero
  /// per quel capitolo invece di perdere tutta la storia.
  static StoryState fromJson(Map<String, Object?> json) {
    final ids = {for (final c in storyChapters) c.id: c};
    final puzzles = <String, int>{};
    final raw = json['puzzles'];
    if (raw is Map) {
      for (final e in raw.entries) {
        final chapter = ids[e.key];
        final n = e.value;
        if (chapter != null && n is int) {
          puzzles['${e.key}'] = n.clamp(0, chapter.puzzleCount);
        }
      }
    }
    final beaten = <String>{};
    final list = json['beaten'];
    if (list is List) {
      beaten.addAll(list.whereType<String>().where(ids.containsKey));
    }
    return StoryState(puzzles: puzzles, beaten: beaten);
  }
}

/// Un passo di un capitolo con il suo avanzamento.
class StoryStep {
  const StoryStep(this.kind, {required this.value, required this.total});

  final StoryStepKind kind;
  final int value;
  final int total;

  bool get done => value >= total;
}

/// Avanzamento della storia, derivato dal percorso e da [StoryState]: le
/// lezioni e i guardiani contano come nel percorso, lezioni aggiunte con un
/// aggiornamento comprese.
class StoryProgress {
  const StoryProgress(this.path, this.state);

  final PathProgress path;
  final StoryState state;

  List<StoryStep> steps(StoryChapter chapter) {
    final stages = chapter.pathChapter.stages;
    final lessons = stages.where((s) => !s.isGuardian).toList();
    final guardian = stages.where((s) => s.isGuardian).firstOrNull;
    return [
      StoryStep(
        StoryStepKind.lessons,
        value: lessons.where((s) => path.isCompleted(s.id)).length,
        total: lessons.length,
      ),
      StoryStep(
        StoryStepKind.puzzles,
        value: state.puzzlesSolved(chapter.id),
        total: chapter.puzzleCount,
      ),
      if (guardian != null)
        StoryStep(
          StoryStepKind.guardian,
          value: path.isCompleted(guardian.id) ? 1 : 0,
          total: 1,
        ),
      StoryStep(
        StoryStepKind.boss,
        value: state.isBossBeaten(chapter.id) ? 1 : 0,
        total: 1,
      ),
    ];
  }

  /// Concluso se ogni passo è fatto, se il suo bot è battuto o se la storia
  /// è già andata oltre: chi ha battuto un bot o risolto puzzle più avanti
  /// non rifà le lezioni aggiunte o spostate prima.
  bool isChapterDone(StoryChapter chapter) {
    if (state.isBossBeaten(chapter.id)) return true;
    if (steps(chapter).every((s) => s.done)) return true;
    final later = storyChapters.skip(storyChapters.indexOf(chapter) + 1);
    return later.any(
      (c) => state.isBossBeaten(c.id) || state.puzzlesSolved(c.id) > 0,
    );
  }

  int get completedChapters => storyChapters.where(isChapterDone).length;

  /// Un capitolo si apre quando il precedente è concluso.
  bool isChapterUnlocked(int index) =>
      index == 0 || isChapterDone(storyChapters[index - 1]);

  /// Un passo si apre quando quelli prima sono fatti.
  bool isStepUnlocked(StoryChapter chapter, StoryStepKind kind) {
    for (final s in steps(chapter)) {
      if (s.kind == kind) return true;
      if (!s.done) return false;
    }
    return false;
  }

  /// Primo capitolo aperto e non concluso; `null` a storia finita.
  int? get currentChapterIndex {
    for (var i = 0; i < storyChapters.length; i++) {
      if (isChapterUnlocked(i) && !isChapterDone(storyChapters[i])) return i;
    }
    return null;
  }
}

/// Prima lezione, o guardiano, ancora da fare nei capitoli della storia;
/// `null` se tutto è fatto. Serve a «Continua da dove eri» della scheda Tu.
/// I capitoli del percorso che la storia non racconta non contano.
Stage? nextStoryStage(PathProgress path) {
  for (final chapter in storyChapters) {
    final stages = chapter.pathChapter.stages;
    // Nel capitolo prima le lezioni, poi il guardiano.
    for (final s in [
      ...stages.where((s) => !s.isGuardian),
      ...stages.where((s) => s.isGuardian),
    ]) {
      if (!path.isCompleted(s.id)) return s;
    }
  }
  return null;
}
