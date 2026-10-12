// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rokko';

  @override
  String get kidProfileSection => 'Profile';

  @override
  String get kidProfile => 'Kid profile';

  @override
  String get kidProfileDescription =>
      'Simpler screens and words, friendly bots, no numbers';

  @override
  String get kidAdultGateTitle => 'Ask a grown-up';

  @override
  String kidAdultGateQuestion(int a, int b) {
    return 'To leave the kid profile: what is $a × $b?';
  }

  @override
  String get kidAdultGateWrong => 'Wrong answer.';

  @override
  String get kidAdultGateConfirm => 'Confirm';

  @override
  String get kidBotPinoDescription => 'A cheerful chick who loves to attack';

  @override
  String get kidBotChiaraDescription => 'Plays calmly and waits for your moves';

  @override
  String get kidBotRoccoDescription => 'A clever fox full of surprises';

  @override
  String get kidBotUnavailable => 'Bots are not available on this device.';

  @override
  String get kidGameYourTurn => 'Your turn!';

  @override
  String kidGameTurnSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'White\'s turn!',
      'other': 'Black\'s turn!',
    });
    return '$_temp0';
  }

  @override
  String kidGameTurnName(String name) {
    return '$name, your turn!';
  }

  @override
  String kidGameOpponentTurn(String name) {
    return '$name is about to move';
  }

  @override
  String kidGameThinking(String name) {
    return '$name is thinking…';
  }

  @override
  String kidGameDrawThinking(String name) {
    return '$name is thinking it over…';
  }

  @override
  String get kidGameCheckYou => 'Check! Your king is in danger';

  @override
  String get kidGameCheckOpponent => 'Check! The other king is in danger';

  @override
  String kidGameCheckSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Check! The white king is in danger',
      'other': 'Check! The black king is in danger',
    });
    return '$_temp0';
  }

  @override
  String kidGameCheckName(String name) {
    return 'Check! $name, your king is in danger';
  }

  @override
  String get kidGameCheckmate => 'Checkmate!';

  @override
  String get kidGameTimeUp => 'Time\'s up!';

  @override
  String get kidGameKingOfTheHill => 'The king reached the center!';

  @override
  String get kidGameThirdCheck => 'Third check!';

  @override
  String get kidGameOver => 'Game over!';

  @override
  String get kidGameYouResigned => 'You gave up.';

  @override
  String kidGameResignedSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'White gives up.',
      'other': 'Black gives up.',
    });
    return '$_temp0';
  }

  @override
  String kidGameResignedName(String name) {
    return '$name gives up.';
  }

  @override
  String get kidGameYouWon => 'You won!';

  @override
  String kidGameOpponentWon(String name) {
    return '$name won. Try again!';
  }

  @override
  String kidGameWinnerSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'White won!',
      'other': 'Black won!',
    });
    return '$_temp0';
  }

  @override
  String kidGameWinnerName(String name) {
    return '$name won!';
  }

  @override
  String get kidGameStalemate =>
      'Stalemate: the king can\'t move but isn\'t in check. It\'s a draw!';

  @override
  String get kidGameInsufficientMaterial =>
      'Too few pieces are left to checkmate. It\'s a draw!';

  @override
  String get kidGameRepetition =>
      'The same position came back three times. It\'s a draw!';

  @override
  String get kidGameFiftyMoves =>
      'Lots of moves with no captures or pawn moves. It\'s a draw!';

  @override
  String get kidGameAgreedDraw => 'You agreed on a draw!';

  @override
  String get kidGameTimeUpDraw =>
      'Time\'s up, but no one can win with these pieces. It\'s a draw!';

  @override
  String get kidGameComputer => 'The computer';

  @override
  String get kidGameNew => 'New game';

  @override
  String get kidGameDraw => 'Draw?';

  @override
  String get kidGameResign => 'I give up';

  @override
  String get kidGameResignTitle => 'Do you want to give up?';

  @override
  String kidGameResignTitleSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'White, do you want to give up?',
      'other': 'Black, do you want to give up?',
    });
    return '$_temp0';
  }

  @override
  String kidGameResignTitleName(String name) {
    return '$name, do you want to give up?';
  }

  @override
  String get kidGameResignBody => 'If you give up, the game ends.';

  @override
  String get kidGameResignNo => 'No, keep playing';

  @override
  String get kidGameResignYes => 'Yes, I give up';

  @override
  String kidGameDrawOfferSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'White, do you want a draw?',
      'other': 'Black, do you want a draw?',
    });
    return '$_temp0';
  }

  @override
  String kidGameDrawOfferName(String name) {
    return '$name, do you want a draw?';
  }

  @override
  String get kidGameDrawNo => 'No, let\'s play';

  @override
  String get kidGameDrawYes => 'Yes, draw';

  @override
  String kidGameDrawAccepted(String name) {
    return '$name accepts the draw!';
  }

  @override
  String kidGameDrawRefused(String name) {
    return '$name wants to keep playing.';
  }

  @override
  String get kidGameTimeTitle => 'How much time?';

  @override
  String get kidGameSlowClock => 'With a clock, no rush';

  @override
  String get kidGameUndo => 'Undo';

  @override
  String get kidGameFlip => 'Flip';

  @override
  String get kidGameWhiteName => 'White\'s name';

  @override
  String get kidGameBlackName => 'Black\'s name';

  @override
  String get kidGameNameHint => 'Optional';

  @override
  String get kidGameNoClock => 'No clock';

  @override
  String get kidGameCoach => 'Coach';

  @override
  String get kidGameHint => 'Hint';

  @override
  String get kidProgressGreat => 'Well done, keep going!';

  @override
  String get kidProgressGoal => 'Today\'s goal reached!';

  @override
  String get kidProgressLevelUp => 'You levelled up: one more star!';

  @override
  String get kidProgressChallenge => 'Challenge complete!';

  @override
  String get kidProgressAchievement => 'New achievement!';

  @override
  String get kidProgressReward => 'You unlocked a reward!';

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
  String puzzleGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'mateIn1': 'Goal: mate in 1',
      'mateIn2': 'Goal: mate in 2',
      'mateIn3': 'Goal: mate in 3',
      'mateIn4': 'Goal: mate in 4',
      'mate': 'Goal: checkmate the opponent',
      'crushing': 'Goal: get a decisive advantage',
      'advantage': 'Goal: get the advantage',
      'equality': 'Goal: reach equality',
      'other': 'Goal: find the best move',
    });
    return '$_temp0';
  }

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

  @override
  String get kidUnlockByPlaying => 'Unlocks as you play';

  @override
  String get kidCoachMaterialLoss => 'Careful: this move loses pieces.';

  @override
  String kidCoachAllowedMate(String move, String reply) {
    return 'After $move your opponent can checkmate with $reply.';
  }

  @override
  String kidCoachMissedMate(String move) {
    return 'You could checkmate with $move!';
  }

  @override
  String get qrSendTitle => 'Pass via QR';

  @override
  String get qrSendHint =>
      'On the other phone open You › Archive › Receive via QR and frame the code.';

  @override
  String qrPart(int current, int total) {
    return 'Part $current of $total';
  }

  @override
  String get qrPause => 'Pause';

  @override
  String get qrResume => 'Resume';

  @override
  String get qrNext => 'Next part';

  @override
  String get qrPrevious => 'Previous part';

  @override
  String get qrCodeLabel => 'Game QR code';

  @override
  String get qrReceiveTitle => 'Receive via QR';

  @override
  String get qrReceiveHint => 'Frame the QR code shown on the other phone.';

  @override
  String qrReceived(int received, int total) {
    return '$received of $total parts read';
  }

  @override
  String get qrForeign => 'This QR code does not contain a game.';

  @override
  String get qrCorrupted => 'The QR code is damaged: start reading again.';

  @override
  String get qrTooLarge => 'The game is too large to receive.';

  @override
  String get qrRestarted => 'New game framed: reading restarted.';

  @override
  String get qrCameraError =>
      'The camera is not available. Allow Rokko to use the camera in the phone settings and try again.';

  @override
  String get qrRetry => 'Try again';

  @override
  String get qrInvalidGame => 'The QR code does not contain a valid game.';

  @override
  String get qrFinishedGame =>
      'The game is already over: receive it from You › Archive › Receive via QR.';

  @override
  String get qrMalformed => 'Invalid QR code: ignored.';

  @override
  String get editorFenTitle => 'Position (FEN)';

  @override
  String get editorFenHelpTooltip => 'What is FEN?';

  @override
  String get editorFenHelpBody =>
      'FEN is a line of text that describes a position: the pieces on the board, whose turn it is, castling rights and move counters. Use it to copy the position to other apps or to paste one you received: use the copy and paste buttons above.';

  @override
  String get editorFenHelpClose => 'Got it';

  @override
  String get backupTitle => 'Backup and restore';

  @override
  String get backupIntro =>
      'The backup contains games, progress, learning path, tournaments, training and settings. Keep it somewhere safe: the app works offline, so there is no online copy.';

  @override
  String get backupShare => 'Share the backup';

  @override
  String get backupShareSubject => 'Rokko backup';

  @override
  String get backupRestoreFromText => 'Restore from text';

  @override
  String get backupExported => 'Backup ready to save';

  @override
  String backupExportFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get backupRestoreStaged =>
      'Backup ready. Close and reopen the app to restore your data.';

  @override
  String backupRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get backupErrorNotApp => 'This is not a Rokko backup';

  @override
  String get backupErrorNewerVersion => 'Backup created by a newer version';

  @override
  String backupErrorUnexpectedFile(String file) {
    return 'Unexpected file in the backup: $file';
  }

  @override
  String backupErrorInvalidFile(String file) {
    return 'Invalid file in the backup: $file';
  }

  @override
  String backupErrorInvalidPreference(String name) {
    return 'Invalid preference: $name';
  }

  @override
  String get backupErrorUnreadable => 'Unreadable backup';

  @override
  String get backupRestoreDialogTitle => 'Restore the backup';

  @override
  String get backupRestoreDialogBody =>
      'Paste the contents of the backup file. Your current data will be replaced.';

  @override
  String get backupCancel => 'Cancel';

  @override
  String get backupRestore => 'Restore';

  @override
  String get minigamesTitle => 'Minigames';

  @override
  String minigamesRecord(int score) {
    return 'Best $score';
  }

  @override
  String get minigamesCoordinatesTitle => 'Timed coordinates';

  @override
  String get minigamesCoordinatesDescription =>
      'Tap the given square: how many can you find in 30 seconds?';

  @override
  String get minigamesCaptureAllTitle => 'Capture them all';

  @override
  String get minigamesCaptureAllDescription =>
      'A single piece captures every pawn in as few moves as possible.';

  @override
  String get minigamesBlindTitle => 'Blindfold';

  @override
  String get minigamesBlindDescription =>
      'Read the moves without a board and say what is on a square.';

  @override
  String get minigamesMaterialTitle => 'Material count';

  @override
  String get minigamesMaterialDescription => 'Who is ahead, and by how much?';

  @override
  String get minigamesAgain => 'Again';

  @override
  String get minigamesDone => 'Done';

  @override
  String get minigamesNext => 'Next';

  @override
  String minigamesCaptureAllProgress(int board, int total) {
    return 'Board $board of $total';
  }

  @override
  String get minigamesCaptureAllSessionOver => 'Session over';

  @override
  String minigamesCaptureAllScore(int score, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score stars out of $max',
      one: '$score star out of $max',
    );
    return '$_temp0';
  }

  @override
  String minigamesCaptureAllMoves(int moves, int optimal) {
    return 'Moves $moves, minimum $optimal';
  }

  @override
  String minigamesCaptureAllStars(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars stars out of 3',
      one: '$stars star out of 3',
    );
    return '$_temp0';
  }

  @override
  String get minigamesCaptureAllRetry => 'Start over';

  @override
  String minigamesCoordinatesTarget(String square) {
    return 'Tap the square $square';
  }

  @override
  String minigamesCoordinatesScore(int score) {
    return 'Score $score';
  }

  @override
  String minigamesCoordinatesSecondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '$seconds second',
    );
    return '$_temp0';
  }

  @override
  String get minigamesCoordinatesTimeUp => 'Time\'s up';

  @override
  String minigamesCoordinatesSummary(int score, int mistakes) {
    return 'Score $score: $score right, $mistakes wrong';
  }

  @override
  String get minigamesCoordinatesIntro =>
      'Tap the given square, with no coordinates on the board. You have 30 seconds.';

  @override
  String get minigamesCoordinatesWhite => 'White';

  @override
  String get minigamesCoordinatesBlack => 'Black';

  @override
  String get minigamesCoordinatesStart => 'Start';

  @override
  String minigamesQuizResult(int score, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score correct answers out of $total',
      one: '$score correct answer out of $total',
    );
    return '$_temp0';
  }

  @override
  String minigamesQuizQuestion(int number, int total) {
    return 'Question $number of $total';
  }

  @override
  String get minigamesQuizCorrect => 'Correct!';

  @override
  String minigamesQuizAnswer(String answer) {
    return 'It was: $answer';
  }

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsLoadFailed =>
      'The game archive could not be read: try again later.';

  @override
  String get statsEmpty =>
      'Play a few games against the computer to see your statistics.';

  @override
  String get statsRecord => 'Results';

  @override
  String get statsAllGames => 'All';

  @override
  String get statsWithWhite => 'With white';

  @override
  String get statsWithBlack => 'With black';

  @override
  String get statsLocalGames => 'Two-player games';

  @override
  String get statsByTimeControl => 'By time control';

  @override
  String get statsTopOpenings => 'Most played openings';

  @override
  String statsGames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '$count game',
    );
    return '$_temp0';
  }

  @override
  String get statsAccuracy => 'Accuracy';

  @override
  String get statsAverage => 'Average';

  @override
  String get statsAccuracyTrend => 'Accuracy trend';

  @override
  String statsRating(int rating) {
    return 'Estimated rating $rating';
  }

  @override
  String statsRatingProvisional(int count) {
    return 'provisional: $count games against the computer are needed';
  }

  @override
  String statsRatingGames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'from $count games against the computer',
      one: 'from $count game against the computer',
    );
    return '$_temp0';
  }

  @override
  String get statsRatingTrend => 'Rating trend';

  @override
  String get statsNoGames => 'no games';

  @override
  String statsScoreDetail(int wins, int draws, int losses) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins wins',
      one: '$wins win',
    );
    String _temp1 = intl.Intl.pluralLogic(
      draws,
      locale: localeName,
      other: '$draws draws',
      one: '$draws draw',
    );
    String _temp2 = intl.Intl.pluralLogic(
      losses,
      locale: localeName,
      other: '$losses losses',
      one: '$losses loss',
    );
    return '$_temp0, $_temp1, $_temp2';
  }

  @override
  String statsTrend(
    String label,
    String first,
    String last,
    String min,
    String max,
  ) {
    return '$label: from $first to $last, minimum $min, maximum $max';
  }

  @override
  String get opponentHintHuman => 'Two players share the same device.';

  @override
  String get opponentHintComputer => 'Pick a level or let it adapt to you.';

  @override
  String get opponentHintBot =>
      'Opponents with a personality, unlocked one by one.';

  @override
  String botUnlockHint(String name) {
    return 'Unlocks by beating $name';
  }

  @override
  String get weeklyEntryTitle => 'Weekly summary';

  @override
  String get weeklyEmpty =>
      'You have not done anything in the last seven days yet. Play a game or solve a puzzle: the summary fills in by itself.';

  @override
  String get weeklyProgressHeading => 'Your progress';

  @override
  String weeklyGames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '$count game',
    );
    return '$_temp0';
  }

  @override
  String weeklyGameResults(int wins, int draws, int losses) {
    return '$wins won, $draws drawn, $losses lost';
  }

  @override
  String weeklyPuzzles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puzzles solved',
      one: '$count puzzle solved',
    );
    return '$_temp0';
  }

  @override
  String weeklyLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons completed',
      one: '$count lesson completed',
    );
    return '$_temp0';
  }

  @override
  String weeklyReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games reviewed',
      one: '$count game reviewed',
    );
    return '$_temp0';
  }

  @override
  String weeklyMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes of training',
      one: '$count minute of training',
    );
    return '$_temp0';
  }

  @override
  String weeklyAccuracy(int percent) {
    return 'Average accuracy $percent%';
  }

  @override
  String weeklyAccuracyUp(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points points more than last week',
      one: '$points point more than last week',
    );
    return '$_temp0';
  }

  @override
  String weeklyAccuracyDown(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points points less than last week',
      one: '$points point less than last week',
    );
    return '$_temp0';
  }

  @override
  String get weeklyErrorHeading => 'Most frequent mistake';

  @override
  String weeklyErrorLine(String error, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '$count time',
    );
    return '$error: $_temp0';
  }

  @override
  String get weeklyNoError => 'No mistake came up twice: great work.';

  @override
  String get weeklyErrorHangingPiece => 'pieces left hanging';

  @override
  String get weeklyErrorAllowedFork => 'forks you allowed';

  @override
  String get weeklyErrorMissedFork => 'forks you missed';

  @override
  String get weeklyErrorAllowedPin => 'pins you allowed';

  @override
  String get weeklyErrorMissedDiscovery => 'discovered attacks you missed';

  @override
  String get weeklyErrorExposedKing => 'king left exposed';

  @override
  String get weeklyErrorMissedMate => 'mates you missed';

  @override
  String get weeklyErrorAllowedMate => 'mates you allowed';

  @override
  String get weeklyErrorMaterialLoss => 'material lost';

  @override
  String get weeklyErrorMissedCapture => 'captures you missed';

  @override
  String get weeklyAdviceHeading => 'Your tip';

  @override
  String weeklyAdviceLesson(String title) {
    return 'Revisit the lesson “$title” in the Path.';
  }

  @override
  String weeklyAdvicePuzzles(String title) {
    return 'Train with the “$title” puzzles.';
  }

  @override
  String get weeklyAdviceReview =>
      'Review one of your games: the coach shows you where to improve.';

  @override
  String get weeklyAdviceSolvePuzzles =>
      'Solve a few puzzles: a few minutes a day is enough.';

  @override
  String get weeklyAdviceKeepGoing =>
      'Keep it up: training a little but often works.';

  @override
  String get weeklyOpenLesson => 'Open the lesson';

  @override
  String get weeklyOpenPuzzles => 'Open the puzzles';

  @override
  String get weeklyKidActive => 'You practised this week. Well done!';

  @override
  String get weeklyKidDaysLabel => 'The stars are the days you practised';

  @override
  String weeklyKidError(String error) {
    return 'Pay more attention to: $error.';
  }
}
