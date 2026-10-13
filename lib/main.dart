import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';

import 'backup/backup.dart';
import 'backup/backup_page.dart';
import 'home/home_shell.dart';
import 'l10n/app_localizations.dart';
import 'l10n/content.dart';
import 'settings/settings.dart';
import 'theme/rokko_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Backup.applyPending(
      await getApplicationSupportDirectory(),
      applyPreferencesToSystem,
    );
  } on Object catch (e) {
    debugPrint('Backup restore failed: $e');
  }
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
    unawaited(_start());
  }

  Future<void> _start() async {
    // I contenuti (lezioni, grandi maestri…) servono prima delle schermate.
    try {
      await Content.ensureLoaded(
        language: contentLanguage(
          PlatformDispatcher.instance.locale,
          AppLocalizations.supportedLocales,
        ),
      );
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Content not loaded: $e');
    }
    final settings = await SettingsController.load().catchError(
      (Object _) => SettingsController.defaults(),
    );
    if (mounted) setState(() => _settings = settings);
  }

  @override
  void dispose() {
    _settings?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (settings == null) return _app(null, ThemeMode.system);
    return ValueListenableBuilder(
      valueListenable: settings,
      builder: (context, s, _) => _app(settings, s.themeMode),
    );
  }

  Widget _app(SettingsController? settings, ThemeMode themeMode) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // Italiano predefinito finché non sono tradotti tutti i testi.
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: RokkoTheme.light(),
      darkTheme: RokkoTheme.dark(),
      themeMode: themeMode,
      // Sopra il Navigator, così anche le pagine aperte con push lo vedono.
      builder: (context, child) => settings == null
          ? child!
          : SettingsScope(controller: settings, child: child!),
      home: settings == null ? const Scaffold() : HomeShell(settings: settings),
    );
  }
}
