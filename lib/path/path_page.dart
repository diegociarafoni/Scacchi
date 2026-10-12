import 'package:flutter/material.dart';

import '../theme/rokko_theme.dart';
import 'curriculum.dart';
import 'path_controller.dart';
import 'path_progress.dart';
import 'path_widgets.dart';
import 'stage_page.dart';

/// Gioca la partita contro il bot guardiano e restituisce le stelle ottenute,
/// o `null` se la partita non è stata vinta.
typedef PlayGuardian = Future<int?> Function(BuildContext context, Stage stage);

/// Mappa del percorso a tappe (RG-03).
class PathPage extends StatefulWidget {
  const PathPage({super.key, required this.controller, this.playGuardian});

  final PathController controller;
  final PlayGuardian? playGuardian;

  @override
  State<PathPage> createState() => _PathPageState();
}

class _PathPageState extends State<PathPage> {
  PathController get controller => widget.controller;

  /// Evita di aprire due tappe con un doppio tocco.
  bool _opening = false;

  Future<void> _open(BuildContext context, Stage stage) async {
    if (_opening) return;
    _opening = true;
    try {
      await _play(context, stage);
    } finally {
      _opening = false;
    }
  }

  Future<void> _play(BuildContext context, Stage stage) async {
    final started = DateTime.now();
    int? stars;
    if (stage.isGuardian) {
      final play = widget.playGuardian;
      if (play == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pathL10n(context).pathGuardianUnavailable)),
        );
        return;
      }
      stars = await play(context, stage);
    } else {
      stars = await Navigator.push<int>(
        context,
        MaterialPageRoute(builder: (_) => StagePage(stage: stage)),
      );
    }
    if (stars != null && stars > 0) {
      await controller.complete(
        stage,
        stars,
        DateTime.now().difference(started),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = pathL10n(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final progress = controller.progress;
        final next = progress.nextStage;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.pathTitle)),
          floatingActionButton: next == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _open(context, next),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.pathContinue),
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _Summary(progress: progress, next: next),
              for (final (n, chapter) in curriculum.indexed) ...[
                _ChapterHeader(
                  number: n + 1,
                  chapter: chapter,
                  progress: progress,
                ),
                for (final (i, stage) in chapter.stages.indexed)
                  StageNode(
                    stage: stage,
                    stars: progress.starsFor(stage.id),
                    unlocked: progress.isUnlocked(stage.id),
                    current: stage.id == next?.id,
                    alignment: _alignment(i),
                    previousAlignment: i == 0 ? null : _alignment(i - 1),
                    nextAlignment: i == chapter.stages.length - 1
                        ? null
                        : _alignment(i + 1),
                    nextUnlocked:
                        i < chapter.stages.length - 1 &&
                        progress.isUnlocked(chapter.stages[i + 1].id),
                    onTap: () => _open(context, stage),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Le tappe serpeggiano sul sentiero: al centro, a destra, al centro, a
/// sinistra.
double _alignment(int index) => const [0.0, 0.6, 0.0, -0.6][index % 4];

/// Stelle totali e prossima tappa, in cima al sentiero.
class _Summary extends StatelessWidget {
  const _Summary({required this.progress, required this.next});

  final PathProgress progress;
  final Stage? next;

  @override
  Widget build(BuildContext context) {
    final l10n = pathL10n(context);
    final theme = Theme.of(context);
    final stars = progress.totalStars;
    return Card(
      key: const ValueKey('path-summary'),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.pathSummaryTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Semantics(
                  container: true,
                  label: l10n.pathStars(stars, maxStars),
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: RokkoTokens.of(context).star),
                      const SizedBox(width: 4),
                      Text('$stars/$maxStars'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  RokkoTokens.of(context).radiusSmall,
                ),
                child: LinearProgressIndicator(
                  value: maxStars == 0 ? 0 : stars / maxStars,
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              next == null ? l10n.pathAllDone : l10n.pathNext(next!.title),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({
    required this.number,
    required this.chapter,
    required this.progress,
  });

  final int number;
  final Chapter chapter;
  final PathProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = pathL10n(context);
    final theme = Theme.of(context);
    final max = chapter.stages.length * 3;
    final stars = progress.chapterStars(chapter);
    final done = chapter.stages.every((s) => progress.isCompleted(s.id));
    return Semantics(
      container: true,
      header: true,
      label:
          '${l10n.pathChapterNumber(number)}: ${chapter.title}, '
          '${l10n.pathStars(stars, max)}'
          '${done ? ', ${l10n.pathChapterDone}' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.pathChapterNumber(number),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(chapter.title, style: theme.textTheme.titleLarge),
                    ],
                  ),
                ),
                if (done)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Icon(Icons.star, size: 18, color: RokkoTokens.of(context).star),
                const SizedBox(width: 2),
                Text('$stars/$max'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                RokkoTokens.of(context).radiusSmall,
              ),
              child: LinearProgressIndicator(
                key: ValueKey('chapter-progress-${chapter.id}'),
                value: max == 0 ? 0 : stars / max,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
