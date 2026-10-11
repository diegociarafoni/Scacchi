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
  String get kidAdultGateTitle => 'Chiedi a un adulto';

  @override
  String kidAdultGateQuestion(int a, int b) {
    return 'Per uscire dal profilo bambino: quanto fa $a × $b?';
  }

  @override
  String get kidAdultGateWrong => 'Risposta sbagliata.';

  @override
  String get kidAdultGateConfirm => 'Conferma';

  @override
  String get kidProgressGreat => 'Bravo, continua così!';

  @override
  String get kidProgressGoal => 'Obiettivo di oggi raggiunto!';

  @override
  String get kidProgressLevelUp => 'Sei salito di livello: una stella in più!';

  @override
  String get kidProgressFreeze => 'Hai guadagnato uno scudo per la tua fiamma!';

  @override
  String get kidProgressChallenge => 'Sfida completata!';

  @override
  String get kidProgressAchievement => 'Nuovo traguardo!';

  @override
  String kidProgressReward(String name) {
    return 'Hai sbloccato: $name';
  }

  @override
  String get kidLevelTitle => 'Le tue stelle';

  @override
  String get kidLevelStarsLabel => 'Una stella per ogni livello raggiunto';

  @override
  String get kidLevelProgress =>
      'Gioca ancora per guadagnare un\'altra stella!';

  @override
  String get kidLevelProgressLabel => 'Strada verso la prossima stella';

  @override
  String get kidStreakOn => 'Stai giocando tutti i giorni: la fiamma è accesa!';

  @override
  String get kidStreakOff => 'Gioca oggi per accendere la fiamma!';

  @override
  String get kidGoalToday => 'Obiettivo di oggi';

  @override
  String get kidChallengeProgress => 'Strada verso la sfida';

  @override
  String get kidPuzzleHubTitle => 'Risolvi i puzzle e raccogli stelle!';

  @override
  String get kidPuzzleStarsLabel => 'Le stelle dei puzzle risolti';

  @override
  String get kidPuzzleTraining => 'Puzzle scelti per te';

  @override
  String get kidPuzzleDaily => 'Un puzzle nuovo ogni giorno';

  @override
  String get kidPuzzleReviewDue => 'Ci sono puzzle da ripassare';

  @override
  String get kidPuzzleReviewNone => 'Niente da ripassare oggi';

  @override
  String get kidPuzzleKeepGoing => 'Forza, ce la puoi fare!';

  @override
  String get kidAccuracy5 => 'Perfetto!';

  @override
  String get kidAccuracy4 => 'Molto bene';

  @override
  String get kidAccuracy3 => 'Bene';

  @override
  String get kidAccuracy2 => 'Così così';

  @override
  String get kidAccuracy1 => 'Da migliorare';

  @override
  String get kidReviewAnalysing => 'Sto guardando la partita…';

  @override
  String get kidAnalysisThinking => 'Il computer sta pensando…';

  @override
  String get kidEvalWhite => 'Il Bianco è in vantaggio';

  @override
  String get kidEvalBlack => 'Il Nero è in vantaggio';

  @override
  String get kidEvalEven => 'Partita in equilibrio';
}
