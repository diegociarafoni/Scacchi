import 'package:flutter/material.dart';

import '../engine/bots.dart';
import '../path/path_controller.dart';
import '../path/path_page.dart';
import '../path/stage_page.dart';
import 'story.dart';
import 'story_controller.dart';
import 'story_l10n.dart';

/// Gioca la sfida contro [bot] e dice se è stata vinta.
typedef PlayStoryBoss = Future<bool> Function(BuildContext context, Bot bot);

/// Apre i puzzle del capitolo e restituisce quanti ne ha risolti al primo
/// tentativo (al massimo [remaining]); `null` se i puzzle non si caricano.
typedef PlayStoryPuzzles = Future<int?> Function(
  BuildContext context,
  StoryChapter chapter,
  int remaining,
);

/// Percorso a storia (RG-13): capitoli con racconto, lezioni, puzzle,
/// guardiano e un bot da battere. Vedi docs/storia.md.
class StoryPage extends StatefulWidget {
  const StoryPage({
    super.key,
    required this.path,
    required this.story,
    this.playGuardian,
    this.playBoss,
    this.playPuzzles,
  });

  final PathController path;
  final StoryController story;
  final PlayGuardian? playGuardian;
  final PlayStoryBoss? playBoss;
  final PlayStoryPuzzles? playPuzzles;

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  /// Evita di aprire due passi con un doppio tocco.
  bool _busy = false;

  StoryProgress get _progress =>
      StoryProgress(widget.path.progress, widget.story.state);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _open(StoryChapter chapter, StoryStepKind kind) =>
      _run(() async {
        switch (kind) {
          case StoryStepKind.lessons:
            await _lesson(chapter);
          case StoryStepKind.puzzles:
            await _puzzles(chapter);
          case StoryStepKind.guardian:
            await _guardian(chapter);
          case StoryStepKind.boss:
            await _boss(chapter);
        }
      });

  Future<void> _lesson(StoryChapter chapter) async {
    final stage = chapter.pathChapter.stages
        .where((s) => !s.isGuardian && !widget.path.progress.isCompleted(s.id))
        .firstOrNull;
    if (stage == null) return;
    final started = DateTime.now();
    final stars = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => StagePage(stage: stage)),
    );
    if (stars != null && stars > 0) {
      await widget.path.complete(
        stage,
        stars,
        DateTime.now().difference(started),
      );
    }
  }

  Future<void> _puzzles(StoryChapter chapter) async {
    final play = widget.playPuzzles;
    if (play == null) return;
    final remaining =
        chapter.puzzleCount - widget.story.state.puzzlesSolved(chapter.id);
    final solved = await play(context, chapter, remaining);
    if (!mounted) return;
    if (solved == null) return _say(storyL10n(context).storyPuzzlesNone);
    if (solved > 0) await widget.story.puzzlesSolved(chapter, solved);
  }

  Future<void> _guardian(StoryChapter chapter) async {
    final play = widget.playGuardian;
    if (play == null) return _say(storyL10n(context).storyEngineMissing);
    final stage = chapter.pathChapter.stages.firstWhere((s) => s.isGuardian);
    final stars = await play(context, stage);
    if (stars != null && stars > 0) {
      await widget.path.complete(stage, stars, Duration.zero);
    }
  }

  Future<void> _boss(StoryChapter chapter) async {
    final play = widget.playBoss;
    if (play == null) return _say(storyL10n(context).storyEngineMissing);
    final won = await play(context, chapter.bot);
    if (!mounted) return;
    final l10n = storyL10n(context);
    if (won) {
      await widget.story.bossBeaten(chapter);
      if (mounted) _say(l10n.storyBossWon(chapter.bot.name));
    } else {
      _say(l10n.storyBossLost(chapter.bot.name));
    }
  }

  /// Primo passo da fare nel capitolo corrente.
  (StoryChapter, StoryStepKind)? get _next {
    final index = _progress.currentChapterIndex;
    if (index == null) return null;
    final chapter = storyChapters[index];
    final step = _progress.steps(chapter).firstWhere((s) => !s.done);
    return (chapter, step.kind);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = storyL10n(context);
    return ListenableBuilder(
      listenable: Listenable.merge([widget.path, widget.story]),
      builder: (context, _) {
        final progress = _progress;
        final next = _next;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.storyTitle),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    l10n.storyProgress(
                      progress.completedChapters,
                      storyChapters.length,
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: next == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _open(next.$1, next.$2),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.storyContinue),
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final (i, chapter) in storyChapters.indexed)
                _ChapterCard(
                  index: i,
                  chapter: chapter,
                  progress: progress,
                  onOpen: (kind) => _open(chapter, kind),
                ),
              if (next == null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.storyFinished,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.index,
    required this.chapter,
    required this.progress,
    required this.onOpen,
  });

  final int index;
  final StoryChapter chapter;
  final StoryProgress progress;
  final void Function(StoryStepKind kind) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = storyL10n(context);
    final theme = Theme.of(context);
    final unlocked = progress.isChapterUnlocked(index);
    final done = progress.isChapterDone(chapter);
    final title = l10n.chapterTitle(chapter);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              container: true,
              header: true,
              label:
                  '${l10n.storyChapterNumber(index + 1)}: $title'
                  '${done ? ', ${l10n.storyChapterDone}' : ''}'
                  '${unlocked ? '' : ', ${l10n.storyStepLocked}'}',
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(
                    done
                        ? Icons.check_circle
                        : unlocked
                        ? Icons.menu_book_outlined
                        : Icons.lock_outline,
                    color: unlocked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.storyChapterNumber(index + 1),
                          style: theme.textTheme.labelMedium,
                        ),
                        Text(title, style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!unlocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.storyChapterLocked),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.chapterIntro(chapter)),
              ),
              for (final step in progress.steps(chapter))
                _StepTile(
                  chapter: chapter,
                  step: step,
                  unlocked: progress.isStepUnlocked(chapter, step.kind),
                  onTap: () => onOpen(step.kind),
                ),
              if (done)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.chapterOutro(chapter),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.chapter,
    required this.step,
    required this.unlocked,
    required this.onTap,
  });

  final StoryChapter chapter;
  final StoryStep step;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = storyL10n(context);
    final title = switch (step.kind) {
      StoryStepKind.lessons => l10n.storyStepLessons(step.value, step.total),
      StoryStepKind.puzzles => l10n.storyStepPuzzles(step.value, step.total),
      StoryStepKind.guardian => l10n.storyStepGuardian,
      StoryStepKind.boss => l10n.storyStepBoss(chapter.bot.name),
    };
    final state = step.done
        ? l10n.storyStepDone
        : unlocked
        ? l10n.storyStepTodo
        : l10n.storyStepLocked;
    return Semantics(
      container: true,
      button: unlocked,
      label: '$title, $state',
      excludeSemantics: true,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        enabled: unlocked,
        leading: step.kind == StoryStepKind.boss
            ? ExcludeSemantics(
                child: Text(
                  chapter.bot.avatar,
                  style: const TextStyle(fontSize: 28),
                ),
              )
            : Icon(switch (step.kind) {
                StoryStepKind.lessons => Icons.school_outlined,
                StoryStepKind.puzzles => Icons.extension_outlined,
                _ => Icons.smart_toy_outlined,
              }),
        title: Text(title),
        subtitle: Text(
          step.kind == StoryStepKind.boss && unlocked && !step.done
              ? l10n.chapterBoss(chapter)
              : state,
        ),
        trailing: Icon(
          step.done
              ? Icons.check_circle
              : unlocked
              ? Icons.chevron_right
              : Icons.lock_outline,
        ),
        onTap: unlocked ? onTap : null,
      ),
    );
  }
}
