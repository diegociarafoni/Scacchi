import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../archive/game_archive.dart';
import '../archive/saved_game.dart';
import '../l10n/app_localizations.dart';
import '../theme/rokko_theme.dart';

const _dismissedKey = 'reviewInviteDismissed';

/// Prima partita giocata e conclusa da proporre alla revisione (U10); `null`
/// se non c'è, se una partita è già stata rivista o se l'invito è stato chiuso.
Future<SavedGame?> reviewInviteGame(GameArchive archive) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dismissedKey) ?? false) return null;
  } on Object {
    return null;
  }
  final played = (await archive.list())
      .where((g) => g.isPlayed && g.finished)
      .toList();
  if (played.isEmpty || played.any((g) => g.accuracy != null)) return null;
  // La prima per data di inizio, non per ultimo salvataggio.
  return played.reduce((a, b) => b.createdAt.isBefore(a.createdAt) ? b : a);
}

/// L'invito non si ripresenta.
Future<void> dismissReviewInvite() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  } on Object {
    // Senza memoria l'invito può tornare: accettabile.
  }
}

/// Invito a rivedere la prima partita conclusa, nella scheda Tu.
class ReviewInviteCard extends StatelessWidget {
  const ReviewInviteCard({
    super.key,
    required this.game,
    required this.onReview,
    required this.onDismiss,
  });

  final SavedGame game;
  final void Function(SavedGame game) onReview;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tokens = RokkoTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reviewInviteTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.reviewInviteBody(game.titleIn(l10n)),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSecondaryContainer),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: () => onReview(game),
                    child: Text(l10n.reviewInviteAction),
                  ),
                  TextButton(
                    onPressed: onDismiss,
                    child: Text(l10n.reviewInviteDismiss),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
