import 'puzzle.dart';

/// Raccolta di puzzle inclusa nell'app, ordinata per punteggio.
class PuzzleLibrary {
  PuzzleLibrary(List<Puzzle> puzzles)
    : puzzles = List.unmodifiable(
        [...puzzles]..sort((a, b) => a.rating.compareTo(b.rating)),
      );

  final List<Puzzle> puzzles;

  late final Map<String, Puzzle> _byId = {for (final p in puzzles) p.id: p};

  late final List<String> themes = (<String>{
    for (final p in puzzles) ...p.themes,
  }.toList()..sort());

  Puzzle? byId(String id) => _byId[id];

  late final Map<String, int> _themeCounts = () {
    final counts = <String, int>{};
    for (final p in puzzles) {
      for (final t in p.themes) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts;
  }();

  int countFor(String theme) => _themeCounts[theme] ?? 0;

  /// Il puzzle non ancora visto con punteggio più vicino a [rating].
  ///
  /// Se nel tema scelto sono stati visti tutti, ripropone quello visto meno
  /// di recente; [seen] è in ordine dal meno al più recente.
  Puzzle next({
    required double rating,
    String? theme,
    Set<String> seen = const {},
  }) {
    final pool = theme == null
        ? puzzles
        : puzzles.where((p) => p.themes.contains(theme)).toList();
    if (pool.isEmpty) throw StateError('Nessun puzzle per il tema $theme');
    final fresh = pool.where((p) => !seen.contains(p.id));
    if (fresh.isEmpty) {
      final order = {for (final (i, id) in seen.indexed) id: i};
      return pool.reduce((a, b) => order[b.id]! < order[a.id]! ? b : a);
    }
    return fresh.reduce(
      (best, p) =>
          (p.rating - rating).abs() < (best.rating - rating).abs() ? p : best,
    );
  }

  /// Puzzle giornaliero deterministico, uguale per tutti nello stesso giorno.
  Puzzle daily(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final n = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    // Moltiplicatore coprimo con la dimensione: scorre tutta la raccolta.
    final index = (n * 7919) % puzzles.length;
    return puzzles[index];
  }
}
