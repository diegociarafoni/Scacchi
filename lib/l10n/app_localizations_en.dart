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
}
