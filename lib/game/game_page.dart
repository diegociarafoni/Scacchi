import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/computer_player.dart';
import '../engine/levels.dart';
import '../engine/uci.dart';
import '../engine/uci_transport.dart';
import '../review/engine_evaluator.dart';
import '../review/review_page.dart';
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

  /// Valutazione dell'ultima mossa del computer, dal suo punto di vista.
  EngineScore? _computerScore;

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
    _thinking = true;
    _refresh(animate: false);
    EngineMove? reply;
    Object? error;
    try {
      reply = await _computerPlayer.bestMove(
        _game.position.fen,
        engineLevel(_setup.level),
      );
    } catch (e) {
      error = e;
    }
    if (!mounted || generation != _generation) return;
    _thinking = false;
    if (reply != null) {
      _computerScore = reply.score;
      _game.play(reply.move);
    }
    _refresh();
    if (error != null) _showMessage('Il computer non risponde. Riprova.');
  }

  void _cancelComputerMove() {
    _generation++;
    if (_thinking) _computer?.stop();
    _thinking = false;
  }

  void _showMessage(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

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
    _computerScore = null;
    if (setup.opponent == Opponent.computer) {
      final human = setup.resolveHumanSide(_random);
      _computerSide = human.opposite;
      _orientation = human;
      _computerPlayer.newGame().ignore();
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

  bool get _canUndo {
    if (!_game.canUndo) return false;
    if (_computerSide != Side.white) return true;
    return _game.moves.length > 1;
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

  /// Il computer accetta la patta solo se si valuta in svantaggio.
  void _offerDrawToComputer() {
    final score = _computerScore?.comparable ?? 0;
    if (score <= -_drawAcceptanceCp) {
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
    final accepted = await showDialog<bool>(
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
    );
    if (accepted == true) {
      _game.agreeDraw();
      _refresh(animate: false);
    }
  }

  void _openReview() {
    final player = _computerPlayer;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewPage(
          initial: _game.initial,
          moves: [for (final m in _game.moves) m.move],
          evaluate: engineEvaluator(player),
          onCancel: player.stop,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = _GameActions(
      onNewGame: _newGame,
      onUndo: _canUndo ? _undo : null,
      onFlip: () => setState(() => _orientation = _orientation.opposite),
      onDraw: _game.isOver || _thinking ? null : _offerDraw,
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'autoflip') {
                setState(() => _autoFlip = !_autoFlip);
                if (_autoFlip) _refresh(animate: false);
              }
              if (value == 'review') _openReview();
            },
            itemBuilder: (context) => [
              if (widget.computerAvailable)
                PopupMenuItem(
                  value: 'review',
                  enabled: _game.moves.isNotEmpty && !_thinking,
                  child: const Text('Revisione della partita'),
                ),
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
            final landscape =
                constraints.maxWidth > constraints.maxHeight * 1.2;
            final boardSize = landscape
                ? math.min(constraints.maxHeight, constraints.maxWidth * 0.6)
                : math.min(
                    constraints.maxWidth,
                    constraints.maxHeight - _portraitChromeHeight,
                  );
            final board = Chessboard(
              size: boardSize,
              controller: _board,
              orientation: _orientation,
              onMove: _onMove,
              settings: const ChessboardSettings(
                colorScheme: ChessboardColorScheme.green,
              ),
            );
            final status = _StatusLine(
              text: _thinking ? 'Il computer sta pensando…' : statusText(_game),
            );
            final moves = _MoveList(game: _game, horizontal: !landscape);
            if (landscape) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  board,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        status,
                        Expanded(child: moves),
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
                        board,
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

const int _drawAcceptanceCp = 50;
const double _moveStripHeight = 40;
const double _statusHeight = 48;
const double _actionsHeight = 72;
const double _portraitChromeHeight =
    _moveStripHeight + _statusHeight + _actionsHeight;

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
