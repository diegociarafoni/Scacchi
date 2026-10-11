import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../archive/saved_game.dart';
import '../game/game_page.dart';
import '../openings/opening_assets.dart';
import '../openings/openings_hub_page.dart';
import '../openings/repertoire.dart';
import '../path/path_controller.dart';
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
  ReminderScheduler? _scheduler;
  Future<PathController>? _path;

  /// La scheda Tu si costruisce alla prima apertura, poi resta in memoria.
  var _youVisited = false;

  late bool _kidMode = widget.settings.value.kidMode;

  Future<RepertoireTrainer> _loadRepertoire() =>
      (widget.repertoire ??
              () async => RepertoireTrainer.load(await JsonFileStore.open()))()
          .catchError((Object e, StackTrace st) {
            _repertoire = null;
            Error.throwWithStackTrace(e, st);
          });

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettings);
    // Caricamento anticipato in background, per il nome dell'apertura in partita.
    openingBook().ignore();
    _scheduler =
        (widget.reminderScheduler ??
        () => LocalNotificationScheduler.supported
            ? LocalNotificationScheduler()
            : null)();
    if (_scheduler != null) {
      // Il promemoria si allinea ai progressi fin dall'avvio.
      _progressController().ignore();
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettings);
    _reminders?.dispose();
    super.dispose();
  }

  Future<ProgressController> _progressController() =>
      _progress ??= (widget.progress ?? ProgressController.open)().then(
        (p) {
          final scheduler = _scheduler;
          if (scheduler != null && _reminders == null && mounted) {
            setState(() => _reminders = ReminderController(p, scheduler));
          }
          return p;
        },
        onError: (Object e, StackTrace st) {
          // Si riprova alla prossima richiesta invece di restare bloccati.
          _progress = null;
          debugPrint('Progressi non disponibili: $e');
          Error.throwWithStackTrace(e, st);
        },
      );

  /// Un solo percorso in memoria, per non sovrascrivere le stelle tra due
  /// schermate aperte insieme.
  Future<PathController> _pathController() =>
      _path ??= PathController.open(recordActivity: _record)
          .catchError((Object e, StackTrace st) {
            _path = null;
            Error.throwWithStackTrace(e, st);
          });

  Future<void> _saveGame(SavedGame game) async => (await _archive()).save(game);

  Future<GameArchive> _archive() => (widget.archive ?? GameArchive.open)();

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
    StackTrace st,
  ) {
    // Un errore di caricamento si riprova alla prossima apertura della scheda.
    _trainer = null;
    Error.throwWithStackTrace(e, st);
  });

  /// Ricostruisce solo quando cambia il profilo bambino, non a ogni
  /// impostazione.
  void _onSettings() {
    final kidMode = widget.settings.value.kidMode;
    if (kidMode == _kidMode) return;
    setState(() {
      _kidMode = kidMode;
      // Le aperture spariscono: se erano aperte si torna a Gioca (RP-06).
      if (kidMode && _tab == 2) _tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [0, 1, if (!_kidMode) 2, 3];
    if (_tab == 1) {
      _trainer ??= _loadTrainer();
    }
    if (_tab == 2) _repertoire ??= _loadRepertoire();
    if (_tab == 3) _youVisited = true;
    const destinations = [
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
    ];
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          GamePage(
            settings: widget.settings,
            onActivity: _record,
            onSave: _saveGame,
            progress: _progressController,
          ),
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
              progress: _progressController,
              path: _pathController,
              archive: _archive,
              reminders: () => _reminders,
              simple: _kidMode,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.indexOf(_tab),
        onDestinationSelected: (i) => setState(() => _tab = tabs[i]),
        destinations: [for (final t in tabs) destinations[t]],
      ),
    );
  }
}
