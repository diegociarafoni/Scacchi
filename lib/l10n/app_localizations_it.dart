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
  String get kidBotPinoDescription => 'Un pulcino allegro che ama attaccare';

  @override
  String get kidBotChiaraDescription =>
      'Gioca con calma e aspetta le tue mosse';

  @override
  String get kidBotRoccoDescription => 'Una volpe furba piena di sorprese';

  @override
  String get kidBotUnavailable =>
      'Su questo dispositivo i bot non sono disponibili.';

  @override
  String get qrSendTitle => 'Passa con QR';

  @override
  String get qrSendHint =>
      'Sull\'altro telefono apri Tu › Archivio › Ricevi con QR e inquadra il codice.';

  @override
  String qrPart(int current, int total) {
    return 'Parte $current di $total';
  }

  @override
  String get qrPause => 'Pausa';

  @override
  String get qrResume => 'Riprendi';

  @override
  String get qrNext => 'Parte successiva';

  @override
  String get qrPrevious => 'Parte precedente';

  @override
  String get qrCodeLabel => 'Codice QR della partita';

  @override
  String get qrReceiveTitle => 'Ricevi con QR';

  @override
  String get qrReceiveHint =>
      'Inquadra il codice QR mostrato dall\'altro telefono.';

  @override
  String qrReceived(int received, int total) {
    return '$received di $total parti lette';
  }

  @override
  String get qrForeign => 'Questo QR non contiene una partita.';

  @override
  String get qrCorrupted => 'Il QR è danneggiato: ricomincia la lettura.';

  @override
  String get qrTooLarge => 'La partita è troppo grande per essere ricevuta.';

  @override
  String get qrRestarted => 'Nuova partita inquadrata: lettura ricominciata.';

  @override
  String get qrCameraError =>
      'Non riesco a usare la fotocamera. Consenti l\'accesso alla fotocamera per Scacchi nelle impostazioni del telefono e riprova.';

  @override
  String get qrRetry => 'Riprova';

  @override
  String get qrInvalidGame => 'Il QR non contiene una partita valida.';

  @override
  String get qrFinishedGame =>
      'La partita è già conclusa: ricevila da Tu › Archivio › Ricevi con QR.';

  @override
  String get qrMalformed => 'QR non valido: ignorato.';
}
