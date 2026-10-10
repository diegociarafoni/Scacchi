import 'package:flutter/material.dart';

import 'progress_tracker.dart';

/// Testo che riassume un aggiornamento dei progressi, o `null` se non c'è nulla
/// da dire.
String? progressMessage(ProgressUpdate update) {
  if (update.xpGained == 0) return null;
  return [
    '+${update.xpGained} XP',
    if (update.goalReached) 'Obiettivo di oggi raggiunto',
    if (update.newLevel != null) 'Livello ${update.newLevel}!',
    if (update.freezeEarned) 'Hai guadagnato una protezione della serie',
    for (final a in update.unlocked) 'Traguardo: ${a.title}',
  ].join(' · ');
}

/// Notifica in-app non invasiva dei progressi.
void showProgressFeedback(BuildContext context, ProgressUpdate update) {
  final message = progressMessage(update);
  if (message == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
