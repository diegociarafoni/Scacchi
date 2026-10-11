import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../analysis/analysis_page.dart';
import '../archive/saved_game.dart';
import '../coach/coach_session.dart';
import '../editor/position_editor_page.dart';
import '../engine/adaptive.dart';
import '../engine/bot_collection.dart';
import '../engine/bots.dart';
import '../engine/computer_player.dart';
import '../engine/levels.dart';
import '../engine/uci_transport.dart';
import '../openings/opening_name.dart';
import '../progress/activity.dart';
import '../progress/game_activity.dart';
import '../progress/progress_controller.dart';
import '../progress/progress_feedback.dart';
import '../puzzles/activity_recorder.dart';
import '../review/engine_evaluator.dart';
import '../review/game_review.dart';
import '../review/move_classification.dart';
import '../review/personal_puzzles.dart';
import '../review/review_page.dart';
import '../settings/settings.dart';
import '../settings/settings_page.dart';
import '../storage/key_value_store.dart';
import 'challenge.dart';
import 'chess_game.dart';
import 'clock.dart';
import 'material.dart';
import 'move_input.dart';
import 'move_label.dart';
import 'move_speech.dart';
import 'opponent_picker.dart';
import 'sounds.dart';
import 'variant.dart';

/// Semimosse minime perché una partita valga XP: abbandonare subito non deve
/// far guadagnare nulla.
const _minPliesForProgress = 4;

/// Tempo massimo di una partita che conta per l'obiettivo a minuti, per non
/// gonfiarlo con le pause (app in background, finestre aperte).
const _maxCountedPlay = Duration(hours: 1);

/// Partita tra due persone sullo stesso dispositivo o contro il computer.
class GamePage extends StatefulWidget {
  GamePage({
    super.key,
    required this.settings,
    this.chess960Id = randomChess960Id,
    bool? computerAvailable,
    this.createComputer,
    this.now,
    this.onActivity,
    this.onSave,
    this.progress,
    this.challenge,
    this.onFinished,
    this.store,
    this.onSavePuzzles,
  }) : computerAvailable = computerAvailable ?? StockfishTransport.isSupported;

  final SettingsController settings;
  final bool computerAvailable;
  final ComputerPlayer Function()? createComputer;

  /// Archivio della stima dell'avversario adattivo; quello su file se assente.
  final KeyValueStore? store;

  /// Ora corrente per l'orologio; quella di sistema se assente.
  final DateTime Function()? now;

  /// Registra la partita finita nei progressi; senza, nessun XP.
  final ActivityRecorder? onActivity;

  /// Salva la partita finita nell'archivio; senza, nessun salvataggio.
  final Future<void> Function(SavedGame game)? onSave;

  /// Partita già impostata da un'altra schermata: parte subito e non si può
  /// ricominciare né annullare.
  final GameChallenge? challenge;

  /// Esito per l'utente e mosse complete giocate, a fine partita contro il
  /// computer, una volta per partita (sfide).
  final void Function(GameResult result, int moves)? onFinished;

  /// Progressi da mostrare nelle impostazioni (temi e ricompense da sbloccare).
  final Future<ProgressController> Function()? progress;

  /// Salva i puzzle ricavati dagli errori della revisione.
  final Future<int> Function(List<MistakePuzzle> puzzles)? onSavePuzzles;

  /// Sceglie la posizione Chess960; sostituibile nei test.
  final int Function() chess960Id;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  ChessGame _game = ChessGame();
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );
  Side _orientation = Side.white;

  /// Partita i cui XP sono già stati assegnati, per farlo una volta sola.
  ChessGame? _recordedGame;

  /// Esito già comunicato a [GamePage.onFinished]; dopo un annulla la partita
  /// riprende e l'esito nuovo sostituisce il precedente.
  String? _reportedEnding;

  /// Ultimo stato salvato nell'archivio (partita, esito, mosse).
  String? _archivedKey;
  late DateTime _startedAt = _clockNow();
  late String _gameId = 'game-${_startedAt.microsecondsSinceEpoch}';
  var _fromEditor = false;
  GameSetup _setup = const GameSetup();
  AdaptiveOpponent _adaptive = const AdaptiveOpponent();

  /// Stima prima dell'esito della partita in corso, per ripristinarla se si annulla.
  AdaptiveOpponent _adaptiveBefore = const AdaptiveOpponent();
  Future<KeyValueStore>? _store;

  /// Livello della partita in corso contro il computer.
  int _gameLevel = defaultEngineLevel;
  bool _resultRecorded = false;

  /// Bot della partita in corso, `null` contro il computer o tra due persone.
  Bot? _bot;
  BotCollection _collection = const BotCollection();
  BotCollection _collectionBefore = const BotCollection();
  bool _botResultRecorded = false;

  /// Ultima variante scelta per la partita tra due persone.
  Variant _twoPlayerVariant = Variant.standard;
  final _random = math.Random();

  /// Lato giocato dal computer; `null` nella partita tra due persone.
  Side? _computerSide;
  ComputerPlayer? _computer;

  /// Allenatore in partita (RF-73): giudica le mosse dell'utente.
  bool _coachOn = false;
  String? _hintedFen;
  late CoachSession _coach = _newCoach();

  CoachSession _newCoach() => CoachSession(
    evaluate: (fen) => _computerPlayer.analyse(fen, depth: 12, multiPv: 2),
  );
  _ComputerTask _task = _ComputerTask.none;
  bool get _thinking => _task != _ComputerTask.none;

  /// Invalida le risposte del computer per posizioni non più attuali.
  int _generation = 0;

  /// Orologio all'inizio della riflessione del computer in corso.
  Map<Side, Duration>? _searchClock;

  /// Sospensioni attive (finestre aperte, app in background).
  int _suspensions = 0;
  bool _clockBeforeSuspension = false;
  bool _inBackground = false;
  ChessClock? _clock;
  Timer? _ticker;
  final List<Map<Side, Duration>> _clockHistory = [];
  final ValueNotifier<int> _tick = ValueNotifier(0);
  final SoundPlayer _sounds = SoundPlayer();
  final LowTimeAlarm _lowTime = LowTimeAlarm();
  Move? _pendingMove;

  /// Semimossa visualizzata (-1 = posizione iniziale), null = partita in corso.
  int? _viewPly;

  AppSettings get _settings => widget.settings.value;

  late bool _autoFlip;

  /// Nomi dei giocatori: solo nella partita tra due persone.
  String? _nameOf(Side side) =>
      _computerSide == null ? _settings.nameOf(side) : null;

  @override
  void initState() {
    super.initState();
    _autoFlip = _settings.autoFlip;
    widget.settings.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadProfile());
    if (_isChallenge) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startChallenge());
    }
  }

  bool get _isChallenge => widget.challenge != null;

  /// Una sfida non ha ancora iniziato la partita: fino ad allora la scacchiera
  /// non accetta mosse.
  late bool _awaitingChallenge = _isChallenge;

  void _startChallenge() {
    final challenge = widget.challenge;
    if (!mounted || challenge == null) return;
    _awaitingChallenge = false;
    final setup = _applySetup(
      GameSetup(
        opponent: Opponent.computer,
        sideChoice: challenge.side == Side.white
            ? SideChoice.white
            : SideChoice.black,
        level: challenge.levelId,
      ),
    );
    _beginGame(ChessGame(), setup, null);
  }

  Future<KeyValueStore> _openStore() => _store ??= () async {
    if (widget.store != null) return widget.store!;
    try {
      return await JsonFileStore.open();
    } on Object catch (_) {
      return MemoryStore();
    }
  }();

  Future<void> _loadProfile() async {
    final store = await _openStore();
    final adaptive = await AdaptiveOpponent.load(store)
        .catchError((_) => const AdaptiveOpponent());
    final collection = await BotCollection.load(store)
        .catchError((_) => const BotCollection());
    if (!mounted) return;
    setState(() {
      if (!_resultRecorded && _adaptive.games == 0) _adaptive = adaptive;
      if (!_botResultRecorded && _collection.beaten.isEmpty) {
        _collection = collection;
      }
    });
  }

  /// Aggiorna la stima a fine partita adattiva, una sola volta; se la partita
  /// viene riaperta (annulla) ripristina quella precedente. Le partite chiuse
  /// senza mosse non contano.
  void _recordAdaptiveResult() {
    final side = _computerSide;
    if (side == null || _bot != null || !_setup.adaptive || !_standardStart) {
      return;
    }
    if (_resultRecorded && !_game.isOver) {
      _resultRecorded = false;
      _adaptive = _adaptiveBefore;
      _saveAdaptive();
      return;
    }
    if (_resultRecorded || !_game.isOver || _game.moves.isEmpty) return;
    _resultRecorded = true;
    _adaptiveBefore = _adaptive;
    final winner = _game.outcome?.winner;
    final score = winner == null ? 0.5 : (winner == side ? 0.0 : 1.0);
    _adaptive = _adaptive.record(score, level: _gameLevel);
    _saveAdaptive();
  }

  /// A fine partita contro un bot lo aggiunge alla collezione se ha vinto il
  /// giocatore e fa commentare il bot; una partita riaperta (annulla) si può
  /// registrare di nuovo.
  void _recordBotResult() {
    final bot = _bot;
    final side = _computerSide;
    if (bot == null || side == null) return;
    if (_botResultRecorded && !_game.isOver) {
      _botResultRecorded = false;
      if (!identical(_collection, _collectionBefore)) {
        _collection = _collectionBefore;
        final restored = _collection;
        unawaited(_openStore().then(restored.save).catchError((_) {}));
      }
      return;
    }
    if (_botResultRecorded || !_game.isOver || _game.moves.isEmpty) return;
    _botResultRecorded = true;
    final winner = _game.outcome?.winner;
    _collectionBefore = _collection;
    if (_standardStart && winner != null && winner != side) {
      final updated = _collection.beat(bot.id, DateTime.now());
      if (!identical(updated, _collection)) {
        _collection = updated;
        unawaited(_openStore().then(updated.save).catchError((_) {}));
      }
    }
    _botSay(
      winner == null
          ? BotEvent.draw
          : (winner == side ? BotEvent.win : BotEvent.loss),
    );
  }

  /// Il bot commenta il proprio scacco e, ogni tanto, le proprie catture.
  void _botReact() {
    if (_game.position.isCheck) {
      _botSay(BotEvent.check);
    } else if (_game.moves.last.san.contains('x') && _random.nextInt(3) == 0) {
      _botSay(BotEvent.capture);
    }
  }

  void _botSay(BotEvent event) {
    final bot = _bot;
    if (bot == null || !mounted) return;
    _showMessage('${bot.avatar} ${bot.name}: ${bot.phrase(event, _random)}');
  }

  void _saveAdaptive() {
    final adaptive = _adaptive;
    unawaited(_openStore().then(adaptive.save).catchError((_) {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_inBackground) return;
      _inBackground = false;
      _resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_inBackground) return;
      _inBackground = true;
      _suspend();
    }
  }

  /// Ferma orologio e computer; la ricerca interrotta non costa tempo al computer.
  void _suspend() {
    if (_suspensions++ > 0) return;
    final clock = _clock;
    _clockBeforeSuspension = clock?.isRunning ?? false;
    final searchStart = _searchClock;
    _cancelComputerMove();
    if (clock != null && searchStart != null) {
      clock.restore(searchStart, null);
    } else {
      clock?.pause();
    }
    _syncClock();
    _tick.value++;
  }

  /// Chiude una sospensione; all'ultima, se [restart], riparte da dove era.
  void _resume({bool restart = true}) {
    if (_suspensions == 0 || --_suspensions > 0 || !restart) return;
    if (!mounted || _game.isOver) return;
    if (_clockBeforeSuspension) _clock?.start(_game.position.turn);
    _syncClock();
    _tick.value++;
    unawaited(_computerMove());
  }

  /// Esegue [action] con orologio e computer fermi; riparte se [restart] lo consente.
  Future<T?> _whileSuspended<T>(
    Future<T?> Function() action, {
    bool Function(T? result)? restart,
  }) async {
    _suspend();
    T? result;
    try {
      result = await action();
    } finally {
      if (mounted) _resume(restart: restart?.call(result) ?? true);
    }
    return result;
  }

  Future<T?> _suspendedDialog<T>(
    WidgetBuilder builder, {
    bool Function(T? result)? restart,
  }) => _whileSuspended(
    () => showDialog<T>(context: context, builder: builder),
    restart: restart,
  );

  @override
  void didUpdateWidget(GamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      oldWidget.settings.removeListener(_onSettingsChanged);
      widget.settings.addListener(_onSettingsChanged);
      _onSettingsChanged();
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    _generation++;
    _computer?.dispose().ignore();
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _tick.dispose();
    _sounds.dispose();
    _board.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {
      final turnedOn = _settings.autoFlip && !_autoFlip;
      _autoFlip = _settings.autoFlip;
      if (turnedOn && _computerSide == null) {
        _orientation = _game.position.turn;
      }
    });
  }

  PlayerSide get _playerSide {
    if (_game.isOver || _thinking || _awaitingChallenge) {
      return PlayerSide.none;
    }
    return switch (_computerSide) {
      null => PlayerSide.both,
      Side.white => PlayerSide.black,
      Side.black => PlayerSide.white,
    };
  }

  bool get _humanToMove => _playerSide != PlayerSide.none && !_computerToMove;

  ComputerPlayer get _computerPlayer =>
      _computer ??= widget.createComputer?.call() ?? ComputerPlayer();

  GameData _gameData() {
    final pos = _game.position;
    return GameData(
      fen: pos.fen,
      lastMove: _game.lastMove,
      playerSide: _playerSide,
      sideToMove: pos.turn,
      kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
      validMoves: makeLegalMoves(pos),
    );
  }

  /// Posizione da mostrare senza poter muovere.
  GameData _staticData(Position pos, Move? lastMove) => GameData(
    fen: pos.fen,
    lastMove: lastMove,
    playerSide: PlayerSide.none,
    sideToMove: pos.turn,
    kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
    validMoves: const {},
  );

  var _openingSettings = false;

  Future<void> _openSettings() async {
    if (_openingSettings) return;
    _openingSettings = true;
    try {
      ProgressController? progress;
      try {
        progress = await widget.progress?.call();
      } on Object catch (e) {
        // Senza progressi le impostazioni restano utilizzabili, senza i blocchi.
        debugPrint('Progressi non disponibili: $e');
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              SettingsPage(controller: widget.settings, progress: progress),
        ),
      );
    } finally {
      _openingSettings = false;
    }
  }

  DateTime _clockNow() => (widget.now ?? DateTime.now)();

  /// Inizia una nuova partita per progressi e archivio. Una posizione
  /// preparata con l'editor si archivia ma non vale XP.
  void _startRecording({bool fromEditor = false}) {
    _startedAt = _clockNow();
    _gameId = 'game-${_startedAt.microsecondsSinceEpoch}';
    _fromEditor = fromEditor;
  }

  /// A fine partita la salva nell'archivio e la registra nei progressi.
  ///
  /// Dopo un annulla dell'abbandono o del tempo scaduto la partita riprende e
  /// può finire in altro modo: l'archivio si aggiorna (stesso `id`), gli XP si
  /// assegnano una volta sola per partita.
  void _finishGame() {
    final game = _game;
    if (!game.isOver) return;
    final side = _computerSide?.opposite;
    final ending =
        '${identityHashCode(game)}:${game.endReason}:${game.moves.length}';
    if (side != null && ending != _reportedEnding) {
      _reportedEnding = ending;
      final winner = game.outcome?.winner;
      widget.onFinished?.call(
        winner == null
            ? GameResult.draw
            : (winner == side ? GameResult.win : GameResult.loss),
        (game.moves.length + 1) ~/ 2,
      );
    }
    if (game.moves.isEmpty) return;
    final now = _clockNow();
    final elo = side == null
        ? null
        : (_bot?.elo ?? engineLevel(_gameLevel).approxElo);
    final key =
        '${identityHashCode(game)}:${game.endReason}:${game.moves.length}';
    if (key != _archivedKey) {
      _archivedKey = key;
      _archive(game, side, now, elo);
    }
    if (identical(game, _recordedGame) ||
        _fromEditor ||
        game.moves.length < _minPliesForProgress) {
      return;
    }
    _recordedGame = game;
    final elapsed = now.difference(_startedAt);
    unawaited(
      _record(
        gameActivity(
          game,
          player: side,
          opponentElo: elo,
          duration: elapsed.isNegative
              ? Duration.zero
              : elapsed > _maxCountedPlay
              ? _maxCountedPlay
              : elapsed,
        ),
      ),
    );
  }

  /// Salvataggio e progressi vanno avanti da soli: uno lento o fallito non
  /// ferma l'altro.
  void _archive(ChessGame game, Side? side, DateTime now, int? elo) {
    final save = widget.onSave;
    if (save == null) return;
    String name(Side s) => side == null
        ? (_settings.nameOf(s) ?? (s == Side.white ? 'Bianco' : 'Nero'))
        : (s == side ? 'Tu' : (_bot?.name ?? 'Computer'));
    final saved = SavedGame.fromGame(
      game,
      id: _gameId,
      white: name(Side.white),
      black: name(Side.black),
      mode: side == null ? SavedGame.local : SavedGame.computer,
      createdAt: _startedAt,
      updatedAt: now,
      playerSide: side,
      timeControl: _clock?.control.label,
      opponentElo: elo,
    );
    unawaited(
      save(saved)
          .onError((Object e, _) => debugPrint('Partita non salvata: $e')),
    );
  }

  Future<void> _record(GamePlayed activity) async {
    try {
      final update = await widget.onActivity?.call(activity);
      if (update != null && mounted) {
        final message = progressMessage(update);
        if (message != null) _showMessage(message);
      }
    } on Object catch (e) {
      debugPrint('Progressi non registrati: $e');
    }
  }

  void _refresh({bool animate = true}) {
    _pendingMove = null;
    _viewPly = null;
    _syncClock();
    _finishGame();
    _board.updatePosition(_gameData(), animate: animate, resetPremove: true);
    _recordAdaptiveResult();
    _recordBotResult();
    setState(() {
      if (_settings.autoFlip && _computerSide == null) {
        _orientation = _game.position.turn;
      }
    });
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    if (!_humanToMove) return;
    if (!_settings.confirmMove) {
      _commitMove(move, animate: viaDragAndDrop != true);
      return;
    }
    if (!_game.position.isLegal(move)) return;
    final (preview, san) = _game.position.makeSan(move);
    final turn = _game.position.turn;
    _announce('Da confermare. ${describeSan(san, turn, name: _nameOf(turn))}');
    _board.updatePosition(
      _staticData(preview, move),
      animate: viaDragAndDrop != true,
    );
    setState(() => _pendingMove = move);
  }

  void _confirmPending() {
    final move = _pendingMove;
    if (move == null) return;
    setState(() => _pendingMove = null);
    _commitMove(move, animate: false);
  }

  void _discardPending() {
    _clearBoardInteraction();
    _refresh(animate: false);
  }

  void _commitMove(Move move, {required bool animate}) {
    final before = _game.position;
    final played = _apply(move);
    if (!played && !_game.isOver) return;
    _refresh(animate: played && animate);
    if (played) unawaited(_afterHumanMove(before, move));
  }

  /// Con l'allenatore acceso, giudica la mossa prima della risposta del
  /// computer; un errore offre di riprenderla.
  Future<void> _afterHumanMove(Position before, Move move) async {
    if (!_coachOn || _computerSide == null || _game.isOver) {
      return _computerMove();
    }
    final plies = _game.moves.length;
    _showMessage(
      'L\'allenatore valuta la mossa…',
      duration: const Duration(seconds: 2),
    );
    final retry = await _whileSuspended<bool>(() async {
      final MoveVerdict verdict;
      try {
        verdict = await _coach.judge(before, move);
      } on Object {
        return false;
      }
      if (!mounted || _game.isOver || _game.moves.length != plies) {
        return false;
      }
      final text = verdict.comment?.text;
      if (!verdict.shouldWarn) {
        if (text != null) _announce(text);
        return false;
      }
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Allenatore'),
          content: Text(text ?? 'Questa mossa peggiora la tua posizione.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continua'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }, restart: (retry) => retry != true);
    if (retry == true && mounted && _game.moves.length == plies) _undo();
  }

  /// Suggerimento a livelli: prima il pezzo, poi la mossa.
  Future<void> _giveHint() async {
    final position = _game.position;
    final level = _hintedFen == position.fen ? HintLevel.move : HintLevel.piece;
    CoachHint? hint;
    try {
      hint = await _whileSuspended(() => _coach.hint(position, level));
    } on Object {
      hint = null;
    }
    if (!mounted || !identical(position, _game.position)) return;
    if (hint == null) {
      _showMessage('Nessun suggerimento disponibile.');
      return;
    }
    _hintedFen = position.fen;
    _showMessage(
      level == HintLevel.piece
          ? 'Prova a muovere il pezzo in ${hint.from.name}.'
          : 'Prova ${hint.san}.',
    );
  }

  /// Gioca [move] con orologio, suono e annuncio; con il tempo scaduto chiude la partita.
  bool _apply(Move move) {
    final clock = _clock;
    final flagged = clock?.flagged;
    if (flagged != null) {
      _game.flag(flagged);
      _playSound(GameSound.gameEnd);
      _announce(statusText(_game, _nameOf));
      return false;
    }
    final before = clock?.snapshot();
    final position = _game.position;
    if (!_game.play(move)) return false;
    final spoken = describeSan(
      _game.moves.last.san,
      position.turn,
      name: _nameOf(position.turn),
    );
    _announce(_game.isOver ? '$spoken. ${statusText(_game, _nameOf)}' : spoken);
    final sound = soundForLastMove(_game, position);
    if (sound != null) _playSound(sound);
    if (clock != null) {
      _clockHistory.add(before!);
      if (clock.isRunning) {
        clock.switchAfterMove();
      } else {
        clock.start(_game.position.turn);
      }
    }
    return true;
  }

  Future<void> _computerMove() async {
    final side = _computerSide;
    if (_thinking || side == null || _game.isOver || _suspensions > 0) return;
    if (_game.position.turn != side) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final generation = _generation;
    _task = _ComputerTask.move;
    final clock = _clock;
    if (clock != null && !clock.isRunning && _game.moves.isNotEmpty) {
      clock.start(side);
    }
    _searchClock = clock?.snapshot();
    var level = _bot?.level ?? engineLevel(_gameLevel);
    if (clock != null) {
      level = level.withinClock(
        clock.remaining(side),
        Duration(seconds: clock.control.increment),
      );
    }
    _refresh(animate: false);
    EngineMove? reply;
    Object? error;
    try {
      final book = _bookMove();
      if (book != null) {
        await Future<void>.delayed(level.minReply);
        reply = EngineMove(move: book, pv: const []);
      } else {
        reply = await _computerPlayer.bestMove(
          _game.initial.fen,
          _moveHistory,
          level,
        );
      }
    } on Object catch (e) {
      error = e;
    }
    if (!mounted || generation != _generation) return;
    _task = _ComputerTask.none;
    final searchStart = _searchClock;
    _searchClock = null;
    final played = reply != null && _apply(reply.move);
    if (reply == null ? !_game.isOver : !played && !_game.isOver) {
      error ??= reply ?? 'nessuna mossa';
      if (searchStart != null) clock?.restore(searchStart, null);
    }
    final viewing = _viewPly;
    _refresh();
    if (viewing != null) _showPly(viewing);
    if (played && !_game.isOver) _botReact();
    if (error != null) {
      _showMessage(
        'Il computer non risponde.',
        duration: const Duration(days: 1),
        action: SnackBarAction(label: 'Riprova', onPressed: _computerMove),
      );
    }
  }

  /// Partita di scacchi classici dalla posizione iniziale: solo queste contano
  /// per la stima adattiva e per la collezione dei bot.
  bool get _standardStart =>
      _game.variant == Variant.standard &&
      _game.initial.fen == Chess.initial.fen;

  /// Mossa del libro d'apertura del bot, solo negli scacchi classici.
  Move? _bookMove() {
    final bot = _bot;
    if (bot == null || !_standardStart) return null;
    return bot.bookMoveFor(_game.initial, _moveHistory, _random);
  }

  List<Move> get _moveHistory => [for (final m in _game.moves) m.move];

  /// Posizione sulla scacchiera, anche mentre si scorrono le mosse.
  Position get _shownPosition {
    final ply = _viewPly;
    if (ply == null) return _game.position;
    return ply == -1 ? _game.initial : _game.moves[ply].after;
  }

  void _cancelComputerMove() {
    _generation++;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (_thinking) _computer?.stop();
    _task = _ComputerTask.none;
    _searchClock = null;
  }

  /// Mostra la posizione dopo la semimossa [ply] (-1 = iniziale); `null` o
  /// oltre l'ultima mossa torna alla partita in corso.
  void _showPly(int? ply) {
    if (_pendingMove != null || _game.moves.isEmpty) return;
    if (ply == null || ply >= _game.moves.length) {
      if (_viewPly != null) {
        _clearBoardInteraction();
        _refresh(animate: false);
      }
      return;
    }
    final target = ply < -1 ? -1 : ply;
    _board.updatePosition(
      target == -1
          ? _staticData(_game.initial, null)
          : _staticData(_game.moves[target].after, _game.moves[target].move),
      animate: false,
    );
    setState(() => _viewPly = target);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final current = _viewPly ?? _game.moves.length - 1;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _showPly(current - 1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _showPly(current + 1);
    } else if (key == LogicalKeyboardKey.home) {
      _showPly(-1);
    } else if (key == LogicalKeyboardKey.end) {
      _showPly(null);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Ferma l'orologio a fine partita e aggiorna il timer di visualizzazione.
  void _syncClock() {
    final clock = _clock;
    if (clock != null && _game.isOver) clock.pause();
    if (clock != null && clock.isRunning) {
      _ticker ??= Timer.periodic(const Duration(milliseconds: 100), _onTick);
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _onTick(Timer _) {
    final clock = _clock;
    final flagged = clock?.flagged;
    if (flagged != null && !_game.isOver) {
      _cancelComputerMove();
      _game.flag(flagged);
      _playSound(GameSound.gameEnd);
      _announce(statusText(_game, _nameOf));
      _refresh(animate: false);
      return;
    }
    final active = clock?.active;
    if (active != null &&
        active != _computerSide &&
        _lowTime.check(active, clock!.remaining(active))) {
      _playSound(GameSound.lowTime);
    }
    _tick.value++;
  }

  void _announce(String message) {
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  void _playSound(GameSound sound) {
    final s = _settings;
    unawaited(
      _sounds.play(
        sound,
        enabled: s.sound,
        volume: s.volume,
        haptics: s.haptics,
      ),
    );
  }

  /// Chiude selezione e selettore di promozione rimasti aperti sulla scacchiera.
  void _clearBoardInteraction() {
    _board.updatePosition(
      _staticData(_game.position, _game.lastMove),
      animate: false,
    );
  }

  /// Messaggio sopra la barra dei comandi, per non coprirla.
  void _showMessage(
    String text, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, _actionsHeight + 8),
    ),
  );

  /// Memorizza la scelta dell'avversario; un bot bloccato diventa il primo.
  GameSetup _applySetup(GameSetup chosen) {
    var setup = chosen;
    var bot = setup.opponent == Opponent.bot ? botById(setup.botId) : null;
    if (bot != null && !_collection.isUnlocked(bot)) {
      bot = bots.first;
      setup = setup.copyWith(botId: bot.id);
    }
    _setup = setup;
    _bot = bot;
    _gameLevel = setup.adaptive ? _adaptive.level : setup.level;
    _resultRecorded = false;
    _botResultRecorded = false;
    return setup;
  }

  Future<void> _newGame() async {
    final choice = await _whileSuspended(
      () => showModalBottomSheet<_TimeChoice>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _TimeControlSheet(
          variant: _twoPlayerVariant,
          whiteName: _settings.whiteName,
          blackName: _settings.blackName,
          setup: _setup,
          adaptiveLevel: _adaptive.level,
          collection: _collection,
          computerAvailable: widget.computerAvailable,
        ),
      ),
      restart: (choice) => choice == null,
    );
    if (!mounted || choice == null) return;
    final setup = _applySetup(choice.setup);
    final vsComputer = setup.opponent != Opponent.human;
    if (!vsComputer) _twoPlayerVariant = choice.variant;
    final variant = vsComputer ? Variant.standard : choice.variant;
    final control = choice.control;
    _beginGame(
      ChessGame(
        initial: initialPosition(
          variant,
          chess960Id: variant == Variant.chess960 ? widget.chess960Id() : null,
        ),
        variant: variant,
      ),
      setup,
      control == null ? null : ChessClock(control, now: widget.now),
    );
    if (vsComputer) return;
    unawaited(
      widget.settings.update(
        _settings.copyWith(
          whiteName: choice.whiteName,
          blackName: choice.blackName,
        ),
      ),
    );
  }

  /// Avvia [game] contro l'avversario di [setup]: azzera orologio e cronologia,
  /// dispone i lati e fa muovere subito chi tocca.
  void _beginGame(
    ChessGame game,
    GameSetup setup,
    ChessClock? clock, {
    bool fromEditor = false,
  }) {
    _cancelComputerMove();
    _clockBeforeSuspension = false;
    _coachOn = false;
    _hintedFen = null;
    _coach = _newCoach();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _game = game;
    _clock = clock;
    _clockHistory.clear();
    _lowTime.reset();
    _clearBoardInteraction();
    _startRecording(fromEditor: fromEditor);
    if (setup.opponent != Opponent.human) {
      final human = setup.resolveHumanSide(_random);
      _computerSide = human.opposite;
      _orientation = human;
      _computerPlayer.newGame().ignore();
    } else {
      if (_computerSide != null) _orientation = Side.white;
      _computerSide = null;
      _computer?.dispose().ignore();
      _computer = null;
    }
    _refresh(animate: false);
    unawaited(_computerMove());
    if (_bot != null) _botSay(BotEvent.start);
  }

  /// Apre l'editor sulla posizione mostrata e gioca senza orologio quella scelta.
  Future<void> _editPosition() async {
    final shown = _shownPosition;
    // Editor e scelta dell'avversario sono un'unica sospensione: chiudere uno
    // dei due lascia la partita, orologio compreso, com'era.
    final result = await _whileSuspended<(Position, GameSetup)>(() async {
      final position = await Navigator.of(context).push<Position>(
        MaterialPageRoute(
          builder: (_) =>
              PositionEditorPage(initialFen: shown.fen, board: _settings.board),
        ),
      );
      if (position == null || !mounted) return null;
      var chosen = _setup.copyWith(opponent: Opponent.human);
      if (widget.computerAvailable) {
        final picked = await showModalBottomSheet<GameSetup>(
          context: context,
          isScrollControlled: true,
          builder: (context) => _PositionSheet(
            setup: chosen,
            adaptiveLevel: _adaptive.level,
            collection: _collection,
          ),
        );
        if (picked == null) return null;
        chosen = picked;
      }
      return (position, chosen);
    }, restart: (result) => result == null);
    if (!mounted || result == null) return;
    final (position, chosen) = result;
    // Contro una persona restano le scelte fatte per il computer.
    if (chosen.opponent == Opponent.human) {
      _bot = null;
      _resultRecorded = false;
      _botResultRecorded = false;
    }
    final setup = chosen.opponent == Opponent.human
        ? chosen
        : _applySetup(chosen);
    _beginGame(ChessGame(initial: position), setup, null, fromEditor: true);
  }

  String get _title => switch (_game.variant) {
    Variant.standard => 'Scacchi',
    Variant.chess960 => switch (chess960IdOf(_game.initial)) {
      null => 'Chess960',
      final id => 'Chess960 n. $id',
    },
    Variant.kingOfTheHill => Variant.kingOfTheHill.label,
    // Non "1-0": si confonderebbe con un risultato.
    Variant.threeCheck =>
      'Scacchi dati: Bianco ${_checksGiven(Side.white)}, '
          'Nero ${_checksGiven(Side.black)}',
  };

  int _checksGiven(Side side) {
    final pos = _game.position;
    if (pos is! ThreeCheck) return 0;
    final (white, black) = pos.remainingChecks;
    return 3 - (side == Side.white ? white : black);
  }

  Future<void> _typeMove() async {
    final position = _game.position;
    final move = await showDialog<Move>(
      context: context,
      builder: (_) => _MoveInputDialog(position: position),
    );
    if (move == null || !mounted || _viewPly != null || _game.isOver) return;
    if (!_humanToMove) return;
    if (_pendingMove != null || !identical(position, _game.position)) return;
    _onMove(move);
  }

  void _undo() {
    if (_viewPly != null) {
      _showPly(null);
      return;
    }
    if (_pendingMove != null) {
      _discardPending();
      return;
    }
    _cancelComputerMove();
    final revokeOnly = _endedByChoice;
    final timedOut = _game.endReason == GameEndReason.timeout;
    _game.undo();
    if (timedOut) _game.undo();
    if (revokeOnly) {
      if (_game.moves.isNotEmpty) _clock?.start(_game.position.turn);
    } else {
      _restoreClock();
      if (_computerToMove && _game.canUndo) {
        _game.undo();
        _restoreClock();
      }
    }
    _clearBoardInteraction();
    _refresh(animate: false);
    unawaited(_computerMove());
  }

  bool get _endedByChoice => switch (_game.endReason) {
    GameEndReason.resignation || GameEndReason.agreement => true,
    _ => false,
  };

  void _restoreClock() {
    final clock = _clock;
    if (clock == null || _clockHistory.isEmpty) return;
    clock.restore(
      _clockHistory.removeLast(),
      _game.moves.isEmpty ? null : _game.position.turn,
    );
  }

  bool get _computerToMove => _computerSide == _game.position.turn;

  bool get _canUndo {
    if (!_game.canUndo) return false;
    if (_computerSide != Side.white || _endedByChoice) return true;
    if (_game.endReason == GameEndReason.timeout) return true;
    return _game.moves.length > 1;
  }

  Future<void> _resign() async {
    final side = _computerSide?.opposite ?? _game.position.turn;
    final confirmed = await _suspendedDialog<bool>(
      (context) => AlertDialog(
        title: const Text('Abbandonare la partita?'),
        content: Text('Abbandona ${_player(side, _nameOf)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abbandona'),
          ),
        ],
      ),
      restart: (confirmed) => confirmed != true,
    );
    if (!mounted) return;
    if (confirmed == true) {
      _game.resign(side);
      _playSound(GameSound.gameEnd);
      _refresh(animate: false);
    }
  }

  /// Il computer accetta la patta solo se si valuta in svantaggio.
  Future<void> _offerDrawToComputer() async {
    if (_thinking) return;
    final turn = _game.position.turn;
    int? computerScore;
    Object? error;
    var current = false;
    await _whileSuspended<void>(() async {
      final generation = _generation;
      _task = _ComputerTask.draw;
      _refresh(animate: false);
      try {
        final score = await _computerPlayer.evaluate(
          _game.initial.fen,
          _moveHistory,
        );
        if (score != null) {
          computerScore = turn == _computerSide
              ? score.comparable
              : -score.comparable;
        }
      } on Object catch (e) {
        error = e;
      }
      current = mounted && generation == _generation;
      if (current) {
        _task = _ComputerTask.none;
        _refresh(animate: false);
      }
    }, restart: (_) => !(current && _accepts(computerScore)));
    if (!mounted || !current || _game.isOver) return;
    if (error != null) return _showMessage('Il computer non risponde.');
    if (_accepts(computerScore)) {
      _game.agreeDraw();
      _playSound(GameSound.gameEnd);
      _refresh(animate: false);
      _showMessage('Il computer accetta la patta.');
    } else {
      _showMessage('Il computer rifiuta la patta.');
    }
  }

  bool _accepts(int? computerScore) =>
      computerScore != null && computerScore <= -_drawAcceptanceCp;

  Future<void> _offerDraw() async {
    if (_computerSide != null) return _offerDrawToComputer();
    final opponent = _game.position.turn.opposite;
    final accepted = await _suspendedDialog<bool>(
      (context) => AlertDialog(
        title: Text(
          '${_capitalized(_player(opponent, _nameOf))} accetta la patta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Rifiuta'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accetta'),
          ),
        ],
      ),
      restart: (accepted) => accepted != true,
    );
    if (!mounted) return;
    if (accepted == true) {
      _game.agreeDraw();
      _playSound(GameSound.gameEnd);
      _refresh(animate: false);
    }
  }

  LiveAnalysis _liveAnalysis(ComputerPlayer player) =>
      (fen, multiPv) => player.analyseLive(fen, multiPv: multiPv);

  /// Analisi della posizione mostrata con orologio e computer fermi.
  void _openAnalysis() {
    final position = _shownPosition;
    unawaited(
      _withEngine(
        (player) => AnalysisPage(
          initial: position,
          analyse: _liveAnalysis(player),
          orientation: _orientation,
        ),
      ),
    );
  }

  /// Revisione della partita con orologio e computer fermi.
  void _openReview() {
    final moves = _moveHistory;
    final computer = _computerSide;
    // Contro il computer contano gli errori di chi ha giocato, non quelli
    // del motore.
    final players = computer == null
        ? {Side.white, Side.black}
        : {computer.opposite};
    unawaited(
      _withEngine(
        (player) => ReviewPage(
          initial: _game.initial,
          moves: moves,
          evaluate: engineEvaluator(player),
          onCancel: player.stopAnalysis,
          analyseLive: _liveAnalysis(player),
          onReviewed: (review) => _recordReview(review, players),
          onSavePuzzles: widget.onSavePuzzles,
          puzzlePlayers: players,
        ),
      ),
    );
  }

  /// Una revisione nuova vale XP; con due giocatori la precisione non è di
  /// nessuno in particolare e non si registra.
  Future<void> _recordReview(GameReview review, Set<Side> players) async {
    final record = widget.onActivity;
    if (record == null) return;
    final update = await record(
      ReviewCompleted(
        accuracy: players.length == 1 ? review.accuracy(players.single) : null,
        brilliantMoves: [
          for (final side in players) review.count(side, MoveClass.brilliant),
        ].fold(0, (a, b) => a + b),
      ),
    );
    if (update != null && mounted) showProgressFeedback(context, update);
  }

  /// Apre una pagina che usa il motore. Nella partita tra due persone il
  /// motore serve solo a quella pagina e si chiude al ritorno.
  Future<void> _withEngine(Widget Function(ComputerPlayer player) page) async {
    final player = _computerPlayer;
    await _whileSuspended(
      () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => page(player))),
    );
    if (_computerSide == null && identical(_computer, player)) {
      _computer = null;
      player.dispose().ignore();
    }
  }

  Widget? _clockView(Side side) {
    final clock = _clock;
    if (clock == null) return null;
    return ListenableBuilder(
      listenable: _tick,
      builder: (context, _) => _ClockView(
        side: side,
        name: _nameOf(side),
        remaining: clock.remaining(side),
        active: clock.active == side,
      ),
    );
  }

  /// Uscire da una sfida in corso la fa perdere: prima si chiede conferma.
  Future<void> _confirmLeaveChallenge() async {
    final leave = await _suspendedDialog<bool>(
      (context) => AlertDialog(
        title: const Text('Lasciare la sfida?'),
        content: const Text('La partita in corso conta come persa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continua'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esci'),
          ),
        ],
      ),
      restart: (leave) => leave != true,
    );
    if (leave != true || !mounted) return;
    // L'uscita vale una resa: l'esito arriva a chi ha lanciato la sfida.
    final side = _computerSide?.opposite;
    if (side != null && !_game.isOver) {
      _cancelComputerMove();
      _game.resign(side);
      _refresh(animate: false);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inProgress = _isChallenge && !_game.isOver && _game.moves.isNotEmpty;
    return PopScope(
      canPop: !inProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeaveChallenge());
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    // La valutazione della patta è breve: nel frattempo la partita resta com'è.
    final evaluating = _task == _ComputerTask.draw;
    final actions = _GameActions(
      onNewGame: evaluating || _isChallenge ? null : _newGame,
      onUndo:
          !evaluating &&
              !_isChallenge &&
              (_canUndo || _pendingMove != null || _viewPly != null)
          ? _undo
          : null,
      onFlip: () => setState(() => _orientation = _orientation.opposite),
      onDraw:
          _game.isOver || _pendingMove != null || _thinking || _computerToMove
          ? null
          : _offerDraw,
      onResign: _game.isOver || _pendingMove != null || evaluating
          ? null
          : _resign,
      // Nelle sfide niente aiuti: né suggerimenti né ripetizione della mossa.
      coachOn: _computerSide == null || _isChallenge ? null : _coachOn,
      onCoach: () => setState(() => _coachOn = !_coachOn),
      onHint: _coachOn && _humanToMove && _pendingMove == null
          ? _giveHint
          : null,
    );
    // Il libro delle aperture vale solo per gli scacchi classici.
    final title = _isChallenge
        ? Text(widget.challenge!.title)
        : _game.variant == Variant.standard
        ? OpeningName(
            positions: [_game.initial, for (final m in _game.moves) m.after],
            fallback: 'Scacchi',
          )
        : Text(_title);
    return Scaffold(
      appBar: AppBar(
        title: _computerSide == null
            ? title
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  Text(
                    _bot != null
                        ? '${_bot!.avatar} ${_bot!.name} (${_bot!.elo} Elo)'
                        : 'Computer, livello $_gameLevel: '
                              '${engineLevel(_gameLevel).name}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
        actions: [
          // Stockfish analizza solo gli scacchi classici.
          if (widget.computerAvailable &&
              !_isChallenge &&
              _game.variant == Variant.standard)
            PopupMenuButton<String>(
              tooltip: 'Altre azioni',
              onSelected: (value) {
                if (value == 'review') _openReview();
                if (value == 'analysis') _openAnalysis();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'analysis',
                  enabled: _task != _ComputerTask.draw,
                  child: const Text('Analisi della posizione'),
                ),
                PopupMenuItem(
                  value: 'review',
                  enabled: _game.moves.isNotEmpty && !_thinking,
                  child: const Text('Revisione della partita'),
                ),
              ],
            ),
          if (!_isChallenge)
            IconButton(
              tooltip: 'Editor di posizione',
              icon: const Icon(Icons.edit_note),
              onPressed: _editPosition,
            ),
          IconButton(
            tooltip: 'Mossa da tastiera',
            icon: const Icon(Icons.keyboard_outlined),
            onPressed: !_humanToMove || _pendingMove != null || _viewPly != null
                ? null
                : _typeMove,
          ),
          IconButton(
            tooltip: 'Impostazioni',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape =
                  constraints.maxWidth > constraints.maxHeight * 1.2;
              final boardSize = landscape
                  ? math.min(constraints.maxHeight, constraints.maxWidth * 0.6)
                  : math.max(
                      0.0,
                      math.min(
                        constraints.maxWidth,
                        constraints.maxHeight - _portraitChromeHeight,
                      ),
                    );
              final boardSettings = _settings.board;
              final board = Chessboard(
                size: boardSize,
                controller: _board,
                orientation: _orientation,
                onMove: _onMove,
                settings: boardSettings,
              );
              final viewPly = _viewPly;
              final Widget status = viewPly != null
                  ? _ViewBar(
                      text: viewPly == -1
                          ? 'Posizione iniziale'
                          : 'Posizione dopo ${moveLabel(_game, viewPly, number: true)}',
                      onPrevious: viewPly > -1
                          ? () => _showPly(viewPly - 1)
                          : null,
                      onNext: () => _showPly(viewPly + 1),
                      onBack: () => _showPly(null),
                    )
                  : _pendingMove == null
                  ? _StatusLine(
                      game: _game,
                      nameOf: _nameOf,
                      replacement: switch (_task) {
                        _ComputerTask.none => null,
                        _ComputerTask.move => 'Il computer sta pensando…',
                        _ComputerTask.draw => 'Il computer valuta la patta…',
                      },
                    )
                  : _ConfirmBar(
                      onConfirm: _confirmPending,
                      onDiscard: _discardPending,
                    );
              final moves = _MoveList(
                game: _game,
                horizontal: !landscape,
                selected: viewPly,
                onSelect: _showPly,
              );
              final balance = MaterialBalance.of(
                viewPly == null
                    ? _game
                    : ChessGame.replay(
                            _game.initial,
                            _game.moves.take(viewPly + 1).map((m) => m.move),
                          ) ??
                          _game,
              );
              final topMaterial = _MaterialRow(
                balance: balance,
                side: _orientation.opposite,
                name: _nameOf(_orientation.opposite),
                pieceAssets: boardSettings.pieceAssets,
                clock: _clockView(_orientation.opposite),
              );
              final bottomMaterial = _MaterialRow(
                balance: balance,
                side: _orientation,
                name: _nameOf(_orientation),
                pieceAssets: boardSettings.pieceAssets,
                clock: _clockView(_orientation),
              );
              if (landscape) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    board,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          topMaterial,
                          status,
                          Expanded(child: moves),
                          bottomMaterial,
                          actions,
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: _moveStripHeight, child: moves),
                          status,
                          topMaterial,
                          board,
                          bottomMaterial,
                        ],
                      ),
                    ),
                  ),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Operazione in corso del computer.
enum _ComputerTask { none, move, draw }

const int _drawAcceptanceCp = 50;
const double _moveStripHeight = 40;
const double _statusHeight = 48;
const double _actionsHeight = 72;
const double _materialHeight = 36;
const double _portraitChromeHeight =
    _moveStripHeight + _statusHeight + _actionsHeight + 2 * _materialHeight;

String _sideName(Side side) => side == Side.white ? 'Bianco' : 'Nero';

/// "il Bianco", oppure "Anna (Bianco)" se il giocatore ha un nome.
String _player(Side side, String? Function(Side)? nameOf) {
  final name = nameOf?.call(side);
  return name == null ? 'il ${_sideName(side)}' : '$name (${_sideName(side)})';
}

String _capitalized(String s) => s[0].toUpperCase() + s.substring(1);

/// Stato della partita; [nameOf] affianca al colore il nome scelto.
String statusText(ChessGame game, [String? Function(Side)? nameOf]) {
  String player(Side side) => _player(side, nameOf);
  final named =
      nameOf?.call(Side.white) != null || nameOf?.call(Side.black) != null;

  final turn = game.position.turn;
  return switch (game.endReason) {
    null =>
      game.position.isCheck
          ? named
                ? 'Scacco. Muove ${player(turn)}.'
                : 'Scacco al ${_sideName(turn)}. Muove ${player(turn)}.'
          : 'Muove ${player(turn)}.',
    GameEndReason.checkmate => 'Scacco matto. Vince ${player(turn.opposite)}.',
    GameEndReason.resignation =>
      'Abbandono. Vince ${player(game.outcome!.winner!)}.',
    GameEndReason.stalemate => 'Stallo. Patta.',
    GameEndReason.insufficientMaterial => 'Materiale insufficiente. Patta.',
    GameEndReason.threefoldRepetition => 'Triplice ripetizione. Patta.',
    GameEndReason.fiftyMoveRule => 'Regola delle 50 mosse. Patta.',
    GameEndReason.agreement => 'Patta concordata.',
    GameEndReason.variantEnd => switch (game.variant) {
      Variant.kingOfTheHill =>
        'Re al centro. Vince il ${_sideName(game.outcome!.winner!)}.',
      Variant.threeCheck =>
        'Terzo scacco. Vince il ${_sideName(game.outcome!.winner!)}.',
      // Senza una vittoria propria della variante non si arriva qui.
      Variant.standard || Variant.chess960 => 'Partita finita.',
    },
    GameEndReason.timeout =>
      game.outcome!.winner == null
          ? 'Tempo scaduto. Patta per materiale insufficiente.'
          : 'Tempo scaduto. Vince ${player(game.outcome!.winner!)}.',
  };
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.game,
    required this.nameOf,
    this.replacement,
  });

  final ChessGame game;
  final String? Function(Side) nameOf;

  /// Testo al posto dello stato della partita.
  final String? replacement;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _statusHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            replacement ?? statusText(game, nameOf),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}

class _MoveList extends StatelessWidget {
  const _MoveList({
    required this.game,
    required this.horizontal,
    required this.selected,
    required this.onSelect,
  });

  final ChessGame game;
  final bool horizontal;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final moves = game.moves;
    final theme = Theme.of(context);
    Widget item(int i) {
      final isSelected = i == selected;
      final chip = InkWell(
        key: ValueKey('move-$i'),
        borderRadius: BorderRadius.circular(4),
        onTap: () => onSelect(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: isSelected
              ? BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Text(moveLabel(game, i), style: theme.textTheme.bodyLarge),
        ),
      );
      return isSelected ? _KeepVisible(child: chip) : chip;
    }

    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Ancorata a destra: l'ultima mossa resta visibile.
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < moves.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              item(i),
            ],
          ],
        ),
      );
    }
    return SingleChildScrollView(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [for (var i = 0; i < moves.length; i++) item(i)],
      ),
    );
  }
}

class _GameActions extends StatelessWidget {
  const _GameActions({
    required this.onNewGame,
    required this.onUndo,
    required this.onFlip,
    required this.onDraw,
    required this.onResign,
    required this.coachOn,
    required this.onCoach,
    required this.onHint,
  });

  final VoidCallback? onNewGame;
  final VoidCallback? onUndo;
  final VoidCallback onFlip;
  final VoidCallback? onDraw;
  final VoidCallback? onResign;

  /// `null` nella partita tra due persone, dove l'allenatore non c'è.
  final bool? coachOn;
  final VoidCallback onCoach;
  final VoidCallback? onHint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _actionsHeight,
      child: Row(
        children: [
          _ActionButton(Icons.add, 'Nuova', onNewGame),
          _ActionButton(Icons.undo, 'Annulla', onUndo),
          _ActionButton(Icons.swap_vert, 'Gira', onFlip),
          _ActionButton(Icons.handshake_outlined, 'Patta', onDraw),
          _ActionButton(Icons.flag_outlined, 'Abbandona', onResign),
          if (coachOn != null)
            _ActionButton(
              coachOn! ? Icons.school : Icons.school_outlined,
              'Allenatore',
              onCoach,
            ),
          if (coachOn ?? false)
            _ActionButton(Icons.lightbulb_outline, 'Aiuto', onHint),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(this.icon, this.label, this.onPressed);

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null
        ? Theme.of(context).disabledColor
        : Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            // Con sei pulsanti le etichette lunghe si rimpiccioliscono.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _roleNames = {
  Role.pawn: 'pedone',
  Role.knight: 'cavallo',
  Role.bishop: 'alfiere',
  Role.rook: 'torre',
  Role.queen: 'donna',
  Role.king: 're',
};

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.balance,
    required this.side,
    required this.name,
    required this.pieceAssets,
    this.clock,
  });

  final MaterialBalance balance;
  final Side side;
  final String? name;
  final PieceAssets pieceAssets;
  final Widget? clock;

  @override
  Widget build(BuildContext context) {
    final advantage = balance.advantage(side);
    final opponent = side.opposite;
    final captured = balance.capturedBy(side);
    final description = [
      name == null ? '${_sideName(side)}: ' : '$name, ${_sideName(side)}: ',
      captured.isEmpty
          ? 'nessun pezzo catturato'
          : 'ha catturato ${captured.map((r) => _roleNames[r]).join(', ')}',
      if (advantage > 0) ', vantaggio di $advantage',
    ].join();
    final material = Semantics(
      label: description,
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              for (final (i, role) in captured.indexed)
                Image(
                  key: ValueKey('captured-${opponent.name}-${role.name}-$i'),
                  image: pieceAssets[Piece(color: opponent, role: role).kind]!,
                  width: 20,
                  height: 20,
                ),
              if (advantage > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '+$advantage',
                  key: ValueKey('advantage-${side.name}'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return SizedBox(
      height: _materialHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (name != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                // Già letto nella descrizione del materiale.
                child: ExcludeSemantics(
                  child: Text(
                    name!,
                    key: ValueKey('player-${side.name}'),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: material),
            ?clock,
          ],
        ),
      ),
    );
  }
}

class _ClockView extends StatelessWidget {
  const _ClockView({
    required this.side,
    required this.name,
    required this.remaining,
    required this.active,
  });

  final Side side;
  final String? name;
  final Duration remaining;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final low = active && isLowTime(remaining);
    final background = low
        ? scheme.error
        : active
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final foreground = low
        ? scheme.onError
        : active
        ? scheme.onPrimary
        : scheme.onSurfaceVariant;
    return Semantics(
      label:
          '${name == null ? 'Orologio del ${_sideName(side)}' : 'Orologio di $name'}: '
          '${remaining.inMinutes} minuti e ${remaining.inSeconds % 60} secondi',
      excludeSemantics: true,
      child: Container(
        key: active ? const ValueKey('clock-active') : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          formatClock(remaining),
          key: ValueKey('clock-${side.name}'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: foreground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _TimeChoice {
  const _TimeChoice(
    this.control,
    this.variant,
    this.whiteName,
    this.blackName,
    this.setup,
  );

  final TimeControl? control;
  final Variant variant;
  final String whiteName;
  final String blackName;
  final GameSetup setup;
}

/// Scelta dell'avversario per una posizione creata con l'editor (RF-24).
class _PositionSheet extends StatefulWidget {
  const _PositionSheet({
    required this.setup,
    required this.adaptiveLevel,
    required this.collection,
  });

  final GameSetup setup;
  final int adaptiveLevel;
  final BotCollection collection;

  @override
  State<_PositionSheet> createState() => _PositionSheetState();
}

class _PositionSheetState extends State<_PositionSheet> {
  late GameSetup _setup = widget.setup;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Gioca questa posizione',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        OpponentPicker(
          setup: _setup,
          adaptiveLevel: widget.adaptiveLevel,
          collection: widget.collection,
          computerAvailable: true,
          onChanged: (setup) => setState(() => _setup = setup),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context, _setup),
          child: const Text('Gioca'),
        ),
      ],
    ),
  );
}

/// Scelta di avversario, variante, nomi e cadenza: toccare una cadenza avvia
/// la partita.
class _TimeControlSheet extends StatefulWidget {
  const _TimeControlSheet({
    required this.variant,
    required this.whiteName,
    required this.blackName,
    required this.setup,
    required this.adaptiveLevel,
    required this.collection,
    required this.computerAvailable,
  });

  final Variant variant;
  final String whiteName;
  final String blackName;
  final GameSetup setup;
  final int adaptiveLevel;
  final BotCollection collection;
  final bool computerAvailable;

  @override
  State<_TimeControlSheet> createState() => _TimeControlSheetState();
}

class _TimeControlSheetState extends State<_TimeControlSheet> {
  late Variant _variant = widget.variant;
  late GameSetup _setup = widget.computerAvailable
      ? widget.setup
      : widget.setup.copyWith(opponent: Opponent.human);
  late final _white = TextEditingController(text: widget.whiteName);
  late final _black = TextEditingController(text: widget.blackName);

  @override
  void dispose() {
    _white.dispose();
    _black.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = <String, List<TimeControl>>{};
    for (final t in TimeControl.presets) {
      groups.putIfAbsent(t.category, () => []).add(t);
    }
    Widget chip(String label, TimeControl? control) => ActionChip(
      label: Text(label),
      onPressed: () => Navigator.pop(
        context,
        _TimeChoice(control, _variant, _white.text, _black.text, _setup),
      ),
    );
    Widget nameField(TextEditingController controller, String label) =>
        Expanded(
          child: TextField(
            controller: controller,
            maxLength: AppSettings.maxNameLength,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: label,
              hintText: 'Facoltativo',
              counterText: '',
            ),
          ),
        );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text('Nuova partita', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            OpponentPicker(
              setup: _setup,
              adaptiveLevel: widget.adaptiveLevel,
              collection: widget.collection,
              computerAvailable: widget.computerAvailable,
              onChanged: (setup) => setState(() => _setup = setup),
            ),
            if (_setup.opponent == Opponent.human) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  nameField(_white, 'Nome del Bianco'),
                  const SizedBox(width: 12),
                  nameField(_black, 'Nome del Nero'),
                ],
              ),
              const SizedBox(height: 16),
              Text('Variante', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in Variant.values)
                    ChoiceChip(
                      label: Text(v.label),
                      selected: v == _variant,
                      onSelected: (_) => setState(() => _variant = v),
                    ),
                ],
              ),
              if (_variant.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(_variant.description),
              ],
            ],
            const SizedBox(height: 12),
            Text('Cadenza', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            chip('Senza tempo', null),
            for (final entry in groups.entries) ...[
              const SizedBox(height: 12),
              Text(entry.key, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final t in entry.value) chip(t.label, t)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.onConfirm, required this.onDiscard});

  final VoidCallback onConfirm;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _statusHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDiscard,
                icon: const Icon(Icons.close),
                label: const Text('Scarta'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check),
                label: const Text('Conferma'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewBar extends StatelessWidget {
  const _ViewBar({
    required this.text,
    required this.onPrevious,
    required this.onNext,
    required this.onBack,
  });

  final String text;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _statusHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Mossa precedente',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Mossa successiva',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
            TextButton(
              onPressed: onBack,
              child: const Text('Torna alla partita'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Porta il figlio nella parte visibile della lista che lo contiene.
class _KeepVisible extends StatefulWidget {
  const _KeepVisible({required this.child});

  final Widget child;

  @override
  State<_KeepVisible> createState() => _KeepVisibleState();
}

class _KeepVisibleState extends State<_KeepVisible> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 150),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MoveInputDialog extends StatefulWidget {
  const _MoveInputDialog({required this.position});

  final Position position;

  @override
  State<_MoveInputDialog> createState() => _MoveInputDialogState();
}

class _MoveInputDialogState extends State<_MoveInputDialog> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    switch (parseMoveInput(widget.position, _text.text)) {
      case MoveInputOk(:final move):
        Navigator.of(context).pop(move);
      case MoveInputAmbiguous():
        setState(() => _error = 'R è ambigua: usa K per il re, T per la torre');
      case MoveInputInvalid():
        setState(() => _error = 'Mossa non valida');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mossa da tastiera'),
      content: TextField(
        controller: _text,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'Mossa',
          hintText: 'es. e4, Cf3, Nf3, O-O, e7e8q',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        // Mantiene la tastiera aperta dopo una mossa non valida.
        onEditingComplete: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Gioca')),
      ],
    );
  }
}
