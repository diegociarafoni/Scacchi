import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import 'progress_tracker.dart';
import 'rewards.dart';

/// Testo che riassume un aggiornamento dei progressi, o `null` se non c'è nulla
/// da dire.
String? progressMessage(ProgressUpdate update) {
  if (update.xpGained == 0) return null;
  return [
    '+${update.xpGained} XP',
    if (update.goalReached) 'Obiettivo di oggi raggiunto',
    if (update.newLevel != null) 'Livello ${update.newLevel}!',
    if (update.freezeEarned) 'Hai guadagnato una protezione della serie',
    for (final c in update.challengesCompleted) 'Sfida completata: ${c.title}',
    if (update.weeklyCompleted) 'Sfida della settimana completata',
    for (final r in update.newRecords) 'Nuovo record: ${r.label.toLowerCase()}',
    for (final a in update.unlocked) 'Traguardo: ${a.title}',
    for (final r in update.rewards) 'Sbloccato: ${rewardName(r)}',
  ].join(' · ');
}

/// Versione del profilo bambino: solo incoraggiamenti, senza XP né numeri.
/// I titoli di sfide e traguardi possono contenere cifre e non si ripetono;
/// i record sono tutti numerici e restano fuori.
String? kidProgressMessage(ProgressUpdate update, AppLocalizations l) {
  if (update.xpGained == 0) return null;
  return [
    l.kidProgressGreat,
    if (update.goalReached) l.kidProgressGoal,
    if (update.newLevel != null) l.kidProgressLevelUp,
    if (update.freezeEarned) l.kidProgressFreeze,
    if (update.challengesCompleted.isNotEmpty || update.weeklyCompleted)
      l.kidProgressChallenge,
    if (update.unlocked.isNotEmpty) l.kidProgressAchievement,
    for (final r in update.rewards) l.kidProgressReward(rewardName(r)),
  ].join(' · ');
}

/// Notifica in-app non invasiva dei progressi.
void showProgressFeedback(BuildContext context, ProgressUpdate update) {
  final message = AppSettings.of(context).kidMode
      ? kidProgressMessage(update, AppLocalizations.of(context))
      : progressMessage(update);
  if (message == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
