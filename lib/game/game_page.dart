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
              onNewGame: _newGame,
              onUndo: _game.canUndo ? _undo : null,
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
    required this.onNewGame,
    required this.onUndo,
    required this.onResign,
  });

  final ChessGame game;
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
          Text(statusText(game), style: theme.textTheme.titleMedium),
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
