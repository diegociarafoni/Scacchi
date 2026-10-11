// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Chess';

  @override
  String get kidProfileSection => 'Profile';

  @override
  String get kidProfile => 'Kid profile';

  @override
  String get kidProfileDescription =>
      'Simpler screens and words, friendly bots, no numbers';

  @override
  String get kidProgressGreat => 'Well done, keep going!';

  @override
  String get kidProgressGoal => 'Today\'s goal reached!';

  @override
  String get kidProgressLevelUp => 'You levelled up: one more star!';

  @override
  String get kidProgressFreeze => 'You earned a shield for your flame!';

  @override
  String get kidProgressChallenge => 'Challenge complete!';

  @override
  String get kidProgressAchievement => 'New achievement!';

  @override
  String kidProgressReward(String name) {
    return 'Unlocked: $name';
  }

  @override
  String get kidLevelTitle => 'Your stars';

  @override
  String get kidLevelStarsLabel => 'One star for each level reached';

  @override
  String get kidLevelProgress => 'Keep playing to earn another star!';

  @override
  String get kidLevelProgressLabel => 'Way to the next star';

  @override
  String get kidStreakOn => 'You are playing every day: your flame is lit!';

  @override
  String get kidStreakOff => 'Play today to light your flame!';

  @override
  String get kidGoalToday => 'Today\'s goal';

  @override
  String get kidChallengeProgress => 'Way to the challenge';

  @override
  String get kidPuzzleHubTitle => 'Solve puzzles and collect stars!';

  @override
  String get kidPuzzleStarsLabel => 'Stars for the puzzles you solved';

  @override
  String get kidPuzzleTraining => 'Puzzles picked for you';

  @override
  String get kidPuzzleDaily => 'A new puzzle every day';

  @override
  String get kidPuzzleReviewDue => 'Some puzzles to try again';

  @override
  String get kidPuzzleReviewNone => 'Nothing to try again today';

  @override
  String get kidPuzzleKeepGoing => 'Go on, you can do it!';

  @override
  String get kidAccuracy5 => 'Perfect!';

  @override
  String get kidAccuracy4 => 'Very good';

  @override
  String get kidAccuracy3 => 'Good';

  @override
  String get kidAccuracy2 => 'So-so';

  @override
  String get kidAccuracy1 => 'Keep practising';

  @override
  String get kidReviewAnalysing => 'Looking at the game…';

  @override
  String get kidAnalysisThinking => 'The computer is thinking…';

  @override
  String get kidEvalWhite => 'White is ahead';

  @override
  String get kidEvalBlack => 'Black is ahead';

  @override
  String get kidEvalEven => 'The game is even';
}
