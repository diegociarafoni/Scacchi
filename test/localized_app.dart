import 'package:flutter/material.dart';
import 'package:scacchi/l10n/app_localizations.dart';

/// `MaterialApp` con le stesse localizzazioni dell'app, in italiano salvo
/// diversa indicazione.
MaterialApp localizedApp({
  required Widget home,
  Locale locale = const Locale('it'),
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  home: home,
);
