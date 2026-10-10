import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'chess_game.dart';

/// Partita tra due persone sullo stesso dispositivo.
class GamePage extends StatefulWidget {
  const GamePage({super.key});

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

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
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
    _board.updatePosition(_gameData(), animate: animate, resetPremove: true);
    setState(() {
      if (_autoFlip) _orientation = _game.position.turn;
    });
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    if (_game.play(move)) _refresh(animate: viaDragAndDrop != true);
  }

  void _newGame() {
    _game = ChessGame();
    _refresh(animate: false);
  }

  void _undo() {
    _game.undo();
    _refresh(animate: false);
  }

  Future<void> _resign() async {
    final side = _game.position.turn;
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
      _game.resign(side);
      _refresh(animate: false);
    }
  }

  Future<void> _offerDraw() async {
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
        title: const Text('Scacchi'),
        actions: [
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
            final status = _StatusLine(game: _game);
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
