import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/sheets.dart';
import 'mode_guide.dart';

/// Obiettivo e regole di una modalità, con un pulsante per proseguire.
class GuideBody extends StatelessWidget {
  const GuideBody({
    super.key,
    required this.guide,
    required this.actionLabel,
    required this.onAction,
    this.footer,
  });

  final PuzzleGuide guide;
  final String actionLabel;
  final VoidCallback onAction;

  /// Riga facoltativa sotto le regole, per esempio il record personale.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(guide.title(l), style: text.headlineSmall),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              l.puzzleGuideGoalHeading,
              style: text.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(guide.goal(l), style: text.titleMedium),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              l.puzzleGuideRulesHeading,
              style: text.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final rule in guide.rules(l))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(rule, style: text.bodyMedium)),
                ],
              ),
            ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            Text(footer!, style: text.bodyMedium),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

/// Apre la spiegazione di [guide] in un pannello dal basso.
Future<void> showPuzzleGuide(BuildContext context, PuzzleGuide guide) {
  return showRokkoSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => GuideBody(
      guide: guide,
      actionLabel: AppLocalizations.of(sheet).puzzleGuideGotIt,
      onAction: () => Navigator.of(sheet).pop(),
    ),
  );
}
