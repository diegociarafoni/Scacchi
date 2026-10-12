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
  String whyPiece(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'pawn': 'the pawn',
      'knight': 'the knight',
      'bishop': 'the bishop',
      'rook': 'the rook',
      'queen': 'the queen',
      'other': 'the king',
    });
    return '$_temp0';
  }

  @override
  String get whyMate => 'Checkmate!';

  @override
  String get whyCastle => 'Castles: puts the king safe.';

  @override
  String whyPromote(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'queen': 'a queen',
      'rook': 'a rook',
      'bishop': 'a bishop',
      'knight': 'a knight',
      'other': 'a piece',
    });
    return 'Promotes the pawn to $_temp0.';
  }

  @override
  String whyCapture(String victim, String attacker) {
    return 'Captures $victim with $attacker.';
  }

  @override
  String get whyCheck => 'Gives check to your king.';

  @override
  String whySafe(String piece) {
    return 'Moves $piece to safety; it was under attack.';
  }

  @override
  String whyThreatCapture(String victim, String square) {
    return 'Threatens to capture $victim on $square.';
  }

  @override
  String whyThreatCaptureKid(String victim) {
    return 'Threatens to capture $victim.';
  }

  @override
  String get whyThreatCheck => 'Prepares a check on your king.';

  @override
  String get whyThreatPromote => 'Prepares to promote a pawn.';

  @override
  String whyDevelop(String piece) {
    return 'Develops $piece: it joins the game.';
  }

  @override
  String get whyCenter => 'Takes space in the centre.';

  @override
  String whyImprove(String piece) {
    return 'Moves $piece to a more useful square.';
  }

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
  String get handicapTitle => 'Handicap';

  @override
  String get handicapGameTitle => 'Handicap game';

  @override
  String get handicapHint =>
      'Whoever gives the advantage plays without a piece or with less time. The game does not count for the local rating.';

  @override
  String get handicapPieceTitle => 'Piece removed';

  @override
  String get handicapNone => 'None';

  @override
  String get handicapPieceFPawn => 'F pawn';

  @override
  String get handicapPieceKnight => 'Knight';

  @override
  String get handicapPieceRook => 'Rook';

  @override
  String get handicapPieceQueen => 'Queen';

  @override
  String get handicapTimeTitle => 'Time of the player giving odds';

  @override
  String get handicapTimeEqual => 'Equal';

  @override
  String get handicapTimeHint =>
      'Applies only with a clock and when it is lower than the chosen time control.';

  @override
  String get handicapGiverTitle => 'Who gives the advantage';

  @override
  String get handicapGiverYou => 'You';

  @override
  String get handicapGiverOpponent => 'The opponent';

  @override
  String get handicapGiverWhite => 'White';

  @override
  String get handicapGiverBlack => 'Black';

  @override
  String handicapTimeMinutes(int n) {
    return '$n min';
  }

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
  String get personalTitle => 'Your openings';

  @override
  String get personalHubSubtitle => 'The moves you have played, with results';

  @override
  String get personalLoadFailed =>
      'The game archive could not be read: try again later.';

  @override
  String get personalEmpty =>
      'Play a few games against the computer to build your opening tree.';

  @override
  String get personalNoGamesFiltered => 'No games match these filters.';

  @override
  String get personalNoGamesHere => 'You have never played from this position.';

  @override
  String get personalSideAll => 'Both';

  @override
  String get personalSideWhite => 'White';

  @override
  String get personalSideBlack => 'Black';

  @override
  String get personalOpponent => 'Opponent';

  @override
  String get personalAllOpponents => 'All opponents';

  @override
  String personalGames(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '$count game',
    );
    return '$_temp0';
  }

  @override
  String personalGamesTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games counted',
      one: '$count game counted',
    );
    return '$_temp0';
  }

  @override
  String personalScore(int wins, int draws, int losses) {
    return '${wins}W · ${draws}D · ${losses}L';
  }

  @override
  String personalScoreSemantics(int wins, int draws, int losses) {
    return '$wins won, $draws drawn, $losses lost';
  }

  @override
  String get personalStartPosition => 'Starting position';

  @override
  String get personalNoName => 'Unnamed opening';

  @override
  String get personalBack => 'Back';

  @override
  String get personalStart => 'Start';

  @override
  String get personalFlip => 'Flip the board';

  @override
  String get personalOpenInBook => 'Open in the openings explorer';

  @override
  String get personalFromHere => 'Your games from this position';

  @override
  String get openingsTitle => 'Openings';

  @override
  String get openingsExplorer => 'Explore openings';

  @override
  String get openingsExplorerSubtitle =>
      'Names and continuations of over 3,000 openings';

  @override
  String get openingsRepertoireWhite => 'Repertoire as White';

  @override
  String get openingsRepertoireBlack => 'Repertoire as Black';

  @override
  String get openingsRepertoireUnavailable => 'Repertoire unavailable';

  @override
  String get openingsLoading => 'Loading...';

  @override
  String openingsRepertoireSummary(int lines, int due) {
    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: '$lines lines',
      one: '1 line',
    );
    String _temp1 = intl.Intl.pluralLogic(
      due,
      locale: localeName,
      other: '$due moves to review',
      one: '1 move to review',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get openingsWhite => 'White';

  @override
  String get openingsBlack => 'Black';

  @override
  String get openingsCancel => 'Cancel';

  @override
  String get openingsBack => 'Back';

  @override
  String get openingsReset => 'To start';

  @override
  String get openingsFlipBoard => 'Flip the board';

  @override
  String get openingsLoadFailed => 'Could not load the openings.';

  @override
  String get openingsStartPosition => 'Starting position';

  @override
  String get openingsUnnamed => 'Unnamed opening';

  @override
  String get openingsOutOfBook => 'Out of the opening book';

  @override
  String get openingsFreeTitle => 'Free opening';

  @override
  String get openingsAddToRepertoire => 'Add to repertoire';

  @override
  String get openingsAdd => 'Add';

  @override
  String get openingsLineName => 'Name';

  @override
  String get openingsDefaultLineName => 'Line';

  @override
  String openingsPgnLineName(int n) {
    return 'PGN $n';
  }

  @override
  String get openingsLineAddedWhite => 'Line added to White\'s repertoire.';

  @override
  String get openingsLineAddedBlack => 'Line added to Black\'s repertoire.';

  @override
  String get openingsPlayOpening => 'Play this opening';

  @override
  String get openingsPlayLine => 'Play the line';

  @override
  String get openingsPlayDialogTitle => 'Play against the computer';

  @override
  String get openingsPlayLevel => 'Level';

  @override
  String get openingsPlay => 'Play';

  @override
  String get openingsLeftByComputer => 'The computer left the repertoire line.';

  @override
  String get openingsLeftByUser => 'You left the repertoire line.';

  @override
  String openingsGameSemantics(String name, String eco) {
    return 'Opening: $name ($eco)';
  }

  @override
  String get openingsImportPgn => 'Import PGN';

  @override
  String get openingsImportHelper => 'Each variation becomes a line.';

  @override
  String get openingsImport => 'Import';

  @override
  String get openingsNoValidLines => 'No valid lines in the PGN.';

  @override
  String openingsLinesAdded(int added) {
    return 'Lines added: $added';
  }

  @override
  String openingsLinesAddedDiscarded(int added, int discarded, String reason) {
    return 'Lines added: $added. Discarded: $discarded ($reason)';
  }

  @override
  String get openingsNoLines =>
      'No lines. Add them from Explore openings with the \"Add to repertoire\" button or import a PGN.';

  @override
  String get openingsDeleteLine => 'Delete the line';

  @override
  String get openingsNothingToReview => 'No moves to review';

  @override
  String openingsReviewMoves(int due) {
    String _temp0 = intl.Intl.pluralLogic(
      due,
      locale: localeName,
      other: '$due moves',
      one: '1 move',
    );
    return 'Review $_temp0';
  }

  @override
  String get openingsDrillTitle => 'Repertoire review';

  @override
  String openingsDrillDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '1 move',
    );
    return 'Review complete: $_temp0.';
  }

  @override
  String get openingsDrillNewMove =>
      'New move: play the one shown by the arrow.';

  @override
  String openingsDrillPrompt(String name) {
    return 'Line \"$name\": what is your move?';
  }

  @override
  String get openingsDrillWrong =>
      'That is not the repertoire move: here is the right one.';

  @override
  String get openingsErrorEmpty => 'The line is empty.';

  @override
  String get openingsErrorIllegal => 'The line contains an illegal move.';

  @override
  String get openingsErrorNoOwnMoves => 'The line has no moves for your color.';

  @override
  String openingsErrorConflict(String san) {
    return 'In this position the repertoire already has $san.';
  }

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
  String get challengeTitle => 'Challenge a friend';

  @override
  String get challengeSubtitle => 'The same puzzles on two phones, no network';

  @override
  String get challengeIntro =>
      'Pick the run and show the QR code to your friend: you both play the same puzzles. At the end you swap scores with a second QR code.';

  @override
  String get challengePrepare => 'Set up the challenge';

  @override
  String challengeReady(String mode) {
    return 'Challenge ready: $mode';
  }

  @override
  String get challengeShowInvite => 'Show the QR code to your friend';

  @override
  String get challengePlay => 'Play your run';

  @override
  String get challengeReceive => 'Receive a challenge';

  @override
  String challengeInviteTitle(String mode) {
    return 'Challenge: $mode';
  }

  @override
  String get challengeInviteHint =>
      'Your friend opens Puzzles › Challenge a friend › Receive a challenge and scans the code.';

  @override
  String get challengeReceiveHint =>
      'Scan the challenge QR code your friend is showing.';

  @override
  String get challengeNotInvite =>
      'This QR code is not a challenge: ask your friend to show the challenge QR code.';

  @override
  String get challengeLibraryMismatch =>
      'The two phones have different puzzles: update Rokko on both.';

  @override
  String get challengeCompareTitle => 'Challenge with your friend';

  @override
  String get challengeShowResult => 'Show my result';

  @override
  String challengeResultTitle(int score) {
    return 'My result: $score';
  }

  @override
  String get challengeResultHint =>
      'Your friend scans this code to see your score.';

  @override
  String get challengeReadResult => 'Read your friend\'s result';

  @override
  String get challengeReadResultHint =>
      'Scan the result QR code your friend is showing.';

  @override
  String get challengeNotResult =>
      'This QR code is not a result: ask your friend to show the result QR code.';

  @override
  String get challengeOtherChallenge =>
      'That result belongs to a different challenge.';

  @override
  String challengeWon(int mine, int theirs) {
    return 'You won: $mine to $theirs';
  }

  @override
  String challengeLost(int mine, int theirs) {
    return 'Your friend won: $theirs to $mine';
  }

  @override
  String challengeDraw(int mine, int theirs) {
    return 'A draw: $mine to $theirs';
  }

  @override
  String get settingsExplainWhy => 'Explain why';

  @override
  String get settingsExplainWhyDescription =>
      'After each computer move, one line on what it threatens or prepares';

  @override
  String get settingsZenMode => 'Zen mode';

  @override
  String get settingsZenModeDescription =>
      'During a game only the board and the moves remain: no Elo, material, status, coach warnings or comments';

  @override
  String get shareImageTitle => 'Export as image';

  @override
  String get shareImageAction => 'Share';

  @override
  String get shareImageFlip => 'Flip the board';

  @override
  String get shareImageCoordinates => 'Coordinates';

  @override
  String get shareImageLastMove => 'Last move';

  @override
  String get shareImageCaption => 'Caption (optional)';

  @override
  String get shareImagePreview => 'Board preview';

  @override
  String get shareImageFailed => 'Sharing failed';

  @override
  String get shareImageSubject => 'Chess position';

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
  String get storyTitle => 'Story';

  @override
  String get storyEntrySubtitle =>
      'A journey in chapters: lessons, puzzles and challenges';

  @override
  String storyChapterNumber(int n) {
    return 'Chapter $n';
  }

  @override
  String storyProgress(int done, int total) {
    return '$done chapters out of $total';
  }

  @override
  String get storyChapterLocked => 'Opens when you finish the previous chapter';

  @override
  String get storyChapterDone => 'Chapter finished';

  @override
  String get storyContinue => 'Continue';

  @override
  String get storyFinished =>
      'The story is over. Lessons, puzzles and games stay available in the rest of the app.';

  @override
  String storyStepLessons(int value, int total) {
    return 'Lessons: $value of $total';
  }

  @override
  String storyStepPuzzles(int value, int total) {
    return 'Chapter puzzles: $value of $total';
  }

  @override
  String get storyStepGuardian => 'The chapter guardian';

  @override
  String storyStepBoss(String name) {
    return 'Challenge $name';
  }

  @override
  String get storyStepDone => 'done';

  @override
  String get storyStepTodo => 'to do';

  @override
  String get storyStepLocked => 'locked';

  @override
  String get storyStepLockedHint => 'Finish the previous step first.';

  @override
  String get storyEngineMissing =>
      'Challenges are played where the computer opponent runs: Android and iOS, or Windows and Linux with Stockfish installed.';

  @override
  String storyBossWon(String name) {
    return 'You beat $name!';
  }

  @override
  String storyBossLost(String name) {
    return '$name holds out for now: try again whenever you like.';
  }

  @override
  String get storyPuzzlesNone => 'The puzzles could not be loaded: try again.';

  @override
  String get storyVillageTitle => 'The village of the pieces';

  @override
  String get storyVillageIntro =>
      'You reach the village at the foot of the Rokko fortress. The villagers no longer remember how their pieces move: help them with the lessons, then show you can spot a piece left hanging.';

  @override
  String storyVillageBoss(String name) {
    return '$name, the village keeper, challenges you to see if you really learned.';
  }

  @override
  String get storyVillageOutro =>
      'The village throws a party in your honour. The road to the city gates is open.';

  @override
  String get storyGatesTitle => 'The city gates';

  @override
  String get storyGatesIntro =>
      'The guards stop you at the gates: to enter you must know the rules, from check to castling. A promotion spotted in time even opens the highest gate.';

  @override
  String storyGatesBoss(String name) {
    return '$name, captain of the guards, wants a test before letting you through.';
  }

  @override
  String get storyGatesOutro =>
      'The gates swing open. Ahead of you rises the king\'s tower.';

  @override
  String get storyTowerTitle => 'The king\'s tower';

  @override
  String get storyTowerIntro =>
      'The king lives at the top of the tower, and he knows how to defend himself. Learn the checkmates that corner him, even when his own pieces form a wall.';

  @override
  String storyTowerBoss(String name) {
    return '$name, the knight who loves gambits, is waiting at the top of the stairs.';
  }

  @override
  String get storyTowerOutro =>
      'The king of the tower is checkmated. The forest and its traps remain.';

  @override
  String get storyForestTitle => 'The forest of traps';

  @override
  String get storyForestIntro =>
      'In the forest every piece hides a trap: forks, pins, skewers. Learn to see them before anyone else does.';

  @override
  String storyForestBoss(String name) {
    return '$name, the forest guide, knows every path and every snare.';
  }

  @override
  String get storyForestOutro =>
      'You crossed the forest without falling into a single trap. The castle awaits.';

  @override
  String get storyCastleTitle => 'The castle of endgames';

  @override
  String get storyCastleIntro =>
      'In the castle only a few pieces are left on the board and every move counts. Here we find out who can close a game.';

  @override
  String storyCastleBoss(String name) {
    return '$name, the castellan, guards the entrance to the crown room.';
  }

  @override
  String get storyCastleOutro => 'The great door opens: the crown is near.';

  @override
  String get storyCrownTitle => 'The crown';

  @override
  String get storyCrownIntro =>
      'Last stop: the crown room. A good start is half the victory: the centre, development, castling.';

  @override
  String storyCrownBoss(String name) {
    return '$name, the keeper of the crown, plays openings like no one else.';
  }

  @override
  String get storyCrownOutro =>
      'The crown is yours. The kingdom is at peace and every new game is a new story.';

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

  @override
  String get tablebaseTitle => 'Perfect endgame';

  @override
  String get tablebaseCalculating =>
      'Working out the perfect endgame… this only happens the first time';

  @override
  String tablebaseWhiteMates(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: 'White wins: mate in $moves moves',
      one: 'White wins: mate in $moves move',
    );
    return '$_temp0';
  }

  @override
  String tablebaseBlackMates(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: 'Black wins: mate in $moves moves',
      one: 'Black wins: mate in $moves move',
    );
    return '$_temp0';
  }

  @override
  String get tablebaseWhiteWins => 'White wins';

  @override
  String get tablebaseBlackWins => 'Black wins';

  @override
  String get tablebaseDraw => 'Draw with perfect play';

  @override
  String tablebaseBestMove(String move) {
    return 'Perfect move: $move';
  }

  @override
  String get tablebaseBestMoveHint => 'Play the perfect move';

  @override
  String get tablebaseShowMove => 'Show the perfect move';
}
