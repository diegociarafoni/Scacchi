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
}
