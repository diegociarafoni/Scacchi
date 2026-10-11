import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'board_layout.dart';
import 'capture_all.dart';
import 'minigame.dart';

/// "Cattura tutto": cinque scacchiere in cui un solo pezzo cattura i pedoni.
class CaptureAllPage extends StatefulWidget {
  const CaptureAllPage({
    super.key,
    required this.random,
    required this.onFinished,
  });

  final Random random;

  /// Chiamata con il totale delle stelle a fine sessione.
  final ValueChanged<MinigameResult> onFinished;

  @override
  State<CaptureAllPage> createState() => _CaptureAllPageState();
}

class _CaptureAllPageState extends State<CaptureAllPage> {
  late CaptureAllSession _session = CaptureAllSession(widget.random);
  final _clock = Stopwatch()..start();
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );

  CaptureAllRun get _run => _session.run;

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  GameData _gameData({Move? lastMove}) {
    var board = Board.empty.setPieceAt(
      _run.square,
      Piece(color: Side.white, role: _run.board.role),
    );
    for (final s in _run.remaining) {
      board = board.setPieceAt(
        s,
        const Piece(color: Side.black, role: Role.pawn),
      );
    }
    return GameData(
      fen: '${board.fen} w - - 0 1',
      lastMove: lastMove,
      playerSide: _run.done ? PlayerSide.none : PlayerSide.white,
      sideToMove: Side.white,
      validMoves: {_run.square: _run.validMoves},
    );
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    if (move is NormalMove) _run.move(move.to);
    _board.updatePosition(
      _gameData(lastMove: move),
      animate: viaDragAndDrop != true,
    );
    setState(() {});
  }

  void _retry() {
    setState(
      () => _session.run = CaptureAllRun(
        _run.board,
        optimalMoves: _run.optimalMoves,
      ),
    );
    _board.updatePosition(_gameData(), animate: false);
  }

  void _next() {
    setState(() => _session.finishRound(_run.stars));
    if (_session.done) {
      widget.onFinished((score: _session.score, duration: _clock.elapsed));
    } else {
      _board.updatePosition(_gameData(), animate: false);
    }
  }

  void _again() {
    setState(() => _session = CaptureAllSession(widget.random));
    _clock.reset();
    _board.updatePosition(_gameData(), animate: false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final run = _run;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cattura tutto'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _session.round / CaptureAllSession.rounds,
            semanticsLabel:
                'Scacchiera ${min(_session.round + 1, CaptureAllSession.rounds)} '
                'di ${CaptureAllSession.rounds}',
          ),
        ),
      ),
      body: BoardLayout(
        board: (size) => Chessboard(
          size: size,
          controller: _board,
          orientation: Side.white,
          onMove: _onMove,
          settings: const ChessboardSettings(
            colorScheme: ChessboardColorScheme.green,
          ),
        ),
        panel: _session.done
            ? Column(
                children: [
                  Text('Sessione finita', style: text.titleLarge),
                  Text(
                    '${_session.score} stelle su ${CaptureAllSession.maxScore}',
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _again, child: const Text('Ancora')),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fine'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(run.board.instructions, style: text.titleMedium),
                  Text(
                    'Mosse ${run.moves}, minimo ${run.optimalMoves}',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (run.done) ...[
                    Text(
                      '${'★' * run.stars}${'☆' * (3 - run.stars)}',
                      semanticsLabel: '${run.stars} stelle su 3',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    FilledButton(onPressed: _next, child: const Text('Avanti')),
                  ],
                  TextButton(
                    onPressed: _retry,
                    child: const Text('Ricomincia'),
                  ),
                ],
              ),
      ),
    );
  }
}
