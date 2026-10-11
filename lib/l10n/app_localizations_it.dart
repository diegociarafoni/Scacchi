// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Scacchi';

  @override
  String get kidProfileSection => 'Profilo';

  @override
  String get kidProfile => 'Profilo bambino';

  @override
  String get kidProfileDescription =>
      'Interfaccia e testi più semplici, bot amichevoli, niente numeri';

  @override
  String get kidGameYourTurn => 'Tocca a te!';

  @override
  String kidGameTurnSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Tocca al Bianco!',
      'other': 'Tocca al Nero!',
    });
    return '$_temp0';
  }

  @override
  String kidGameTurnName(String name) {
    return '$name, tocca a te!';
  }

  @override
  String kidGameOpponentTurn(String name) {
    return '$name sta per muovere';
  }

  @override
  String kidGameThinking(String name) {
    return '$name ci sta pensando…';
  }

  @override
  String kidGameDrawThinking(String name) {
    return '$name ci pensa un attimo…';
  }

  @override
  String get kidGameCheckYou => 'Scacco! Il tuo re è in pericolo';

  @override
  String get kidGameCheckOpponent => 'Scacco! Il re avversario è in pericolo';

  @override
  String kidGameCheckSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Scacco! Il re bianco è in pericolo',
      'other': 'Scacco! Il re nero è in pericolo',
    });
    return '$_temp0';
  }

  @override
  String kidGameCheckName(String name) {
    return 'Scacco! $name, il tuo re è in pericolo';
  }

  @override
  String get kidGameCheckmate => 'Scacco matto!';

  @override
  String get kidGameTimeUp => 'Tempo finito!';

  @override
  String get kidGameKingOfTheHill => 'Il re è arrivato al centro!';

  @override
  String get kidGameThirdCheck => 'Terzo scacco!';

  @override
  String get kidGameOver => 'Partita finita!';

  @override
  String get kidGameYouResigned => 'Ti sei arreso.';

  @override
  String kidGameResignedSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Il Bianco si arrende.',
      'other': 'Il Nero si arrende.',
    });
    return '$_temp0';
  }

  @override
  String kidGameResignedName(String name) {
    return '$name si arrende.';
  }

  @override
  String get kidGameYouWon => 'Hai vinto!';

  @override
  String kidGameOpponentWon(String name) {
    return '$name ha vinto. Riprova!';
  }

  @override
  String kidGameWinnerSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Ha vinto il Bianco!',
      'other': 'Ha vinto il Nero!',
    });
    return '$_temp0';
  }

  @override
  String kidGameWinnerName(String name) {
    return 'Ha vinto $name!';
  }

  @override
  String get kidGameStalemate =>
      'Stallo: il re non può muoversi ma non è sotto scacco. Pareggio!';

  @override
  String get kidGameInsufficientMaterial =>
      'Sono rimasti troppo pochi pezzi per dare scacco matto. Pareggio!';

  @override
  String get kidGameRepetition =>
      'La stessa posizione è tornata tre volte. Pareggio!';

  @override
  String get kidGameFiftyMoves =>
      'Tante mosse senza catture né mosse di pedone. Pareggio!';

  @override
  String get kidGameAgreedDraw => 'Pareggio deciso insieme!';

  @override
  String get kidGameTimeUpDraw =>
      'Tempo finito, ma con questi pezzi nessuno può vincere. Pareggio!';

  @override
  String get kidGameComputer => 'Il computer';

  @override
  String get kidGameNew => 'Nuova partita';

  @override
  String get kidGameDraw => 'Pareggio?';

  @override
  String get kidGameResign => 'Mi arrendo';

  @override
  String get kidGameResignTitle => 'Vuoi arrenderti?';

  @override
  String kidGameResignTitleSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Bianco, vuoi arrenderti?',
      'other': 'Nero, vuoi arrenderti?',
    });
    return '$_temp0';
  }

  @override
  String kidGameResignTitleName(String name) {
    return '$name, vuoi arrenderti?';
  }

  @override
  String get kidGameResignBody => 'Se ti arrendi, la partita finisce.';

  @override
  String get kidGameResignNo => 'No, continuo';

  @override
  String get kidGameResignYes => 'Sì, mi arrendo';

  @override
  String kidGameDrawOfferSide(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'white': 'Bianco, vuoi fare pareggio?',
      'other': 'Nero, vuoi fare pareggio?',
    });
    return '$_temp0';
  }

  @override
  String kidGameDrawOfferName(String name) {
    return '$name, vuoi fare pareggio?';
  }

  @override
  String get kidGameDrawNo => 'No, giochiamo';

  @override
  String get kidGameDrawYes => 'Sì, pareggio';

  @override
  String kidGameDrawAccepted(String name) {
    return '$name accetta il pareggio!';
  }

  @override
  String kidGameDrawRefused(String name) {
    return '$name vuole continuare a giocare.';
  }

  @override
  String get kidGameTimeTitle => 'Quanto tempo?';

  @override
  String get kidGameSlowClock => 'Con l\'orologio, con calma';
}
