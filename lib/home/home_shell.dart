import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../game/game_page.dart';
import '../openings/opening_assets.dart';
import '../openings/openings_hub_page.dart';
import '../openings/repertoire.dart';
import '../progress/activity.dart';
import '../progress/progress_controller.dart';
import '../progress/progress_tracker.dart';
import '../puzzles/puzzle_assets.dart';
import '../puzzles/puzzle_hub_page.dart';
import '../puzzles/puzzle_trainer.dart';
import '../reminders/local_notification_scheduler.dart';
import '../reminders/reminder.dart';
import '../reminders/reminder_controller.dart';
import '../settings/settings.dart';
import '../storage/key_value_store.dart';
import 'you_page.dart';

/// Navigazione principale con la barra in basso, nella zona del pollice.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.settings,
    this.puzzleTrainer,
    this.progress,
    this.repertoire,
    this.archive,
    this.reminderScheduler,
  });

  final SettingsController settings;

  /// Sostituibile nei test; di default carica i puzzle inclusi nell'app.
  final Future<PuzzleTrainer> Function()? puzzleTrainer;

  /// Sostituibile nei test; di default apre i progressi salvati.
  final Future<ProgressController> Function()? progress;

  /// Sostituibile nei test; di default il repertorio salvato.
  final Future<RepertoireTrainer> Function()? repertoire;

  /// Sostituibile nei test; di default l'archivio delle partite salvato.
  final Future<GameArchive> Function()? archive;

  /// Sostituibile nei test; di default le notifiche locali dove esistono
  /// (Android e iOS), altrimenti nessun promemoria.
  final ReminderScheduler? Function()? reminderScheduler;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  Future<PuzzleTrainer>? _trainer;
  Future<ProgressController>? _progress;
  Future<RepertoireTrainer>? _repertoire;
  ReminderController? _reminders;

  /// La scheda Tu si costruisce alla prima apertura, poi resta in memoria.
  var _youVisited = false;

  Future<RepertoireTrainer> _loadRepertoire() =>
      (widget.repertoire ??
              () async => RepertoireTrainer.load(await JsonFileStore.open()))()
          .catchError((Object e) {
            _repertoire = null;
            throw e;
          });

  @override
  void initState() {
    super.initState();
    // Caricamento anticipato in background, per il nome dell'apertura in partita.
    openingBook().ignore();
    final scheduler =
        (widget.reminderScheduler ??
        () => LocalNotificationScheduler.supported
            ? LocalNotificationScheduler()
            : null)();
    if (scheduler != null) {
      // Il promemoria si allinea ai progressi fin dall'avvio.
      _progressController().then((p) {
        if (!mounted) return;
        setState(() => _reminders = ReminderController(p, scheduler));
      }, onError: (Object e) => debugPrint('Promemoria non disponibile: $e'));
    }
  }

  @override
  void dispose() {
    _reminders?.dispose();
    super.dispose();
  }

  Future<ProgressController> _progressController() => _progress ??=
      (widget.progress ?? ProgressController.open)().catchError((Object e) {
        // Si riprova alla prossima richiesta invece di restare bloccati.
        _progress = null;
        throw e;
      });

  Future<ProgressUpdate?> _record(Activity activity) async {
    try {
      return await (await _progressController()).record(activity);
    } on Object catch (e) {
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
    if (_tab == 2) _repertoire ??= _loadRepertoire();
    if (_tab == 3) _youVisited = true;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          GamePage(settings: widget.settings),
          if (_trainer != null)
            PuzzleHubPage(trainer: _trainer!, onActivity: _record)
          else
            const SizedBox.shrink(),
          if (_repertoire != null)
            OpeningsHubPage(repertoire: _repertoire!)
          else
            const SizedBox.shrink(),
          if (_tab == 3 || _youVisited)
            YouPage(
              progress: _progressController(),
              archive: widget.archive ?? GameArchive.open,
              recordActivity: _record,
              reminders: _reminders,
            )
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
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Aperture',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Tu'),
        ],
      ),
    );
  }
}
