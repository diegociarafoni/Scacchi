import '../l10n/app_localizations.dart';
import 'puzzle_run.dart';

/// Spiegazione breve di una modalità dei puzzle: cosa fare, come si vince o si
/// perde, tempo o vite e come si calcola il punteggio.
class PuzzleGuide {
  const PuzzleGuide._(this.id, [this.run]);

  /// Spiegazione di una modalità a serie, ricavata da tempo ed errori.
  factory PuzzleGuide.forRun(PuzzleRunMode mode) =>
      PuzzleGuide._(mode.name, mode);

  static const training = PuzzleGuide._('training');
  static const theme = PuzzleGuide._('theme');
  static const daily = PuzzleGuide._('daily');
  static const review = PuzzleGuide._('review');

  /// Chiave stabile, usata per ricordare che la spiegazione è già stata letta.
  final String id;

  /// La modalità a serie spiegata; `null` per le altre.
  final PuzzleRunMode? run;

  String title(AppLocalizations l10n) => switch (id) {
    'training' => l10n.puzzleTraining,
    'theme' => l10n.puzzleGuideThemeTitle,
    'daily' => l10n.puzzleDailyTitle,
    'review' => l10n.puzzleReview,
    _ => l10n.puzzleRunLabel(id),
  };

  /// Una frase: cosa bisogna ottenere.
  String goal(AppLocalizations l10n) {
    final minutes = run?.limit?.inMinutes ?? 0;
    return switch (run) {
      null when id == 'training' => l10n.puzzleGuideTrainingGoal,
      null when id == 'theme' => l10n.puzzleGuideThemeGoal,
      null when id == 'daily' => l10n.puzzleGuideDailyGoal,
      null => l10n.puzzleGuideReviewGoal,
      PuzzleRunMode.storm => l10n.puzzleGuideStormGoal(minutes),
      PuzzleRunMode.rush3 ||
      PuzzleRunMode.rush5 => l10n.puzzleGuideRushGoal(minutes),
      PuzzleRunMode.survival => l10n.puzzleGuideSurvivalGoal,
      PuzzleRunMode.streak => l10n.puzzleGuideStreakGoal,
    };
  }

  /// Regole in ordine: come si gioca, quando finisce, come si segna.
  List<String> rules(AppLocalizations l10n) {
    final base = [l10n.puzzleGuideRunBase1, l10n.puzzleGuideRunBase2];
    final tail = [l10n.puzzleGuideRunTail1, l10n.puzzleGuideRunTail2];
    return switch (run) {
      null when id == 'training' => [
        l10n.puzzleGuideTrainingRule1,
        l10n.puzzleGuideTrainingRule2,
        l10n.puzzleGuideTrainingRule3,
        l10n.puzzleGuideTrainingRule4,
        l10n.puzzleGuideTrainingRule5,
      ],
      null when id == 'theme' => [
        l10n.puzzleGuideThemeRule1,
        l10n.puzzleGuideThemeRule2,
        l10n.puzzleGuideThemeRule3,
      ],
      null when id == 'daily' => [
        l10n.puzzleGuideDailyRule1,
        l10n.puzzleGuideDailyRule2,
        l10n.puzzleGuideDailyRule3,
        l10n.puzzleGuideDailyRule4,
      ],
      null => [
        l10n.puzzleGuideReviewRule1,
        l10n.puzzleGuideReviewRule2,
        l10n.puzzleGuideReviewRule3,
        l10n.puzzleGuideReviewRule4,
      ],
      PuzzleRunMode.storm => [
        ...base,
        l10n.puzzleGuideStormRule1(PuzzleRun.wrongPenalty.inSeconds),
        l10n.puzzleGuideStormRule2,
        l10n.puzzleGuideStormRule3,
        ...tail,
      ],
      PuzzleRunMode.rush3 || PuzzleRunMode.rush5 => [
        ...base,
        l10n.puzzleGuideLivesRule1,
        l10n.puzzleGuideRushRule2,
        ...tail,
      ],
      PuzzleRunMode.survival => [
        ...base,
        l10n.puzzleGuideLivesRule1,
        l10n.puzzleGuideSurvivalRule2,
        ...tail,
      ],
      PuzzleRunMode.streak => [
        ...base,
        l10n.puzzleGuideStreakRule1,
        l10n.puzzleGuideStreakRule2,
        ...tail,
      ],
    };
  }
}
