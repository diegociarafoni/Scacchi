import 'package:flutter/material.dart';

import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../path/curriculum.dart';
import '../puzzles/themes.dart';
import '../settings/settings.dart';
import 'week_log.dart';
import 'weekly_summary.dart';

/// Apre una lezione del Percorso.
typedef OpenLesson = void Function(BuildContext context, Stage stage);

/// Apre i puzzle di un tema, con il suo nome per il titolo.
typedef OpenPuzzles = void Function(
  BuildContext context,
  String theme,
  String title,
);

/// Scheda del riepilogo settimanale (RG-16): progressi, errore ricorrente e
/// un consiglio. Senza [openLesson] e [openPuzzles] il consiglio resta solo
/// testo.
class WeeklySummaryPage extends StatelessWidget {
  const WeeklySummaryPage({
    super.key,
    required this.log,
    this.now,
    this.openLesson,
    this.openPuzzles,
  });

  final WeekLog log;
  final DateTime Function()? now;
  final OpenLesson? openLesson;
  final OpenPuzzles? openPuzzles;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final kid = AppSettings.of(context).kidMode;
    final summary = WeeklySummary.from(log, (now ?? DateTime.now)());
    return Scaffold(
      appBar: AppBar(title: Text(l.weeklyEntryTitle)),
      body: summary.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.weeklyEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Heading(l.weeklyProgressHeading),
                if (kid) _KidProgress(summary) else _Progress(summary),
                if (summary.topError != null || !kid) ...[
                  _Heading(l.weeklyErrorHeading),
                  _ErrorSection(summary, kid: kid),
                ],
                _Heading(l.weeklyAdviceHeading),
                _AdviceSection(
                  summary.advice,
                  kid: kid,
                  openLesson: openLesson,
                  openPuzzles: openPuzzles,
                ),
              ],
            ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
  );
}

class _Progress extends StatelessWidget {
  const _Progress(this.summary);

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = summary.week;
    final change = summary.accuracyChange?.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (w.games > 0) ...[
          _Line(l.weeklyGames(w.games)),
          _Line(l.weeklyGameResults(w.wins, w.draws, w.losses)),
        ],
        if (w.puzzles > 0) _Line(l.weeklyPuzzles(w.puzzles)),
        if (w.lessons > 0) _Line(l.weeklyLessons(w.lessons)),
        if (w.reviews > 0) _Line(l.weeklyReviews(w.reviews)),
        if (w.minutes > 0) _Line(l.weeklyMinutes(w.minutes)),
        if (w.accuracy != null) _Line(l.weeklyAccuracy(w.accuracy!.round())),
        if (change != null && change != 0)
          _Line(
            change > 0
                ? l.weeklyAccuracyUp(change)
                : l.weeklyAccuracyDown(-change),
          ),
      ],
    );
  }
}

/// Profilo bambino (RP-06): stelle per i giorni di allenamento, nessun numero.
class _KidProgress extends StatelessWidget {
  const _KidProgress(this.summary);

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KidStars(count: summary.week.activeDays, label: l.weeklyKidDaysLabel),
        _Line(l.weeklyKidActive),
      ],
    );
  }
}

String _errorName(AppLocalizations l, String error) => switch (error) {
  'hangingPiece' => l.weeklyErrorHangingPiece,
  'allowedFork' => l.weeklyErrorAllowedFork,
  'missedFork' => l.weeklyErrorMissedFork,
  'allowedPin' => l.weeklyErrorAllowedPin,
  'missedDiscovery' => l.weeklyErrorMissedDiscovery,
  'exposedKing' => l.weeklyErrorExposedKing,
  'missedMate' => l.weeklyErrorMissedMate,
  'allowedMate' => l.weeklyErrorAllowedMate,
  'materialLoss' => l.weeklyErrorMaterialLoss,
  'missedCapture' => l.weeklyErrorMissedCapture,
  _ => error,
};

class _ErrorSection extends StatelessWidget {
  const _ErrorSection(this.summary, {required this.kid});

  final WeeklySummary summary;
  final bool kid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final error = summary.topError;
    if (error == null) return _Line(l.weeklyNoError);
    final name = _errorName(l, error);
    return _Line(
      kid
          ? l.weeklyKidError(name)
          : l.weeklyErrorLine(name, summary.topErrorCount),
    );
  }
}

class _AdviceSection extends StatelessWidget {
  const _AdviceSection(
    this.advice, {
    required this.kid,
    this.openLesson,
    this.openPuzzles,
  });

  final Advice advice;
  final bool kid;
  final OpenLesson? openLesson;
  final OpenPuzzles? openPuzzles;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Il profilo bambino non ha la revisione delle partite.
    final kind = kid && advice.kind == AdviceKind.reviewGame
        ? AdviceKind.solvePuzzles
        : advice.kind;
    Stage? stage;
    if (kind == AdviceKind.lesson) {
      for (final chapter in curriculum) {
        for (final s in chapter.stages) {
          if (s.id == advice.target) stage = s;
        }
      }
    }
    final themeTitle = puzzleThemeLabels[advice.target];
    final text = switch (kind) {
      AdviceKind.lesson when stage != null => l.weeklyAdviceLesson(stage.title),
      AdviceKind.puzzles when themeTitle != null => l.weeklyAdvicePuzzles(
        themeTitle,
      ),
      AdviceKind.reviewGame => l.weeklyAdviceReview,
      AdviceKind.keepGoing => l.weeklyAdviceKeepGoing,
      _ => l.weeklyAdviceSolvePuzzles,
    };
    final VoidCallback? action;
    final String label;
    if (kind == AdviceKind.lesson && stage != null && openLesson != null) {
      final target = stage;
      action = () => openLesson!(context, target);
      label = l.weeklyOpenLesson;
    } else if (kind == AdviceKind.puzzles &&
        themeTitle != null &&
        openPuzzles != null) {
      action = () => openPuzzles!(context, advice.target!, themeTitle);
      label = l.weeklyOpenPuzzles;
    } else {
      action = null;
      label = '';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(text),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: action,
              child: Text(label),
            ),
          ),
      ],
    );
  }
}
