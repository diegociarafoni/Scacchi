import 'curriculum.dart';

/// Stelle massime ottenibili nel percorso.
final int maxStars = curriculum.fold(0, (n, c) => n + 3 * c.stages.length);

final List<Stage> _stages = [for (final c in curriculum) ...c.stages];

/// Migliori stelle (1-3) per tappa completata.
class PathProgress {
  const PathProgress([this.stars = const {}, this.resume = const {}]);

  final Map<String, int> stars;

  /// Stelle degli esercizi già risolti in una tappa lasciata a metà, per
  /// riprenderla da dove era.
  final Map<String, List<int>> resume;

  List<int> resumeFor(String stageId) => resume[stageId] ?? const [];

  PathProgress withResume(String stageId, List<int> solved) {
    final next = {...resume}..remove(stageId);
    if (solved.isNotEmpty) next[stageId] = List.unmodifiable(solved);
    return PathProgress(stars, next);
  }

  int starsFor(String stageId) => stars[stageId] ?? 0;

  bool isCompleted(String stageId) => starsFor(stageId) > 0;

  int get totalStars => curriculum.fold(0, (n, c) => n + chapterStars(c));

  int chapterStars(Chapter chapter) =>
      chapter.stages.fold(0, (n, s) => n + starsFor(s.id));

  /// Una tappa è aperta se la lezione precedente è completata o se lo è già
  /// una lezione successiva: così le lezioni aggiunte con un aggiornamento non
  /// richiudono il percorso. I guardiani sono sfide facoltative e non bloccano.
  bool isUnlocked(String stageId) {
    final i = _stages.indexWhere((s) => s.id == stageId);
    if (i < 0) return false;
    final previous = _stages.take(i).where((s) => !s.isGuardian).lastOrNull;
    return previous == null ||
        isCompleted(previous.id) ||
        _stages.skip(i).any((s) => !s.isGuardian && isCompleted(s.id));
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
    return PathProgress({
      ...stars,
      stageId: best.clamp(1, 3),
    }, {...resume}..remove(stageId));
  }

  Map<String, Object?> toJson() => {'stars': stars, 'resume': resume};

  static PathProgress fromJson(Map<String, Object?> json) => PathProgress(
    {
      for (final e in (json['stars'] as Map? ?? const {}).entries)
        if ((e.key, e.value) case (final String k, final int v)
            when v >= 1 && v <= 3)
          k: v,
    },
    {
      for (final e in (json['resume'] as Map? ?? const {}).entries)
        if (e.key is String && e.value is List)
          e.key as String: [
            for (final v in e.value as List)
              if (v is int && v >= 1 && v <= 3) v,
          ],
    }..removeWhere((_, v) => v.isEmpty),
  );
}
