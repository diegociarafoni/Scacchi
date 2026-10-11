import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/computer_player.dart';
import '../engine/levels.dart';
import '../engine/uci_transport.dart';
import '../settings/settings.dart';
import '../settings/settings_page.dart';
import 'chess_game.dart';
import 'clock.dart';
import 'material.dart';
import 'new_game_dialog.dart';

/// Partita tra due persone sullo stesso dispositivo o contro il computer.
class GamePage extends StatefulWidget {
  GamePage({
    super.key,
    required this.settings,
    bool? computerAvailable,
    this.createComputer,
    this.now,
  }) : computerAvailable = computerAvailable ?? StockfishTransport.isSupported;

  final SettingsController settings;
  final bool computerAvailable;
  final ComputerPlayer Function()? createComputer;

  /// Ora corrente per l'orologio; quella di sistema se assente.
  final DateTime Function()? now;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  ChessGame _game = ChessGame();
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );
  Side _orientation = Side.white;
  GameSetup _setup = const GameSetup();
  final _random = math.Random();

  /// Lato giocato dal computer; `null` nella partita tra due persone.
  Side? _computerSide;
  ComputerPlayer? _computer;
  _ComputerTask _task = _ComputerTask.none;
  bool get _thinking => _task != _ComputerTask.none;

  /// Invalida le risposte del computer per posizioni non più attuali.
  int _generation = 0;
  ChessClock? _clock;
  Timer? _ticker;

  /// Snapshot dell'orologio all'inizio della riflessione del computer.
  Map<Side, Duration>? _searchClock;

  /// Sospensioni attive (finestre aperte, app in background).
  int _suspensions = 0;
  bool _clockBeforeSuspension = false;
  bool _inBackground = false;
  final List<Map<Side, Duration>> _clockHistory = [];
  final ValueNotifier<int> _tick = ValueNotifier(0);

  AppSettings get _settings => widget.settings.value;

  late bool _autoFlip;

  @override
  void initState() {
    super.initState();
    _autoFlip = _settings.autoFlip;
    widget.settings.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addObserver(this);
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
    final searchStart = _task == _ComputerTask.move ? _searchClock : null;
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
    _refresh(animate: false);
    _computerMove();
  }

  /// Mostra una finestra con orologio e computer fermi; il chiamante chiama [_resume].
  Future<T?> _suspendedDialog<T>(WidgetBuilder builder) {
    _suspend();
    return showDialog<T>(context: context, builder: builder);
  }

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
    if (_game.isOver || _thinking) return PlayerSide.none;
    return switch (_computerSide) {
      null => PlayerSide.both,
      Side.white => PlayerSide.black,
      Side.black => PlayerSide.white,
    };
  }

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

  void _refresh({bool animate = true}) {
    _syncClock();
    _board.updatePosition(_gameData(), animate: animate, resetPremove: true);
    setState(() {
      if (_settings.autoFlip && _computerSide == null) {
        _orientation = _game.position.turn;
      }
    });
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    final played = _play(move);
    if (!played && !_game.isOver) return;
    _refresh(animate: played && viaDragAndDrop != true);
    if (played) _computerMove();
  }

  /// Gioca [move] e aggiorna l'orologio; con il tempo scaduto chiude la partita.
  bool _play(Move move) {
    final clock = _clock;
    final flagged = clock?.flagged;
    if (flagged != null) {
      _game.flag(flagged);
      return false;
    }
    final before = clock?.snapshot();
    if (!_game.play(move)) return false;
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
    _searchClock = clock?.snapshot();
    var level = engineLevel(_setup.level);
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
      reply = await _computerPlayer.bestMove(
        _game.initial.fen,
        _moveHistory,
        level,
      );
    } catch (e) {
      error = e;
    }
    if (!mounted || generation != _generation) return;
    _task = _ComputerTask.none;
    if (reply == null ? !_game.isOver : !_play(reply.move) && !_game.isOver) {
      error ??= reply ?? 'nessuna mossa';
    }
    _refresh();
    if (error != null) {
      _showMessage(
        'Il computer non risponde.',
        duration: const Duration(days: 1),
        action: SnackBarAction(label: 'Riprova', onPressed: _computerMove),
      );
    }
  }

  List<Move> get _moveHistory => [for (final m in _game.moves) m.move];

  void _cancelComputerMove() {
    _generation++;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (_thinking) _computer?.stop();
    _task = _ComputerTask.none;
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
    final flagged = _clock?.flagged;
    if (flagged != null && !_game.isOver) {
      _cancelComputerMove();
      _game.flag(flagged);
      _refresh(animate: false);
    } else {
      _tick.value++;
    }
  }

  /// Chiude selezione e selettore di promozione rimasti aperti sulla scacchiera.
  void _clearBoardInteraction() {
    final pos = _game.position;
    _board.updatePosition(
      GameData(
        fen: pos.fen,
        playerSide: PlayerSide.none,
        sideToMove: pos.turn,
        validMoves: const {},
      ),
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

  Future<void> _newGame() async {
    _suspend();
    final setup = await showNewGameDialog(
      context,
      initial: _setup,
      computerAvailable: widget.computerAvailable,
    );
    if (!mounted) return;
    _resume(restart: setup == null);
    if (setup == null) return;
    _cancelComputerMove();
    _clockBeforeSuspension = false;
    _setup = setup;
    _game = ChessGame();
    final control = setup.timeControl;
    _clock = control == null ? null : ChessClock(control, now: widget.now);
    _clockHistory.clear();
    _clearBoardInteraction();
    if (setup.opponent == Opponent.computer) {
      final human = setup.resolveHumanSide(_random);
      _computerSide = human.opposite;
      _orientation = human;
      _computerPlayer.newGame().ignore();
    } else {
      _computerSide = null;
      _computer?.dispose().ignore();
      _computer = null;
    }
    _refresh(animate: false);
    _computerMove();
  }

  bool get _endedByChoice => switch (_game.endReason) {
    GameEndReason.resignation || GameEndReason.agreement => true,
    _ => false,
  };

  void _undo() {
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
    _computerMove();
  }

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
        content: Text('Abbandona il ${_sideName(side)}.'),
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
    );
    if (!mounted) return;
    _resume(restart: confirmed != true);
    if (confirmed == true) {
      _game.resign(side);
      _refresh(animate: false);
    }
  }

  /// Il computer accetta la patta solo se si valuta in svantaggio.
  Future<void> _offerDrawToComputer() async {
    if (_thinking) return;
    final generation = _generation;
    final turn = _game.position.turn;
    final clock = _clock;
    final clockStart = clock?.snapshot();
    _task = _ComputerTask.draw;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _refresh(animate: false);
    int? computerScore;
    Object? error;
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
    } catch (e) {
      error = e;
    }
    if (!mounted || generation != _generation) return;
    _task = _ComputerTask.none;
    if (clock != null && clock.isRunning && !_game.isOver) {
      clock.restore(clockStart!, clock.active);
    }
    _refresh(animate: false);
    if (_game.isOver) return;
    if (error != null) return _showMessage('Il computer non risponde.');
    if (computerScore != null && computerScore <= -_drawAcceptanceCp) {
      _cancelComputerMove();
      _game.agreeDraw();
      _refresh(animate: false);
      _showMessage('Il computer accetta la patta.');
    } else {
      _showMessage('Il computer rifiuta la patta.');
    }
  }

  Future<void> _offerDraw() async {
    if (_computerSide != null) return _offerDrawToComputer();
    final opponent = _game.position.turn.opposite;
    final accepted = await _suspendedDialog<bool>(
      (context) => AlertDialog(
        title: Text('Il ${_sideName(opponent)} accetta la patta?'),
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
    );
    if (!mounted) return;
    _resume(restart: accepted != true);
    if (accepted == true) {
      _game.agreeDraw();
      _refresh(animate: false);
    }
  }

  Widget? _clockView(Side side) {
    final clock = _clock;
    if (clock == null) return null;
    return ListenableBuilder(
      listenable: _tick,
      builder: (context, _) => _ClockView(
        side: side,
        remaining: clock.remaining(side),
        active: clock.active == side,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = _GameActions(
      onNewGame: _newGame,
      onUndo: _canUndo ? _undo : null,
      onFlip: () => setState(() => _orientation = _orientation.opposite),
      onDraw: _game.isOver || _thinking || _computerToMove ? null : _offerDraw,
      onResign: _game.isOver ? null : _resign,
    );
    return Scaffold(
      appBar: AppBar(
        title: _computerSide == null
            ? const Text('Scacchi')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scacchi'),
                  Text(
                    'Computer, livello ${_setup.level}: '
                    '${engineLevel(_setup.level).name}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: 'Impostazioni',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsPage(controller: widget.settings),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
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
            final status = _StatusLine(
              text: switch (_task) {
                _ComputerTask.none => statusText(_game),
                _ComputerTask.move => 'Il computer sta pensando…',
                _ComputerTask.draw => 'Il computer valuta la patta…',
              },
            );
            final moves = _MoveList(game: _game, horizontal: !landscape);
            final balance = MaterialBalance.of(_game);
            final topMaterial = _MaterialRow(
              balance: balance,
              side: _orientation.opposite,
              pieceAssets: boardSettings.pieceAssets,
              clock: _clockView(_orientation.opposite),
            );
            final bottomMaterial = _MaterialRow(
              balance: balance,
              side: _orientation,
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

String statusText(ChessGame game) {
  final turn = game.position.turn;
  return switch (game.endReason) {
    null =>
      game.position.isCheck
          ? 'Scacco al ${_sideName(turn)}. Muove il ${_sideName(turn)}.'
          : 'Muove il ${_sideName(turn)}.',
    GameEndReason.checkmate =>
      'Scacco matto. Vince il ${_sideName(turn.opposite)}.',
    GameEndReason.resignation =>
      'Abbandono. Vince il ${_sideName(game.outcome!.winner!)}.',
    GameEndReason.stalemate => 'Stallo. Patta.',
    GameEndReason.insufficientMaterial => 'Materiale insufficiente. Patta.',
    GameEndReason.threefoldRepetition => 'Triplice ripetizione. Patta.',
    GameEndReason.fiftyMoveRule => 'Regola delle 50 mosse. Patta.',
    GameEndReason.agreement => 'Patta concordata.',
    GameEndReason.timeout =>
      game.outcome!.winner == null
          ? 'Tempo scaduto. Patta per materiale insufficiente.'
          : 'Tempo scaduto. Vince il ${_sideName(game.outcome!.winner!)}.',
  };
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _statusHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}

class _MoveList extends StatelessWidget {
  const _MoveList({required this.game, required this.horizontal});

  final ChessGame game;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final moves = game.moves;
    final items = [
      for (var i = 0; i < moves.length; i++)
        i.isEven ? '${i ~/ 2 + 1}. ${moves[i].san}' : moves[i].san,
    ];
    final style = Theme.of(context).textTheme.bodyLarge;
    if (horizontal) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        // Ordine inverso: l'ultima mossa resta visibile.
        itemBuilder: (context, i) =>
            Center(child: Text(items[items.length - 1 - i], style: style)),
      );
    }
    return SingleChildScrollView(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(items.join('  '), style: style),
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
  });

  final VoidCallback onNewGame;
  final VoidCallback? onUndo;
  final VoidCallback onFlip;
  final VoidCallback? onDraw;
  final VoidCallback? onResign;

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
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: color),
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
    required this.pieceAssets,
    this.clock,
  });

  final MaterialBalance balance;
  final Side side;
  final PieceAssets pieceAssets;
  final Widget? clock;

  @override
  Widget build(BuildContext context) {
    final advantage = balance.advantage(side);
    final opponent = side.opposite;
    final captured = balance.capturedBy(side);
    final description = [
      '${_sideName(side)}: ',
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
    required this.remaining,
    required this.active,
  });

  final Side side;
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
          'Orologio del ${_sideName(side)}: '
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
