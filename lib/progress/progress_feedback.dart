import 'package:flutter/material.dart';

import 'progress_tracker.dart';
import 'records.dart';

String recordLabel(RecordKind kind) => switch (kind) {
  RecordKind.strongestBot => 'bot più forte battuto',
  RecordKind.fastestWin => 'vittoria più rapida',
  RecordKind.bestAccuracy => 'precisione migliore',
  RecordKind.puzzleRating => 'punteggio puzzle',
  RecordKind.puzzleRun => 'punteggio a tempo',
};

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
    for (final r in update.newRecords) 'Nuovo record: ${recordLabel(r)}',
    for (final a in update.unlocked) 'Traguardo: ${a.title}',
  ].join(' · ');
}

/// Notifica in-app non invasiva dei progressi.
void showProgressFeedback(BuildContext context, ProgressUpdate update) {
  final message = progressMessage(update);
  if (message == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
