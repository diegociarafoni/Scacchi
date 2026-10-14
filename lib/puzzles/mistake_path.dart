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
    required this.available,
  });

  /// Identificativo del tema (vedi [puzzleThemeIds]).
  final String theme;
  final List<Puzzle> puzzles;

  /// Puzzle già affrontati almeno una volta, compresi quelli imparati.
  final int practiced;

  /// Puzzle usciti dal ripasso perché imparati.
  final int learned;

  /// Puzzle da fare adesso: i nuovi e quelli la cui scadenza è arrivata. Gli
  /// altri aspettano il loro giorno: rifarli subito farebbe salire di livello
  /// il ripasso senza che sia passato tempo.
  final int available;

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
  final themes =
      [
        for (final id in puzzleThemeIds)
          if ((byTheme[id]?.length ?? 0) >= mistakeChapterMinPuzzles) id,
      ]..sort((a, b) {
        final bySize = byTheme[b]!.length.compareTo(byTheme[a]!.length);
        // `sort` non è stabile: il pari merito si decide sull'ordine dei temi.
        return bySize != 0
            ? bySize
            : puzzleThemeIds.indexOf(a).compareTo(puzzleThemeIds.indexOf(b));
      });
  return [
    for (final theme in themes.take(mistakeChaptersMax))
      _chapter(trainer, theme, byTheme[theme]!),
  ];
}

MistakeChapter _chapter(PuzzleTrainer trainer, String theme, List<Puzzle> ps) {
  final reviews = trainer.reviews;
  final due = reviews.due(trainer.now()).toSet();
  var available = 0;
  var learned = 0;
  var practiced = 0;
  for (final p in ps) {
    if (due.contains(p.id)) available++;
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
    available: available,
  );
}

/// Puzzle di un capitolo da fare adesso: prima i nuovi, poi quelli in scadenza
/// dal più in ritardo, ognuno una volta sola per sessione. L'esito va nel ripasso
/// come negli altri puzzle dei propri errori e non sposta il punteggio.
class MistakeChapterFeed implements PuzzleFeed {
  MistakeChapterFeed(this.trainer, this.theme);

  final PuzzleTrainer trainer;
  final String theme;
  final Set<String> _served = {};

  Puzzle? _peek() {
    final reviews = trainer.reviews;
    // `due` è già in ordine di scadenza; i nuovi passano avanti.
    final due = [
      for (final id in reviews.due(trainer.now()))
        if (!_served.contains(id) && _inChapter(id)) id,
    ];
    if (due.isEmpty) return null;
    final first = due.firstWhere(reviews.isNew, orElse: () => due.first);
    return trainer.personal.byId(first);
  }

  bool _inChapter(String id) =>
      trainer.personal.byId(id)?.themes.contains(theme) ?? false;

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
