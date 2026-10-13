import 'puzzle.dart';

/// Che cosa si deve ottenere in un puzzle, ricavato dai temi del database aperto dei puzzle.
enum PuzzleGoal {
  mateIn1,
  mateIn2,
  mateIn3,
  mateIn4,
  mate,
  crushing,
  advantage,
  equality;

  /// Valore del selettore ICU nei testi localizzati.
  String get key => name;

  /// Vero per gli obiettivi di matto: negli altri la mossa matta non è lo scopo.
  bool get isMate =>
      const {mateIn1, mateIn2, mateIn3, mateIn4, mate}.contains(this);

  /// Obiettivo del puzzle, o nullo se i temi non lo dicono.
  static PuzzleGoal? of(Puzzle puzzle) {
    final t = puzzle.themes;
    // Il matto vince sul vantaggio: nei puzzle di matto il tema di
    // valutazione, se c'è, è solo una conseguenza.
    for (final goal in const [mateIn1, mateIn2, mateIn3, mateIn4]) {
      if (t.contains(goal.name)) return goal;
    }
    if (t.contains('mate') || t.contains('mateIn5')) return mate;
    if (t.contains('equality')) return equality;
    if (t.contains('crushing')) return crushing;
    if (t.contains('advantage')) return advantage;
    return null;
  }
}
