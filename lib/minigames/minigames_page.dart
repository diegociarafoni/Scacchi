import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../progress/activity.dart';
import '../progress/progress_controller.dart';
import '../progress/progress_feedback.dart';
import 'capture_all_page.dart';
import 'coordinates_page.dart';
import 'minigame.dart';
import 'quiz.dart';
import 'quiz_page.dart';

/// Elenco dei minigiochi (RG-10) con il record di ciascuno.
class MinigamesPage extends StatelessWidget {
  const MinigamesPage({super.key, this.progress});

  /// Progressi in cui registrare i punteggi; senza, si gioca e basta.
  final ProgressController? progress;

  void _open(BuildContext context, Minigame game) {
    final random = Random();
    final l10n = AppLocalizations.of(context);
    Future<void> finished(MinigameResult result) async {
      final update = await progress?.record(
        MinigameFinished(
          game: game.id,
          score: result.score,
          duration: result.duration,
        ),
      );
      if (update != null && context.mounted) {
        showProgressFeedback(context, update);
      }
    }

    final page = switch (game) {
      Minigame.coordinates => CoordinatesPage(
        random: random,
        onFinished: finished,
      ),
      Minigame.captureAll => CaptureAllPage(
        random: random,
        onFinished: finished,
      ),
      Minigame.blind => QuizPage(
        title: game.title(l10n),
        next: blindItem,
        random: random,
        onFinished: finished,
      ),
      Minigame.material => QuizPage(
        title: game.title(l10n),
        next: materialItem,
        random: random,
        onFinished: finished,
      ),
    };
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.minigamesTitle)),
      body: ListenableBuilder(
        listenable: progress ?? const AlwaysStoppedAnimation(0),
        builder: (context, _) {
          final showRecords = progress?.settings.enabled ?? false;
          final records = progress?.state.records.minigames ?? const {};
          return ListView(
            children: [
              for (final game in Minigame.values)
                ListTile(
                  title: Text(game.title(l10n)),
                  subtitle: Text(game.description(l10n)),
                  trailing: switch (records[game.id]) {
                    final record? when showRecords => Text(
                      l10n.minigamesRecord(record),
                    ),
                    _ => null,
                  },
                  onTap: () => _open(context, game),
                ),
            ],
          );
        },
      ),
    );
  }
}
