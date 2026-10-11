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
      'The camera is not available. Allow Scacchi to use the camera in the phone settings and try again.';

  @override
  String get qrRetry => 'Try again';

  @override
  String get qrInvalidGame => 'The QR code does not contain a valid game.';

  @override
  String get qrFinishedGame =>
      'The game is already over: receive it from You › Archive › Receive via QR.';

  @override
  String get qrMalformed => 'Invalid QR code: ignored.';
}
