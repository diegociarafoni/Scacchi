import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/computer_player.dart';
import '../engine/levels.dart';
import '../engine/uci_transport.dart';
import 'chess_game.dart';
import 'new_game_dialog.dart';

/// Partita tra due persone sullo stesso dispositivo o contro il computer.
class GamePage extends StatefulWidget {
  GamePage({super.key, bool? computerAvailable, this.createComputer})
    : computerAvailable = computerAvailable ?? StockfishTransport.isSupported;

  final bool computerAvailable;
  final ComputerPlayer Function()? createComputer;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  ChessGame _game = ChessGame();
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );
  Side _orientation = Side.white;
  bool _autoFlip = false;
  GameSetup _setup = const GameSetup();
  final _random = math.Random();

  /// Lato giocato dal computer; `null` nella partita tra due persone.
  Side? _computerSide;
  ComputerPlayer? _computer;
  bool _thinking = false;

  /// Invalida le risposte del computer per posizioni non più attuali.
  int _generation = 0;

  @override
  void dispose() {
    _generation++;
    _computer?.dispose();
    _board.dispose();
    super.dispose();
  }

  PlayerSide get _playerSide {
    if (_game.isOver || _thinking) return PlayerSide.none;
    return switch (_computerSide) {
      null => PlayerSide.both,
      Side.white => PlayerSide.black,
      Side.black => PlayerSide.white,
    };
  }

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
    _board.updatePosition(_gameData(), animate: animate, resetPremove: true);
    setState(() {
      if (_autoFlip && _computerSide == null) {
        _orientation = _game.position.turn;
      }
    });
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    if (!_game.play(move)) return;
    _refresh(animate: viaDragAndDrop != true);
    _computerMove();
  }

  Future<void> _computerMove() async {
    final side = _computerSide;
    if (side == null || _game.isOver || _game.position.turn != side) return;
    final generation = _generation;
    final computer = _computer ??=
        widget.createComputer?.call() ?? ComputerPlayer();
    setState(() => _thinking = true);
    _refresh(animate: false);
    EngineMove? reply;
    Object? error;
    try {
      reply = await computer.bestMove(
        _game.position.fen,
        engineLevel(_setup.level),
      );
    } catch (e) {
      error = e;
    }
    if (!mounted || generation != _generation) return;
    _thinking = false;
    if (reply != null) _game.play(reply.move);
    _refresh();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il computer non risponde. Riprova.')),
      );
    }
  }

  void _cancelComputerMove() {
    _generation++;
    if (_thinking) _computer?.stop();
    _thinking = false;
  }

  Future<void> _newGame() async {
    final setup = await showNewGameDialog(
      context,
      initial: _setup,
      computerAvailable: widget.computerAvailable,
    );
    if (setup == null || !mounted) return;
    _cancelComputerMove();
    _setup = setup;
    _game = ChessGame();
    if (setup.opponent == Opponent.computer) {
      final human = setup.resolveHumanSide(_random);
      _computerSide = human.opposite;
      _orientation = human;
      _computer ??= widget.createComputer?.call() ?? ComputerPlayer();
      _computer!.newGame().ignore();
    } else {
      _computerSide = null;
    }
    _refresh(animate: false);
    _computerMove();
  }

  void _undo() {
    _cancelComputerMove();
    _game.undo();
    if (_computerSide == _game.position.turn && _game.canUndo) _game.undo();
    _refresh(animate: false);
    _computerMove();
  }

  Future<void> _resign() async {
    final side = _computerSide?.opposite ?? _game.position.turn;
    final confirmed = await showDialog<bool>(
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
    );
    if (confirmed == true) {
      _cancelComputerMove();
      _game.resign(side);
      _refresh(animate: false);
    }
  }

  bool get _canUndo {
    if (!_game.canUndo) return false;
    if (_computerSide != Side.white) return true;
    return _game.moves.length > 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scacchi'),
        actions: [
          IconButton(
            tooltip: 'Gira la scacchiera',
            icon: const Icon(Icons.swap_vert),
            onPressed: () =>
                setState(() => _orientation = _orientation.opposite),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'autoflip') {
                setState(() => _autoFlip = !_autoFlip);
                if (_autoFlip) _refresh(animate: false);
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'autoflip',
                checked: _autoFlip,
                child: const Text('Ruota a ogni turno'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final boardSize = landscape
                ? math.min(constraints.maxHeight, constraints.maxWidth * 0.6)
                : math.min(constraints.maxWidth, constraints.maxHeight * 0.7);
            final board = Chessboard(
              size: boardSize,
              controller: _board,
              orientation: _orientation,
              onMove: _onMove,
              settings: const ChessboardSettings(
                colorScheme: ChessboardColorScheme.green,
              ),
            );
            final panel = _SidePanel(
              game: _game,
              status: _thinking
                  ? 'Il computer sta pensando…'
                  : statusText(_game),
              opponent: _computerSide == null
                  ? null
                  : 'Contro il computer, livello ${_setup.level}: '
                        '${engineLevel(_setup.level).name}',
              onNewGame: _newGame,
              onUndo: _canUndo ? _undo : null,
              onResign: _game.isOver ? null : _resign,
            );
            return landscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      board,
                      Expanded(child: panel),
                    ],
                  )
                : Column(
                    children: [
                      board,
                      Expanded(child: panel),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

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
  };
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.game,
    required this.status,
    required this.opponent,
    required this.onNewGame,
    required this.onUndo,
    required this.onResign,
  });

  final ChessGame game;
  final String status;
  final String? opponent;
  final VoidCallback onNewGame;
  final VoidCallback? onUndo;
  final VoidCallback? onResign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moves = game.moves;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (opponent != null)
            Text(opponent!, style: theme.textTheme.labelMedium),
          Text(status, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onNewGame,
                icon: const Icon(Icons.refresh),
                label: const Text('Nuova partita'),
              ),
              OutlinedButton.icon(
                onPressed: onUndo,
                icon: const Icon(Icons.undo),
                label: const Text('Annulla mossa'),
              ),
              OutlinedButton.icon(
                onPressed: onResign,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Abbandona'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                [
                  for (var i = 0; i < moves.length; i += 2)
                    '${i ~/ 2 + 1}. ${moves[i].san}'
                        '${i + 1 < moves.length ? ' ${moves[i + 1].san}' : ''}',
                ].join('   '),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
