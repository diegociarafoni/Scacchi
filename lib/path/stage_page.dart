import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'curriculum.dart';
import 'exercise.dart';

/// Svolge gli esercizi di una tappa e restituisce con `Navigator.pop` le
/// stelle ottenute (media arrotondata per difetto).
class StagePage extends StatefulWidget {
  const StagePage({super.key, required this.stage});

  final Stage stage;

  @override
  State<StagePage> createState() => _StagePageState();
}

class _StagePageState extends State<StagePage> {
  int _index = 0;
  final List<int> _stars = [];
  late ExerciseRun _run = ExerciseRun.start(widget.stage.exercises[0]);
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );
  String? _feedback;

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  Exercise get _exercise => widget.stage.exercises[_index];

  bool get _finished => _stars.length == widget.stage.exercises.length;

  GameData _gameData({Move? lastMove}) {
    switch (_run) {
      case final StarsRun run:
        final board = Board.empty.setPieceAt(
          run.square,
          Piece(color: Side.white, role: run.role),
        );
        return GameData(
          fen: '${board.fen} w - - 0 1',
          lastMove: lastMove,
          playerSide: run.done ? PlayerSide.none : PlayerSide.white,
          sideToMove: Side.white,
          validMoves: {run.square: run.validMoves},
        );
      case final LineRun run:
        final pos = run.position;
        return GameData(
          fen: pos.fen,
          lastMove: lastMove,
          playerSide: run.done ? PlayerSide.none : PlayerSide.white,
          sideToMove: pos.turn,
          kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
          validMoves: makeLegalMoves(pos),
        );
    }
  }

  Map<Square, Annotation> get _annotations => switch (_run) {
    final StarsRun run => {
      for (final s in run.remaining)
        s: const Annotation(symbol: '★', color: Color(0xFFF2B01E)),
    },
    LineRun() => const {},
  };

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    final animate = viaDragAndDrop != true;
    switch (_run) {
      case final StarsRun run:
        if (move is NormalMove) run.move(move.to);
        _board.updatePosition(_gameData(lastMove: move), animate: animate);
        if (run.done) _solved(run.stars);
        setState(() {});
      case final LineRun run:
        final verdict = run.play(move);
        switch (verdict) {
          case MoveVerdict.wrong:
            _board.updatePosition(_gameData(), animate: false);
            setState(() => _feedback = 'Non è la mossa giusta, riprova.');
          case MoveVerdict.correct:
            _board.updatePosition(_gameData(lastMove: run.lastReply));
            setState(() => _feedback = 'Bene, continua.');
          case MoveVerdict.solved:
            _board.updatePosition(_gameData(lastMove: move), animate: animate);
            _solved(run.stars);
            setState(() => _feedback = 'Esatto!');
        }
    }
  }

  void _solved(int stars) => _stars.add(stars);

  void _next() {
    setState(() {
      _index++;
      _run = ExerciseRun.start(_exercise);
      _feedback = null;
    });
    _board.updatePosition(_gameData(), animate: false);
  }

  int get _stageStars =>
      (_stars.fold(0, (a, b) => a + b) / _stars.length).floor();

  @override
  Widget build(BuildContext context) {
    final solved = _stars.length > _index;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stage.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _stars.length / widget.stage.exercises.length,
            semanticsLabel:
                'Esercizio ${_index + 1} di ${widget.stage.exercises.length}',
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(
              constraints.maxWidth,
              constraints.maxHeight - 200,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_exercise.instructions, style: text.titleMedium),
                ),
                Center(
                  child: Chessboard(
                    size: size,
                    controller: _board,
                    orientation: Side.white,
                    onMove: _onMove,
                    annotations: _annotations,
                    settings: const ChessboardSettings(
                      colorScheme: ChessboardColorScheme.green,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_feedback != null)
                  Text(
                    _feedback!,
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _finished
                      ? _Result(stars: _stageStars)
                      : FilledButton(
                          onPressed: solved ? _next : null,
                          child: const Text('Avanti'),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Tappa completata', style: Theme.of(context).textTheme.titleLarge),
        Text(
          '${'★' * stars}${'☆' * (3 - stars)}',
          semanticsLabel: '$stars stelle su 3',
          style: TextStyle(
            fontSize: 32,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.pop(context, stars),
          child: const Text('Fine'),
        ),
      ],
    );
  }
}
