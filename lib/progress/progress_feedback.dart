import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import '../theme/rokko_theme.dart';
import 'achievements_l10n.dart';
import 'progress_tracker.dart';
import 'rewards.dart';

/// Testo che riassume un aggiornamento dei progressi, o `null` se non c'è nulla
/// da dire.
String? progressMessage(ProgressUpdate update, AppLocalizations l) {
  if (update.xpGained == 0) return null;
  return [
    l.progressFeedbackXp(update.xpGained),
    if (update.goalReached) l.progressFeedbackGoal,
    if (update.newLevel != null) l.progressFeedbackLevel(update.newLevel!),
    if (update.freezeEarned) l.progressFeedbackFreeze,
    for (final c in update.challengesCompleted)
      l.progressFeedbackChallenge(c.title(l)),
    if (update.weeklyCompleted) l.progressFeedbackWeekly,
    for (final r in update.newRecords) l.progressFeedbackRecord(r.label(l)),
    for (final a in update.unlocked)
      l.progressFeedbackAchievement(achievementTitle(l, a)),
    for (final r in update.rewards) l.progressFeedbackReward(rewardName(l, r)),
  ].join(' · ');
}

/// Versione del profilo bambino: solo incoraggiamenti, senza XP né numeri.
/// I titoli di sfide e traguardi possono contenere cifre e non si ripetono;
/// i record sono tutti numerici e restano fuori. Lo scudo della serie non si
/// vede nel profilo bambino, quindi non si annuncia; il nome della ricompensa
/// è solo in italiano e resta fuori, per non mescolare le lingue.
String? kidProgressMessage(ProgressUpdate update, AppLocalizations l) {
  if (update.xpGained == 0) return null;
  return [
    l.kidProgressGreat,
    if (update.goalReached) l.kidProgressGoal,
    if (update.newLevel != null) l.kidProgressLevelUp,
    if (update.challengesCompleted.isNotEmpty || update.weeklyCompleted)
      l.kidProgressChallenge,
    if (update.unlocked.isNotEmpty) l.kidProgressAchievement,
    if (update.rewards.isNotEmpty) l.kidProgressReward,
  ].join(' · ');
}

/// Testo dei progressi nella lingua e nel profilo in uso, o `null`.
String? progressText(BuildContext context, ProgressUpdate update) {
  final l = AppLocalizations.of(context);
  return AppSettings.of(context).kidMode
      ? kidProgressMessage(update, l)
      : progressMessage(update, l);
}

/// Notifica in-app non invasiva dei progressi. Nelle schermate con pulsanti
/// in basso si usa [ProgressNote] in linea: la barra copre i comandi.
void showProgressFeedback(BuildContext context, ProgressUpdate update) {
  final message = progressText(context, update);
  if (message == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Riga dei progressi guadagnati, da mettere negli spazi liberi sopra i
/// comandi invece di una barra a comparsa.
class ProgressNote extends StatelessWidget {
  const ProgressNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: const Key('puzzle-progress-note'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(
            RokkoTokens.of(context).radiusSmall,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Semantics(
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ),
      ),
    );
  }
}
