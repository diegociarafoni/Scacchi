import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';

import 'backup/backup.dart';
import 'backup/backup_page.dart';
import 'home/home_shell.dart';
import 'l10n/app_localizations.dart';
import 'l10n/content.dart';
import 'settings/app_language.dart';
import 'settings/settings.dart';
import 'theme/no_transitions.dart';
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

class _ScacchiAppState extends State<ScacchiApp> with WidgetsBindingObserver {
  SettingsController? _settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void didChangeAccessibilityFeatures() => _syncReduceMotion();

  void _syncReduceMotion() => _settings?.setReduceMotion(
    WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations,
  );

  Future<void> _start() async {
    final settings = await SettingsController.load().catchError(
      (Object _) => SettingsController.defaults(),
    );
    // I contenuti (lezioni, grandi maestri…) servono prima delle schermate.
    await _loadContent(settings.value.language);
    settings.addListener(_onSettings);
    if (!mounted) return;
    setState(() => _settings = settings);
    _syncReduceMotion();
  }

  AppLanguage? _contentFor;

  void _onSettings() {
    final language = _settings?.value.language;
    if (language == null || language == _contentFor) return;
    unawaited(
      _loadContent(language).then((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  Future<void> _loadContent(AppLanguage language) async {
    _contentFor = language;
    final locale =
        language.locale ??
        resolveAppLocale(
          PlatformDispatcher.instance.locales,
          AppLocalizations.supportedLocales,
        );
    try {
      await Content.ensureLoaded(language: locale.languageCode);
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Content not loaded: $e');
      // Senza contenuti le schermate lanciano un errore: si ripiega sulla
      // lingua di base.
      try {
        await Content.ensureLoaded();
      } on Object catch (e) {
        if (kDebugMode) debugPrint('Base content not loaded: $e');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings?.removeListener(_onSettings);
    _settings?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (settings == null) return _app(null, ThemeMode.system, null, false);
    return ValueListenableBuilder(
      valueListenable: settings,
      builder: (context, s, _) =>
          _app(settings, s.themeMode, s.language.locale, s.reduceMotion),
    );
  }

  Widget _app(
    SettingsController? settings,
    ThemeMode themeMode,
    Locale? locale,
    bool still,
  ) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // Senza scelta si segue il telefono; una lingua non supportata ripiega
      // sull'italiano.
      locale: locale,
      localeListResolutionCallback: resolveAppLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _still(RokkoTheme.light(), still),
      darkTheme: _still(RokkoTheme.dark(), still),
      themeMode: themeMode,
      // Sopra il Navigator, così anche le pagine aperte con push lo vedono.
      builder: (context, child) => settings == null
          ? child!
          : SettingsScope(controller: settings, child: child!),
      home: settings == null ? const Scaffold() : HomeShell(settings: settings),
    );
  }
}

/// Con le animazioni ridotte le pagine si aprono senza transizione.
ThemeData _still(ThemeData theme, bool still) =>
    still ? theme.copyWith(pageTransitionsTheme: stillTransitions) : theme;
