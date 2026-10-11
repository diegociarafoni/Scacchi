import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../openings/opening_name.dart';
import '../settings/settings.dart';
import '../settings/settings_page.dart';
import 'chess_game.dart';
import 'clock.dart';
import 'material.dart';
import 'sounds.dart';

/// Partita tra due persone sullo stesso dispositivo.
class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  ChessGame _game = ChessGame();
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );
  Side _orientation = Side.white;
  ChessClock? _clock;
  Timer? _ticker;
  Side? _pausedInBackground;
  final List<Map<Side, Duration>> _clockHistory = [];
  final ValueNotifier<int> _tick = ValueNotifier(0);
  final SoundPlayer _sounds = SoundPlayer();
  final LowTimeAlarm _lowTime = LowTimeAlarm();

  AppSettings get _settings => widget.settings.value;

  late bool _autoFlip = _settings.autoFlip;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final clock = _clock;
    if (clock == null) return;
    if (state == AppLifecycleState.resumed) {
      final side = _pausedInBackground;
      _pausedInBackground = null;
      if (side != null && !_game.isOver) clock.start(side);
      _syncClock();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (clock.isRunning) {
        _pausedInBackground = clock.active;
        clock.pause();
      }
    }
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
      if (turnedOn) _orientation = _game.position.turn;
    });
  }

  GameData _gameData() {
    final pos = _game.position;
    return GameData(
      fen: pos.fen,
      lastMove: _game.lastMove,
      playerSide: _game.isOver ? PlayerSide.none : PlayerSide.both,
      sideToMove: pos.turn,
      kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
      validMoves: makeLegalMoves(pos),
    );
  }

  void _refresh({bool animate = true}) {
    _syncClock();
    _board.updatePosition(_gameData(), animate: animate, resetPremove: true);
    setState(() {
      if (_settings.autoFlip) _orientation = _game.position.turn;
    });
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    final clock = _clock;
    final flagged = clock?.flagged;
    if (flagged != null) {
      _game.flag(flagged);
      _play(GameSound.gameEnd);
      _refresh(animate: false);
      return;
    }
    final before = clock?.snapshot();
    final position = _game.position;
    if (!_game.play(move)) return;
    final sound = soundForLastMove(_game, position);
    if (sound != null) _play(sound);
    if (clock != null) {
      _clockHistory.add(before!);
      if (clock.isRunning) {
        clock.switchAfterMove();
      } else {
        clock.start(_game.position.turn);
      }
    }
    _refresh(animate: viaDragAndDrop != true);
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
      _game.flag(flagged);
      _play(GameSound.gameEnd);
      _refresh(animate: false);
      return;
    }
    final active = clock?.active;
    if (active != null && _lowTime.check(active, clock!.remaining(active))) {
      _play(GameSound.lowTime);
    }
    _tick.value++;
  }

  void _play(GameSound sound) {
    final s = _settings;
    _sounds.play(sound, enabled: s.sound, volume: s.volume, haptics: s.haptics);
  }

  /// Esegue [action] con l'orologio fermo, poi lo riavvia se la partita continua.
  Future<T> _withClockPaused<T>(Future<T> Function() action) async {
    final clock = _clock;
    final side = clock?.active;
    clock?.pause();
    try {
      return await action();
    } finally {
      if (mounted &&
          side != null &&
          identical(clock, _clock) &&
          !_game.isOver) {
        clock!.start(side);
        _syncClock();
      }
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

  Future<void> _newGame() async {
    final choice = await _withClockPaused(
      () => showModalBottomSheet<_TimeChoice>(
        context: context,
        builder: (context) => const _TimeControlSheet(),
      ),
    );
    if (!mounted || choice == null) return;
    _game = ChessGame();
    _clock = choice.control == null ? null : ChessClock(choice.control!);
    _clockHistory.clear();
    _lowTime.reset();
    _clearBoardInteraction();
    _refresh(animate: false);
  }

  void _undo() {
    final clock = _clock;
    final timedOut = _game.endReason == GameEndReason.timeout;
    final revokesOnly = const {
      GameEndReason.resignation,
      GameEndReason.agreement,
    }.contains(_game.endReason);
    _game.undo();
    if (timedOut) _game.undo();
    if (clock != null && !revokesOnly) {
      final before = _clockHistory.isEmpty ? null : _clockHistory.removeLast();
      if (before != null) {
        clock.restore(before, _game.moves.isEmpty ? null : _game.position.turn);
      }
    } else if (clock != null && revokesOnly && _game.moves.isNotEmpty) {
      clock.start(_game.position.turn);
    }
    _clearBoardInteraction();
    _refresh(animate: false);
  }

  Future<void> _resign() async {
    final side = _game.position.turn;
    final confirmed = await _withClockPaused(
      () => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
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
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      _game.resign(side);
      _play(GameSound.gameEnd);
      _refresh(animate: false);
    }
  }

  Future<void> _offerDraw() async {
    final opponent = _game.position.turn.opposite;
    final accepted = await _withClockPaused(
      () => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
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
      ),
    );
    if (!mounted) return;
    if (accepted == true) {
      _game.agreeDraw();
      _play(GameSound.gameEnd);
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
      onUndo: _game.canUndo ? _undo : null,
      onFlip: () => setState(() => _orientation = _orientation.opposite),
      onDraw: _game.isOver ? null : _offerDraw,
      onResign: _game.isOver ? null : _resign,
    );
    return Scaffold(
      appBar: AppBar(
        title: OpeningName(
          positions: [_game.initial, for (final m in _game.moves) m.after],
          fallback: 'Scacchi',
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
            final status = _StatusLine(game: _game);
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
  const _StatusLine({required this.game});

  final ChessGame game;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _statusHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            statusText(game),
            style: Theme.of(context).textTheme.titleMedium,
          ),
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

class _TimeChoice {
  const _TimeChoice(this.control);

  final TimeControl? control;
}

class _TimeControlSheet extends StatelessWidget {
  const _TimeControlSheet();

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<TimeControl>>{};
    for (final t in TimeControl.presets) {
      groups.putIfAbsent(t.category, () => []).add(t);
    }
    Widget chip(String label, TimeControl? control) => ActionChip(
      label: Text(label),
      onPressed: () => Navigator.pop(context, _TimeChoice(control)),
    );
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text('Nuova partita', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          chip('Senza tempo', null),
          for (final entry in groups.entries) ...[
            const SizedBox(height: 12),
            Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final t in entry.value) chip(t.label, t)],
            ),
          ],
        ],
      ),
    );
  }
}
