import 'package:flutter/material.dart';

import '../game/game_page.dart';
import '../puzzles/puzzle_assets.dart';
import '../puzzles/puzzle_hub_page.dart';
import '../puzzles/puzzle_trainer.dart';

/// Navigazione principale con la barra in basso, nella zona del pollice.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.puzzleTrainer});

  /// Sostituibile nei test; di default carica i puzzle inclusi nell'app.
  final Future<PuzzleTrainer> Function()? puzzleTrainer;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  Future<PuzzleTrainer>? _trainer;

  @override
  Widget build(BuildContext context) {
    if (_tab == 1) {
      _trainer ??= (widget.puzzleTrainer ?? loadPuzzleTrainer)();
    }
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const GamePage(),
          if (_trainer != null)
            PuzzleHubPage(trainer: _trainer!)
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            label: 'Gioca',
          ),
          NavigationDestination(
            icon: Icon(Icons.extension_outlined),
            label: 'Puzzle',
          ),
        ],
      ),
    );
  }
}
