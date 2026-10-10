import 'package:flutter/material.dart';

import 'game/game_page.dart';

void main() {
  runApp(const ScacchiApp());
}

class ScacchiApp extends StatelessWidget {
  const ScacchiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF769656);
    return MaterialApp(
      title: 'Scacchi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const GamePage(),
    );
  }
}
