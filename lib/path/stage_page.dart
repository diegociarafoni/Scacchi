import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import '../theme/rokko_theme.dart';
import 'curriculum.dart';
import 'exercise.dart';
import 'path_controller.dart';

/// Apre [stage] riprendendo dagli esercizi già risolti e salvando i progressi
/// a ogni esercizio; restituisce le stelle come [StagePage].
Future<int?> openStage(
  BuildContext context,
  PathController controller,
  Stage stage,
) {
  final replay = controller.progress.isCompleted(stage.id);
  return Navigator.of(context).push<int>(
    MaterialPageRoute(
      builder: (_) => StagePage(
        stage: stage,
        // Rigiocare una tappa già completata riparte sempre da capo.
        resume: replay ? const [] : controller.progress.resumeFor(stage.id),
        onProgress: replay
            ? null
            : (solved) => controller.saveResume(stage.id, solved),
      ),
    ),
  );
}

/// Svolge gli esercizi di una tappa e restituisce con `Navigator.pop` le
/// stelle ottenute (media arrotondata per difetto).
class StagePage extends StatefulWidget {
  const StagePage({
    super.key,
    required this.stage,
    this.resume = const [],
    this.onProgress,
  });

  final Stage stage;

  /// Stelle degli esercizi già risolti in una visita precedente.
  final List<int> resume;

  /// Chiamata a ogni cambiamento degli esercizi risolti.
  final ValueChanged<List<int>>? onProgress;

  @override
  State<StagePage> createState() => _StagePageState();
}

class _StagePageState extends State<StagePage> {
  // Una ripresa più lunga della tappa è di una versione precedente: si scarta.
  late final List<int> _stars =
      widget.resume.length > widget.stage.exercises.length
      ? []
      : [...widget.resume];
  late int _index = math.min(_stars.length, widget.stage.exercises.length - 1);
  late ExerciseRun _run = ExerciseRun.start(widget.stage.exercises[_index]);
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );
  String? _feedback;

  /// La spiegazione della tappa precede il primo esercizio.
  late bool _started = widget.stage.intro == null || _stars.isNotEmpty;

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  Exercise get _exercise => widget.stage.exercises[_index];

  bool get _finished => _stars.length == widget.stage.exercises.length;

  GameData _gameData({Move? lastMove}) {
    final side = _run.done || !_started || _finished
        ? PlayerSide.none
        : PlayerSide.white;
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

  List<Square> get _remainingStars => switch (_run) {
    final StarsRun run => run.remaining,
    LineRun() => const [],
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
            final l = AppLocalizations.of(context);
            setState(
              () => _feedback = run.savedWithoutDefending
                  ? l.pathStageSaved
                  : l.pathStageWrong,
            );
          case MoveVerdict.correct:
            _board.updatePosition(_gameData(lastMove: run.lastReply));
            setState(
              () => _feedback = AppLocalizations.of(context).pathStageGood,
            );
          case MoveVerdict.solved:
            _board.updatePosition(_gameData(lastMove: move), animate: animate);
            _solved(run.stars);
            setState(
              () => _feedback = AppLocalizations.of(context).pathStageSolved,
            );
        }
    }
  }

  void _solved(int stars) {
    _stars.add(stars);
    widget.onProgress?.call(List.of(_stars));
  }

  /// Rifà da capo l'esercizio in corso, anche se già risolto o senza più
  /// vie d'uscita.
  void _restart() {
    if (_stars.length > _index) {
      _stars.length = _index;
      widget.onProgress?.call(List.of(_stars));
    }
    setState(() {
      _run = ExerciseRun.start(_exercise);
      _feedback = null;
    });
    _board.updatePosition(_gameData(), animate: false);
  }

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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stage.title),
        actions: [
          if (_started && !_finished)
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: l10n.pathStageRestartTooltip,
              onPressed: _restart,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _stars.length / widget.stage.exercises.length,
            semanticsLabel: l10n.pathStageExerciseOf(
              _index + 1,
              widget.stage.exercises.length,
            ),
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
            final cell = size / 8;
            // Le stelle stanno al centro della casa: i segnalini d'angolo di
            // chessground sembravano indicare la casa accanto.
            final board = SizedBox.square(
              dimension: size,
              child: Stack(
                children: [
                  Chessboard(
                    size: size,
                    controller: _board,
                    orientation: Side.white,
                    onMove: _onMove,
                    settings: AppSettings.of(context).exerciseBoard
                        .copyWith(autoQueenPromotion: true),
                  ),
                  for (final s in _remainingStars)
                    Positioned(
                      key: ValueKey('star-${s.name}'),
                      left: s.file.value * cell,
                      top: (7 - s.rank.value) * cell,
                      width: cell,
                      height: cell,
                      child: IgnorePointer(
                        child: Center(
                          child: Text(
                            '★',
                            style: TextStyle(
                              fontSize: cell * 0.7,
                              color: const Color(0xFFF2B01E),
                              shadows: const [
                                Shadow(blurRadius: 3, color: Color(0xCC000000)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
                          child: Text(l10n.pathStageStart),
                        ),
                      ]
                    : [
                        Text(
                          widget.stage.instructions(_index),
                          style: text.titleMedium,
                        ),
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
                            child: Text(l10n.pathStageNext),
                          ),
                        if (!_finished && !solved)
                          TextButton(
                            onPressed: _restart,
                            child: Text(l10n.pathStageRestartExercise),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.pathStageComplete,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          '${'★' * stars}${'☆' * (3 - stars)}',
          semanticsLabel: l10n.pathStageDone(stars),
          style: TextStyle(fontSize: 32, color: RokkoTokens.of(context).star),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.pop(context, stars),
          child: Text(l10n.pathStageFinish),
        ),
      ],
    );
  }
}
