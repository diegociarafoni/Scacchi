import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.minigamesCaptureAllTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _session.round / CaptureAllSession.rounds,
            semanticsLabel: l10n.minigamesCaptureAllProgress(
              min(_session.round + 1, CaptureAllSession.rounds),
              CaptureAllSession.rounds,
            ),
          ),
        ),
      ),
      body: BoardLayout(
        board: (size) => Chessboard(
          size: size,
          controller: _board,
          orientation: Side.white,
          onMove: _onMove,
          settings: AppSettings.of(context).board,
        ),
        panel: _session.done
            ? Column(
                children: [
                  Text(
                    l10n.minigamesCaptureAllSessionOver,
                    style: text.titleLarge,
                  ),
                  Text(
                    l10n.minigamesCaptureAllScore(
                      _session.score,
                      CaptureAllSession.maxScore,
                    ),
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _again,
                    child: Text(l10n.minigamesAgain),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.minigamesDone),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(run.board.instructions, style: text.titleMedium),
                  Text(
                    l10n.minigamesCaptureAllMoves(run.moves, run.optimalMoves),
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (run.done) ...[
                    Text(
                      '${'★' * run.stars}${'☆' * (3 - run.stars)}',
                      semanticsLabel: l10n.minigamesCaptureAllStars(run.stars),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    FilledButton(
                      onPressed: _next,
                      child: Text(l10n.minigamesNext),
                    ),
                  ],
                  TextButton(
                    onPressed: _retry,
                    child: Text(l10n.minigamesCaptureAllRetry),
                  ),
                ],
              ),
      ),
    );
  }
}
