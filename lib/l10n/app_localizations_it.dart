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
  String get kidBotPinoDescription => 'Un pulcino allegro che ama attaccare';

  @override
  String get kidBotChiaraDescription =>
      'Gioca con calma e aspetta le tue mosse';

  @override
  String get kidBotRoccoDescription => 'Una volpe furba piena di sorprese';
}
