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
}
