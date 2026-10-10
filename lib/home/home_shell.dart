import 'package:flutter/material.dart';

import '../game/game_page.dart';
import '../progress/activity.dart';
import '../progress/progress_controller.dart';
import '../progress/progress_tracker.dart';
import '../puzzles/puzzle_assets.dart';
import '../puzzles/puzzle_hub_page.dart';
import '../puzzles/puzzle_trainer.dart';

/// Navigazione principale con la barra in basso, nella zona del pollice.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.puzzleTrainer, this.progress});

  /// Sostituibile nei test; di default carica i puzzle inclusi nell'app.
  final Future<PuzzleTrainer> Function()? puzzleTrainer;

  /// Sostituibile nei test; di default apre i progressi salvati.
  final Future<ProgressController> Function()? progress;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  Future<PuzzleTrainer>? _trainer;
  Future<ProgressController>? _progress;

  Future<ProgressUpdate?> _record(Activity activity) async {
    try {
      _progress ??= (widget.progress ?? ProgressController.open)();
      return await (await _progress!).record(activity);
    } on Object catch (e) {
      // Si riprova alla prossima attività invece di restare bloccati.
      _progress = null;
      debugPrint('Progressi non disponibili: $e');
      return null;
    }
  }

  Future<PuzzleTrainer>
  _loadTrainer() => (widget.puzzleTrainer ?? loadPuzzleTrainer)().catchError((
    Object e,
  ) {
    // Un errore di caricamento si riprova alla prossima apertura della scheda.
    _trainer = null;
    throw e;
  });

  @override
  Widget build(BuildContext context) {
    if (_tab == 1) {
      _trainer ??= _loadTrainer();
    }
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const GamePage(),
          if (_trainer != null)
            PuzzleHubPage(trainer: _trainer!, onActivity: _record)
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
