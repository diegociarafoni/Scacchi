import 'package:flutter/material.dart';

import '../progress/avatar.dart';
import '../progress/guardian_avatar.dart';
import 'story.dart';
import 'story_l10n.dart';

/// Il custode di [chapter] che dice una battuta: avatar decorativo e testo
/// letto come «{nome} dice: …».
class GuardianSays extends StatelessWidget {
  const GuardianSays({
    super.key,
    required this.chapter,
    required this.moment,
    this.expression = AvatarExpression.neutral,
    this.size = 48,
    this.style,
  });

  final StoryChapter chapter;
  final GuardianMoment moment;
  final AvatarExpression expression;
  final double size;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = storyL10n(context);
    final line = l10n.guardianLine(chapter, moment);
    return Semantics(
      container: true,
      label: l10n.storyGuardianSays(chapter.bot.name, line),
      excludeSemantics: true,
      child: Row(
        children: [
          GuardianAvatar(bot: chapter.bot, expression: expression, size: size),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              line,
              style:
                  style ??
                  Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
