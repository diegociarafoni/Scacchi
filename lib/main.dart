import 'package:flutter/material.dart';

import 'home/home_shell.dart';
import 'l10n/app_localizations.dart';
import 'settings/settings.dart';

void main() {
  runApp(const ScacchiApp());
}

class ScacchiApp extends StatefulWidget {
  const ScacchiApp({super.key});

  @override
  State<ScacchiApp> createState() => _ScacchiAppState();
}

class _ScacchiAppState extends State<ScacchiApp> {
  SettingsController? _settings;

  @override
  void initState() {
    super.initState();
    SettingsController.load()
        .catchError((Object _) => SettingsController.defaults())
        .then((s) {
          if (mounted) setState(() => _settings = s);
        });
  }

  @override
  void dispose() {
    _settings?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF769656);
    final settings = _settings;
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // Italiano predefinito finché non sono tradotti tutti i testi.
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      // Sopra il Navigator, così anche le pagine aperte con push lo vedono.
      builder: (context, child) => settings == null
          ? child!
          : SettingsScope(controller: settings, child: child!),
      home: settings == null ? const Scaffold() : HomeShell(settings: settings),
    );
  }
}
