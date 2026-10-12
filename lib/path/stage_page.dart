import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../settings/settings.dart';
import '../theme/rokko_theme.dart';
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

  /// La spiegazione della tappa precede il primo esercizio.
  late bool _started = widget.stage.intro == null;

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  Exercise get _exercise => widget.stage.exercises[_index];

  bool get _finished => _stars.length == widget.stage.exercises.length;

  GameData _gameData({Move? lastMove}) {
    final side = _run.done || !_started ? PlayerSide.none : PlayerSide.white;
    switch (_run) {
      case final StarsRun run:
        final board = Board.empty.setPieceAt(
          run.square,
          Piece(color: Side.white, role: run.role),
        );
        return GameData(
          fen: '${board.fen} w - - 0 1',
          lastMove: lastMove,
          playerSide: side,
          sideToMove: Side.white,
          validMoves: {run.square: run.validMoves},
        );
      case final LineRun run:
        final pos = run.position;
        return GameData(
          fen: pos.fen,
          lastMove: lastMove,
          playerSide: side,
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

  void _start() {
    setState(() => _started = true);
    _board.updatePosition(_gameData(), animate: false);
  }

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
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final size = math.max(
              0.0,
              landscape
                  ? constraints.maxHeight
                  : math.min(
                      constraints.maxWidth,
                      constraints.maxHeight - _portraitReserve,
                    ),
            );
            final board = Chessboard(
              size: size,
              controller: _board,
              orientation: Side.white,
              onMove: _onMove,
              annotations: _annotations,
              settings: AppSettings.of(context).exerciseBoard
                  .copyWith(autoQueenPromotion: true),
            );
            final panel = SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: !_started
                    ? [
                        Text(widget.stage.intro!, style: text.titleMedium),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _start,
                          child: const Text('Inizia'),
                        ),
                      ]
                    : [
                        Text(_exercise.instructions, style: text.titleMedium),
                        const SizedBox(height: 12),
                        if (_feedback != null)
                          Text(
                            _feedback!,
                            textAlign: TextAlign.center,
                            style: text.titleMedium,
                          ),
                        const SizedBox(height: 12),
                        if (_finished)
                          _Result(stars: _stageStars)
                        else
                          FilledButton(
                            onPressed: solved ? _next : null,
                            child: const Text('Avanti'),
                          ),
                      ],
              ),
            );
            if (landscape) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  board,
                  Expanded(child: panel),
                ],
              );
            }
            return Column(
              children: [
                Center(child: board),
                Expanded(child: panel),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Spazio minimo sotto la scacchiera in verticale per testo e comandi.
const double _portraitReserve = 240;

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
          style: TextStyle(fontSize: 32, color: RokkoTokens.of(context).star),
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
