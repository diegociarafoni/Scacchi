import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../archive/pgn.dart';
import '../archive/saved_game.dart';
import '../endgames/endgame_controller.dart';
import '../endgames/endgames_page.dart';
import '../engine/bots.dart';
import '../engine/computer_player.dart';
import '../engine/levels.dart';
import '../engine/uci_transport.dart';
import '../game/challenge.dart';
import '../game/clock.dart';
import '../game/game_page.dart';
import '../game/handicap.dart';
import '../openings/opening_assets.dart';
import '../openings/opening_game.dart';
import '../openings/openings_hub_page.dart';
import '../openings/repertoire.dart';
import '../path/curriculum.dart';
import '../path/path_controller.dart';
import '../progress/activity.dart';
import '../progress/progress_controller.dart';
import '../progress/progress_tracker.dart';
import '../puzzles/puzzle_assets.dart';
import '../puzzles/puzzle_hub_page.dart';
import '../puzzles/puzzle_page.dart';
import '../puzzles/puzzle_trainer.dart';
import '../reminders/local_notification_scheduler.dart';
import '../reminders/reminder.dart';
import '../reminders/reminder_controller.dart';
import '../review/engine_evaluator.dart';
import '../review/move_classification.dart';
import '../review/personal_puzzles.dart';
import '../review/review_page.dart';
import '../settings/settings.dart';
import '../stats/local_rating.dart';
import '../storage/key_value_store.dart';
import '../story/story.dart';
import '../story/story_controller.dart';
import '../story/story_feed.dart';
import '../story/story_l10n.dart';
import '../story/story_page.dart';
import '../tablebase/shared_tablebase.dart';
import '../tournament/tournament.dart';
import '../tournament/tournament_controller.dart';
import '../tournament/tournament_page.dart';
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
    this.path,
    this.computerAvailable,
    this.createComputer,
    this.tournaments,
    this.endgames,
    this.story,
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

  /// Sostituibile nei test; di default il percorso salvato.
  final Future<PathController> Function()? path;

  /// Sostituibili nei test; di default il motore c'è dove Stockfish è
  /// supportato (Android e iOS).
  final bool? computerAvailable;
  final ComputerPlayer Function()? createComputer;

  /// Sostituibile nei test; di default i tornei salvati.
  final Future<TournamentController> Function()? tournaments;

  /// Sostituibile nei test; di default i progressi salvati dei finali.
  final Future<EndgameController> Function()? endgames;

  /// Sostituibile nei test; di default i progressi salvati della storia.
  final Future<StoryController> Function()? story;

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
  Future<TournamentController>? _tournaments;
  Future<EndgameController>? _endgames;
  Future<StoryController>? _story;

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
  Future<PathController> _pathController() => _path ??=
      (widget.path ?? () => PathController.open(recordActivity: _record))()
          .catchError((Object e, StackTrace st) {
            _path = null;
            Error.throwWithStackTrace(e, st);
          });

  /// Un solo torneo in memoria, salvato a ogni partita.
  Future<TournamentController> _tournamentController() => _tournaments ??=
      (widget.tournaments ??
              () => TournamentController.open(recordActivity: _record))()
          .catchError((Object e, StackTrace st) {
            _tournaments = null;
            Error.throwWithStackTrace(e, st);
          });

  /// Un solo allenatore dei finali in memoria, salvato a ogni prova.
  Future<EndgameController> _endgameController() => _endgames ??=
      (widget.endgames ??
              () => EndgameController.open(recordActivity: _record))()
          .catchError((Object e, StackTrace st) {
            _endgames = null;
            Error.throwWithStackTrace(e, st);
          });

  Future<Widget> _endgamesPage() async => EndgamesPage(
    controller: await _endgameController(),
    createComputer: widget.createComputer ?? ComputerPlayer.new,
    simple: _kidMode,
    tablebase: sharedTablebase(),
  );

  /// Una sola storia in memoria, salvata a ogni passo.
  Future<StoryController> _storyController() =>
      _story ??= (widget.story ?? StoryController.open)().catchError((
        Object e,
        StackTrace st,
      ) {
        _story = null;
        Error.throwWithStackTrace(e, st);
      });

  Future<Widget> _storyPage() async => StoryPage(
    path: await _pathController(),
    story: await _storyController(),
    playGuardian: _computerAvailable ? _playGuardian : null,
    playBoss: _computerAvailable ? _playStoryBoss : null,
    playPuzzles: _playStoryPuzzles,
  );

  /// Sfida del capitolo contro [bot]: vale come allenamento, con Annulla.
  /// Uscire a partita in corso vale una sconfitta.
  Future<bool> _playStoryBoss(BuildContext context, Bot bot) async {
    GameResult? result;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          settings: widget.settings,
          computerAvailable: true,
          createComputer: widget.createComputer,
          challenge: GameChallenge(
            title: '${bot.avatar} ${bot.name}',
            levelId: bot.levelId,
            side: Side.white,
            allowUndo: true,
          ),
          onFinished: (r, _) => result = r,
          onActivity: _record,
          onSave: _saveGame,
          progress: _progressController,
        ),
      ),
    );
    return result == GameResult.win;
  }

  /// Puzzle del tema del capitolo fino a [remaining] risolti al primo
  /// tentativo; `null` se la raccolta non si carica.
  Future<int?> _playStoryPuzzles(
    BuildContext context,
    StoryChapter chapter,
    int remaining,
  ) async {
    final PuzzleTrainer trainer;
    try {
      trainer = await (_trainer ??= _loadTrainer());
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Puzzle non disponibili: $e');
      return null;
    }
    if (!context.mounted) return 0;
    final feed = StoryPuzzleFeed(
      trainer,
      theme: chapter.puzzleTheme,
      goal: remaining,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzlePage(
          trainer: trainer,
          theme: chapter.puzzleTheme,
          feed: feed,
          title: storyL10n(context).chapterTitle(chapter),
          onActivity: _record,
        ),
      ),
    );
    return feed.solved;
  }

  /// Bot del torneo: un avversario per ogni livello del motore.
  static final _bots = [
    for (final l in engineLevels)
      Player(name: l.name, elo: l.approxElo, levelId: l.id),
  ];

  Future<Widget> _tournamentPage() async {
    final controller = await _tournamentController();
    final games = await (await _archive()).list();
    return TournamentPage(
      controller: controller,
      bots: _bots,
      userElo: LocalRating.from(games).rating,
      play: _playTournamentGame,
    );
  }

  /// Gioca la partita del torneo e restituisce i punti, o `null` se non si è
  /// conclusa. L'uscita dalla partita vale una sconfitta.
  Future<double?> _playTournamentGame(
    BuildContext context,
    UserGame game,
  ) async {
    GameResult? result;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          settings: widget.settings,
          computerAvailable: true,
          createComputer: widget.createComputer,
          challenge: GameChallenge(
            title: 'Torneo · ${game.opponent.name}',
            levelId:
                game.opponent.levelId ??
                engineLevelForElo(game.opponent.elo).id,
            side: game.color,
          ),
          onFinished: (r, _) => result = r,
          onActivity: _record,
          onSave: _saveGame,
          progress: _progressController,
        ),
      ),
    );
    // Uscire prima di muovere vale una sconfitta: non si rilancia la partita.
    return tournamentPoints(result ?? GameResult.loss, game);
  }

  bool get _computerAvailable =>
      widget.computerAvailable ?? StockfishTransport.isSupported;

  /// Gioca il guardiano di [stage] e restituisce le stelle, o `null` se non si
  /// è vinto.
  Future<int?> _playGuardian(BuildContext context, Stage stage) async {
    GameResult? result;
    var moves = 0;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          settings: widget.settings,
          computerAvailable: true,
          createComputer: widget.createComputer,
          challenge: GameChallenge(
            title: 'Il guardiano',
            levelId: engineLevelForElo(stage.guardianElo!).id,
            side: Side.white,
            allowUndo: true,
          ),
          onFinished: (r, m) {
            result = r;
            moves = m;
          },
          onActivity: _record,
          onSave: _saveGame,
          progress: _progressController,
        ),
      ),
    );
    final r = result;
    return r == null ? null : challengeStars(r, moves: moves);
  }

  /// Gioca contro il computer a partire da un'apertura (RF-94).
  Future<void> _playOpening(BuildContext context, OpeningGameRequest request) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GamePage(
            settings: widget.settings,
            computerAvailable: true,
            createComputer: widget.createComputer,
            challenge: GameChallenge(
              title: request.title,
              levelId: request.levelId,
              side: request.side,
              allowUndo: true,
              startMoves: request.startMoves,
              line: request.line,
            ),
            onActivity: _record,
            onSave: _saveGame,
            progress: _progressController,
          ),
        ),
      );

  /// Apre nella revisione una partita dell'archivio.
  Future<void> _openSavedGame(BuildContext context, SavedGame saved) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final imported = importPgn(saved.pgn).games;
    if (imported.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('La partita non si può aprire.')),
      );
      return;
    }
    if (!_computerAvailable) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'La revisione richiede il motore: su Android e iOS è incluso, '
            'su Windows e Linux serve Stockfish installato.',
          ),
        ),
      );
      return;
    }
    final game = imported.first.game;
    final player = widget.createComputer?.call() ?? ComputerPlayer();
    final side = saved.playerSide;
    final players = side == null ? {Side.white, Side.black} : {side};
    try {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ReviewPage(
            initial: game.initial,
            moves: [for (final m in game.moves) m.move],
            evaluate: engineEvaluator(player),
            onCancel: player.stopAnalysis,
            analyseLive: (fen, multiPv) =>
                player.analyseLive(fen, multiPv: multiPv),
            onReviewed: (review) => _record(
              ReviewCompleted(
                accuracy: players.length == 1
                    ? review.accuracy(players.single)
                    : null,
                brilliantMoves: [
                  for (final s in players) review.count(s, MoveClass.brilliant),
                ].fold(0, (a, b) => a + b),
              ),
            ),
            onSavePuzzles: _savePersonalPuzzles,
            puzzlePlayers: players,
            clocks: [for (final m in game.moves) m.clock],
            notes: [for (final m in game.moves) m.note],
            onNoteChanged: (ply, note) {
              game.annotate(ply, note);
              return _saveGame(
                saved.copyWith(
                  pgn: exportPgn(game, headers: imported.first.headers),
                ),
              );
            },
            timeControl: TimeControl.parse(saved.timeControl ?? ''),
            startTimes: Handicap.startTimesFromPgn(
              imported.first.headers['Handicap'],
              TimeControl.parse(saved.timeControl ?? ''),
            ),
          ),
        ),
      );
    } finally {
      player.dispose().ignore();
    }
  }

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

  /// Mette i puzzle dagli errori nel ripasso. Il caricamento dei puzzle è lo
  /// stesso della scheda Puzzle: un solo archivio in memoria.
  Future<int> _savePersonalPuzzles(List<MistakePuzzle> puzzles) async {
    final trainer = await (_trainer ??= _loadTrainer());
    return trainer.addPersonal([for (final p in puzzles) p.toPuzzle()]);
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
            onSavePuzzles: _savePersonalPuzzles,
            onSave: _saveGame,
            progress: _progressController,
            computerAvailable: widget.computerAvailable,
            createComputer: widget.createComputer,
          ),
          if (_trainer != null)
            PuzzleHubPage(trainer: _trainer!, onActivity: _record)
          else
            const SizedBox.shrink(),
          if (_repertoire != null)
            OpeningsHubPage(
              repertoire: _repertoire!,
              onPlay: _computerAvailable ? _playOpening : null,
              archive: _archive,
            )
          else
            const SizedBox.shrink(),
          if (_tab == 3 || _youVisited)
            YouPage(
              progress: _progressController,
              path: _pathController,
              archive: _archive,
              reminders: () => _reminders,
              simple: _kidMode,
              playGuardian: _computerAvailable ? _playGuardian : null,
              storyPage: _storyPage,
              openGame: _openSavedGame,
              tournamentPage: _computerAvailable ? _tournamentPage : null,
              endgamesPage: _computerAvailable ? _endgamesPage : null,
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
