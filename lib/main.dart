import 'package:flutter/material.dart';

import 'home/home_shell.dart';
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
      title: 'Scacchi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: settings == null ? const Scaffold() : HomeShell(settings: settings),
    );
  }
}
