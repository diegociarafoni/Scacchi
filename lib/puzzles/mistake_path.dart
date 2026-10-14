import 'puzzle.dart';
import 'puzzle_feed.dart';
import 'puzzle_trainer.dart';
import 'themes.dart';

/// Quanti puzzle servono perché un tema diventi un capitolo: un errore solo
/// non dice ancora cosa allenare.
const mistakeChapterMinPuzzles = 2;

/// Capitoli mostrati al massimo, i temi più sbagliati.
const mistakeChaptersMax = 5;

/// Le fasi della partita accompagnano ogni puzzle personale ma non sono temi
/// tattici.
const _phases = {'opening', 'middlegame', 'endgame'};

/// Capitolo personale del percorso «dai miei errori»: i puzzle nati dai propri
/// errori su un tema tattico.
class MistakeChapter {
  const MistakeChapter({
    required this.theme,
    required this.puzzles,
    required this.practiced,
    required this.learned,
  });

  /// Identificativo del tema (vedi [puzzleThemeIds]).
  final String theme;
  final List<Puzzle> puzzles;

  /// Puzzle già affrontati almeno una volta, compresi quelli imparati.
  final int practiced;

  /// Puzzle usciti dal ripasso perché imparati.
  final int learned;

  int get total => puzzles.length;
  bool get done => learned == total;
}

/// Capitoli ricavati dai puzzle personali salvati: un capitolo per tema
/// tattico con almeno [mistakeChapterMinPuzzles] puzzle, dal più sbagliato; a
/// parità vale l'ordine di [puzzleThemeIds], così l'elenco non cambia da solo.
/// Non c'è nulla da salvare: l'avanzamento si legge dalla coda di ripasso.
List<MistakeChapter> mistakeChapters(PuzzleTrainer trainer) {
  final byTheme = <String, List<Puzzle>>{};
  for (final puzzle in trainer.personal.all) {
    for (final theme in puzzle.themes) {
      if (_phases.contains(theme) || !puzzleThemeIds.contains(theme)) continue;
      byTheme.putIfAbsent(theme, () => []).add(puzzle);
    }
  }
  final themes = [
    for (final id in puzzleThemeIds)
      if ((byTheme[id]?.length ?? 0) >= mistakeChapterMinPuzzles) id,
  ]..sort((a, b) => byTheme[b]!.length.compareTo(byTheme[a]!.length));
  return [
    for (final theme in themes.take(mistakeChaptersMax))
      _chapter(trainer, theme, byTheme[theme]!),
  ];
}

MistakeChapter _chapter(PuzzleTrainer trainer, String theme, List<Puzzle> ps) {
  final reviews = trainer.reviews;
  var learned = 0;
  var practiced = 0;
  for (final p in ps) {
    if (!reviews.contains(p.id)) {
      learned++;
      practiced++;
    } else if (!reviews.isNew(p.id)) {
      practiced++;
    }
  }
  return MistakeChapter(
    theme: theme,
    puzzles: ps,
    practiced: practiced,
    learned: learned,
  );
}

/// Puzzle di un capitolo ancora da imparare: prima i nuovi, poi gli altri dal
/// più in ritardo, ognuno una volta sola per sessione. L'esito va nel ripasso
/// come negli altri puzzle dei propri errori e non sposta il punteggio.
class MistakeChapterFeed implements PuzzleFeed {
  MistakeChapterFeed(this.trainer, this.theme);

  final PuzzleTrainer trainer;
  final String theme;
  final Set<String> _served = {};

  Puzzle? _peek() {
    final reviews = trainer.reviews;
    final open = [
      for (final p in trainer.personal.all)
        if (p.themes.contains(theme) &&
            reviews.contains(p.id) &&
            !_served.contains(p.id))
          p,
    ];
    if (open.isEmpty) return null;
    final order = reviews.ids.toList();
    open.sort((a, b) {
      final fresh =
          (reviews.isNew(b.id) ? 1 : 0) - (reviews.isNew(a.id) ? 1 : 0);
      return fresh != 0
          ? fresh
          : order.indexOf(a.id).compareTo(order.indexOf(b.id));
    });
    return open.first;
  }

  @override
  Puzzle? next() {
    final p = _peek();
    if (p != null) _served.add(p.id);
    return p;
  }

  @override
  bool get hasNext => _peek() != null;

  @override
  Future<FeedOutcome> finished(Puzzle puzzle, {required bool solved}) async {
    await trainer.reviews.reviewed(
      puzzle.id,
      solved: solved,
      now: trainer.now(),
    );
    return (ratingDelta: null, awardXp: true);
  }
}
