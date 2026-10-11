import 'curriculum.dart';

/// Stelle massime ottenibili nel percorso.
final int maxStars = curriculum.fold(0, (n, c) => n + 3 * c.stages.length);

/// Migliori stelle (1-3) per tappa completata.
class PathProgress {
  const PathProgress([this.stars = const {}]);

  final Map<String, int> stars;

  int starsFor(String stageId) => stars[stageId] ?? 0;

  bool isCompleted(String stageId) => starsFor(stageId) > 0;

  int get totalStars => curriculum.fold(0, (n, c) => n + chapterStars(c));

  int chapterStars(Chapter chapter) =>
      chapter.stages.fold(0, (n, s) => n + starsFor(s.id));

  /// Una tappa è aperta se tutte le lezioni precedenti sono completate; i
  /// guardiani sono sfide facoltative e non bloccano il percorso.
  bool isUnlocked(String stageId) {
    for (final c in curriculum) {
      for (final s in c.stages) {
        if (s.id == stageId) return true;
        if (!s.isGuardian && !isCompleted(s.id)) return false;
      }
    }
    return false;
  }

  /// Prima lezione non completata da proporre con "Continua"; finite le
  /// lezioni, il primo guardiano non battuto.
  Stage? get nextStage {
    Stage? guardian;
    for (final c in curriculum) {
      for (final s in c.stages) {
        if (isCompleted(s.id)) continue;
        if (!s.isGuardian) return s;
        guardian ??= s;
      }
    }
    return guardian;
  }

  PathProgress complete(String stageId, int earned) {
    final best = earned > starsFor(stageId) ? earned : starsFor(stageId);
    return PathProgress({...stars, stageId: best.clamp(1, 3)});
  }

  Map<String, Object?> toJson() => {'stars': stars};

  static PathProgress fromJson(Map<String, Object?> json) => PathProgress({
    ...(json['stars'] as Map? ?? const {}).cast<String, int>(),
  });
}
