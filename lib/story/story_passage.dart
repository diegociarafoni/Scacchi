import 'package:flutter/material.dart';

import '../progress/avatar.dart';
import '../progress/guardian_avatar.dart';
import '../theme/rokko_theme.dart';
import 'story.dart';
import 'story_l10n.dart';

/// Scelta fatta nel riquadro mostrato a fine puzzle, letta dalla Storia al
/// ritorno al posto del foglio di passaggio.
enum PassageChoice { none, go, later }

/// Contenuto del passaggio fra un passo e l'altro: lo usano il foglio della
/// Storia e il riquadro a fine puzzle.
class StoryPassage {
  const StoryPassage({
    required this.chapter,
    required this.icon,
    required this.title,
    required this.body,
    required this.dismiss,
    this.target,
    this.subtitle,
    this.action,
    this.expression,
    this.line,
  });

  final StoryChapter chapter;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String body;
  final String? action;
  final String dismiss;
  final AvatarExpression? expression;
  final String? line;

  /// Passo da aprire se si sceglie l'azione.
  final (StoryChapter, StoryStepKind)? target;

  Widget sheet({
    VoidCallback? onAction,
    VoidCallback? onDismiss,
    bool card = false,
  }) => Builder(
    builder: (context) => StoryPassageSheet(
      onAction: onAction,
      onDismiss: onDismiss,
      icon: icon,
      guardian: expression == null
          ? null
          : GuardianAvatar(bot: chapter.bot, expression: expression!, size: 88),
      guardianLine: line == null
          ? null
          : storyL10n(context).storyGuardianSays(chapter.bot.name, line!),
      title: title,
      subtitle: subtitle,
      body: body,
      action: action,
      dismiss: dismiss,
    ),
  );
}

/// Il passaggio dopo [kind], o `null` se il passo non è concluso. Con
/// [assumeDone] il passo conta come concluso anche se non ancora salvato:
/// serve a chi lo mostra proprio mentre il passo finisce.
StoryPassage? storyPassage(
  BuildContext context,
  StoryProgress progress,
  StoryChapter chapter,
  StoryStepKind kind, {
  bool assumeDone = false,
}) {
  final step = progress.steps(chapter).firstWhere((s) => s.kind == kind);
  if (!step.done && !assumeDone) return null;
  final l10n = storyL10n(context);
  final index = storyChapters.indexOf(chapter);
  (StoryChapter, StoryStepKind)? target;
  final String title;
  String? subtitle;
  final String body;
  String? action;
  var icon = Icons.check;
  AvatarExpression? expression;
  String? line;
  if (progress.isChapterDone(chapter)) {
    final hasNext = index + 1 < storyChapters.length;
    final nextChapter = hasNext ? storyChapters[index + 1] : null;
    icon = Icons.emoji_events_outlined;
    title = hasNext
        ? l10n.storyPassageChapterTitle(index)
        : l10n.storyPassageStoryDone;
    if (kind == StoryStepKind.boss) {
      subtitle = l10n.storyBossWon(chapter.bot.name);
      expression = AvatarExpression.surprised;
      line = l10n.guardianLine(chapter, GuardianMoment.bossWon);
    }
    body = nextChapter == null
        ? l10n.chapterOutro(chapter)
        : '${l10n.chapterOutro(chapter)}\n\n'
              '${l10n.storyPassageChapterNext(index + 1, l10n.chapterTitle(nextChapter))}';
    if (nextChapter != null) {
      action = l10n.storyPassageGoChapter;
      target = (nextChapter, StoryStepKind.lessons);
    }
  } else {
    final next = progress
        .steps(chapter)
        .firstWhere((s) => !s.done && s.kind != (assumeDone ? kind : null))
        .kind;
    target = (chapter, next);
    title = switch (kind) {
      StoryStepKind.lessons => l10n.storyPassageLessonsTitle,
      StoryStepKind.puzzles => l10n.storyPassagePuzzlesTitle,
      _ => l10n.storyPassageGuardianTitle,
    };
    body = switch (next) {
      StoryStepKind.puzzles => l10n.storyPassageNextPuzzles,
      StoryStepKind.guardian => l10n.storyPassageNextGuardian,
      _ => l10n.storyPassageNextBoss(chapter.bot.name),
    };
    action = switch (next) {
      StoryStepKind.puzzles => l10n.storyPassageGoPuzzles,
      StoryStepKind.guardian => l10n.storyPassageGoGuardian,
      _ => l10n.storyPassageGoBoss(chapter.bot.name),
    };
    if (next == StoryStepKind.boss) {
      expression = AvatarExpression.challenge;
      line = l10n.guardianLine(chapter, GuardianMoment.boss);
    } else if (kind == StoryStepKind.lessons) {
      expression = AvatarExpression.happy;
      line = l10n.guardianLine(chapter, GuardianMoment.lessonDone);
    }
  }

  return StoryPassage(
    chapter: chapter,
    icon: icon,
    title: title,
    subtitle: subtitle,
    body: body,
    action: action,
    dismiss: action == null ? l10n.storyPassageClose : l10n.storyPassageLater,
    target: target,
    expression: expression,
    line: line,
  );
}

/// Foglio di passaggio fra un passo e l'altro: icona che compare con un
/// piccolo rimbalzo (ferma se l'utente ha disattivato le animazioni), cosa è
/// stato fatto e cosa viene dopo.
class StoryPassageSheet extends StatelessWidget {
  const StoryPassageSheet({
    super.key,
    this.onAction,
    this.onDismiss,
    this.card = false,
    required this.icon,
    required this.title,
    required this.body,
    required this.dismiss,
    this.guardian,
    this.guardianLine,
    this.subtitle,
    this.action,
  });

  /// Avatar del custode al posto dell'icona e la sua battuta, già
  /// nella forma «{nome} dice: …».
  final Widget? guardian;
  final String? guardianLine;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String body;
  final String? action;
  final String dismiss;

  /// Senza callback i pulsanti chiudono il foglio con `true` o `false`.
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  /// Dentro una pagina e non in un foglio: niente area sicura né scorrimento.
  final bool card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = RokkoTokens.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: still ? 1 : 0, end: 1),
            duration: still ? Duration.zero : const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, t, _) => Transform.scale(
              scale: t,
              child: Column(
                children: [
                  guardian ??
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.action,
                        ),
                        child: Icon(icon, size: 40, color: tokens.onAction),
                      ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final size in const [18.0, 26.0, 18.0])
                        Icon(Icons.star, size: size, color: tokens.star),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        if (guardianLine != null) ...[
          const SizedBox(height: 12),
          Text(
            guardianLine!,
            key: const ValueKey('story-passage-guardian'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (action != null)
          FilledButton(
            onPressed: onAction ?? () => Navigator.pop(context, true),
            child: Text(action!),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onDismiss ?? () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            minimumSize: Size.fromHeight(tokens.minTouch),
          ),
          child: Text(dismiss),
        ),
      ],
    );
    // Nella pagina del puzzle scorre già la pagina intera.
    if (card) {
      return Padding(
        key: const ValueKey('story-passage'),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: content,
      );
    }
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('story-passage'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: content,
      ),
    );
  }
}
