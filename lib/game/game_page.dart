import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../editor/position_editor_page.dart';
import '../openings/opening_name.dart';
import '../settings/settings.dart';
import '../settings/settings_page.dart';
import 'chess_game.dart';
import 'clock.dart';
import 'material.dart';
import 'move_label.dart';
import 'sounds.dart';
import 'variant.dart';

/// Partita tra due persone sullo stesso dispositivo.
class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.settings,
    this.chess960Id = randomChess960Id,
  });

  final SettingsController settings;

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
  ChessClock? _clock;
  Timer? _ticker;
  Side? _pausedInBackground;
  final List<Map<Side, Duration>> _clockHistory = [];
  final ValueNotifier<int> _tick = ValueNotifier(0);
  final SoundPlayer _sounds = SoundPlayer();
  final LowTimeAlarm _lowTime = LowTimeAlarm();
  Move? _pendingMove;

  /// Semimossa visualizzata (-1 = posizione iniziale), null = partita in corso.
  int? _viewPly;

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

  /// Posizione da mostrare senza poter muovere.
  GameData _staticData(Position pos, Move? lastMove) => GameData(
    fen: pos.fen,
    lastMove: lastMove,
    playerSide: PlayerSide.none,
    sideToMove: pos.turn,
    kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
    validMoves: const {},
  );

  void _refresh({bool animate = true}) {
    _pendingMove = null;
    _viewPly = null;
    _syncClock();
    _board.updatePosition(_gameData(), animate: animate, resetPremove: true);
    setState(() {
      if (_settings.autoFlip) _orientation = _game.position.turn;
    });
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    if (!_settings.confirmMove) {
      _commitMove(move, animate: viaDragAndDrop != true);
      return;
    }
    if (!_game.position.isLegal(move)) return;
    final preview = _game.position.play(move);
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
    _refresh(animate: animate);
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
    _board.updatePosition(
      _staticData(_game.position, _game.lastMove),
      animate: false,
    );
  }

  Future<void> _newGame() async {
    final choice = await _withClockPaused(
      () => showModalBottomSheet<_TimeChoice>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _TimeControlSheet(variant: _game.variant),
      ),
    );
    if (!mounted || choice == null) return;
    final variant = choice.variant;
    _game = ChessGame(
      initial: initialPosition(
        variant,
        chess960Id: variant == Variant.chess960 ? widget.chess960Id() : null,
      ),
      variant: variant,
    );
    _clock = choice.control == null ? null : ChessClock(choice.control!);
    _clockHistory.clear();
    _lowTime.reset();
    _clearBoardInteraction();
    _refresh(animate: false);
  }

  /// Apre l'editor sulla posizione mostrata e gioca senza orologio quella scelta.
  Future<void> _editPosition() async {
    final ply = _viewPly;
    final shown = ply == null
        ? _game.position
        : ply == -1
        ? _game.initial
        : _game.moves[ply].after;
    final position = await _withClockPaused(
      () => Navigator.of(context).push<Position>(
        MaterialPageRoute(
          builder: (_) => PositionEditorPage(
            initialFen: _game.variant == Variant.standard ? shown.fen : null,
          ),
        ),
      ),
    );
    if (!mounted || position == null) return;
    _game = ChessGame(initial: position);
    _clock = null;
    _viewPly = null;
    _pendingMove = null;
    _clockHistory.clear();
    _lowTime.reset();
    _clearBoardInteraction();
    _refresh(animate: false);
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

  void _undo() {
    if (_viewPly != null) {
      _showPly(null);
      return;
    }
    if (_pendingMove != null) {
      _discardPending();
      return;
    }
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
      onUndo: _game.canUndo || _pendingMove != null || _viewPly != null
          ? _undo
          : null,
      onFlip: () => setState(() => _orientation = _orientation.opposite),
      onDraw: _game.isOver || _pendingMove != null ? null : _offerDraw,
      onResign: _game.isOver || _pendingMove != null ? null : _resign,
    );
    return Scaffold(
      appBar: AppBar(
        // Il libro delle aperture vale solo per gli scacchi classici.
        title: _game.variant == Variant.standard
            ? OpeningName(
                positions: [
                  _game.initial,
                  for (final m in _game.moves) m.after,
                ],
                fallback: 'Scacchi',
              )
            : Text(_title),
        actions: [
          IconButton(
            tooltip: 'Editor di posizione',
            icon: const Icon(Icons.edit_note),
            onPressed: _editPosition,
          ),
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
                  ? _StatusLine(game: _game)
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
  const _TimeChoice(this.control, this.variant);

  final TimeControl? control;
  final Variant variant;
}

/// Scelta di variante e cadenza: toccare una cadenza avvia la partita.
class _TimeControlSheet extends StatefulWidget {
  const _TimeControlSheet({required this.variant});

  final Variant variant;

  @override
  State<_TimeControlSheet> createState() => _TimeControlSheetState();
}

class _TimeControlSheetState extends State<_TimeControlSheet> {
  late Variant _variant = widget.variant;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<TimeControl>>{};
    for (final t in TimeControl.presets) {
      groups.putIfAbsent(t.category, () => []).add(t);
    }
    Widget chip(String label, TimeControl? control) => ActionChip(
      label: Text(label),
      onPressed: () => Navigator.pop(context, _TimeChoice(control, _variant)),
    );
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text('Nuova partita', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('Variante', style: Theme.of(context).textTheme.titleSmall),
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
          const SizedBox(height: 12),
          Text('Cadenza', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
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
