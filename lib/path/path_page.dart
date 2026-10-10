import 'package:flutter/material.dart';

import 'curriculum.dart';
import 'path_controller.dart';
import 'path_progress.dart';
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
          const SnackBar(
            content: Text(
              'Il guardiano arriva con la partita contro il computer.',
            ),
          ),
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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final progress = controller.progress;
        final next = progress.nextStage;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Percorso'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '★ ${progress.totalStars}/$maxStars',
                    semanticsLabel:
                        '${progress.totalStars} stelle su $maxStars',
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: next == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _open(context, next),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continua'),
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final chapter in curriculum) ...[
                _ChapterHeader(chapter: chapter, progress: progress),
                for (final (i, stage) in chapter.stages.indexed)
                  _StageNode(
                    stage: stage,
                    index: i,
                    stars: progress.starsFor(stage.id),
                    unlocked: progress.isUnlocked(stage.id),
                    current: stage.id == next?.id,
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

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({required this.chapter, required this.progress});

  final Chapter chapter;
  final PathProgress progress;

  @override
  Widget build(BuildContext context) {
    final max = chapter.stages.length * 3;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              chapter.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Text(
            '★ ${progress.chapterStars(chapter)}/$max',
            semanticsLabel: '${progress.chapterStars(chapter)} stelle su $max',
          ),
        ],
      ),
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.stage,
    required this.index,
    required this.stars,
    required this.unlocked,
    required this.current,
    required this.onTap,
  });

  final Stage stage;
  final int index;
  final int stars;
  final bool unlocked;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = stars > 0;
    final state = done
        ? '$stars stelle su 3'
        : unlocked
        ? 'da fare'
        : 'bloccata';
    final background = !unlocked
        ? scheme.surfaceContainerHighest
        : done
        ? scheme.primary
        : scheme.primaryContainer;
    final foreground = !unlocked
        ? scheme.outline
        : done
        ? scheme.onPrimary
        : scheme.onPrimaryContainer;
    // Le tappe si alternano a sinistra e a destra come su una mappa.
    const offsets = [0.0, 0.5, 0.0, -0.5];
    return Align(
      alignment: Alignment(offsets[index % offsets.length], 0),
      child: Semantics(
        button: unlocked,
        label: '${stage.title}, $state',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: unlocked ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: background,
                    border: current
                        ? Border.all(color: scheme.tertiary, width: 4)
                        : null,
                  ),
                  child: SizedBox.square(
                    dimension: 72,
                    child: Icon(
                      !unlocked
                          ? Icons.lock_outline
                          : stage.isGuardian
                          ? Icons.smart_toy_outlined
                          : Icons.school_outlined,
                      color: foreground,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(stage.title),
                Text(
                  '${'★' * stars}${'☆' * (3 - stars)}',
                  style: TextStyle(color: scheme.tertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
