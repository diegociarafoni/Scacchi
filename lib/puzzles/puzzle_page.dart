import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../progress/activity.dart';
import '../progress/progress_feedback.dart';
import '../training/training_board.dart';
import 'activity_recorder.dart';
import 'puzzle.dart';
import 'puzzle_session.dart';
import 'puzzle_trainer.dart';
import 'themes.dart';

enum _Feedback { find, correct, wrong, solved, revealed }

/// Risoluzione di puzzle uno dopo l'altro, con punteggio.
class PuzzlePage extends StatefulWidget {
  const PuzzlePage({
    super.key,
    required this.trainer,
    this.theme,
    this.puzzle,
    this.title = 'Puzzle',
    this.onActivity,
    this.replyDelay = const Duration(milliseconds: 400),
  });

  final PuzzleTrainer trainer;
  final String? theme;

  /// Puzzle fisso (per esempio quello del giorno); altrimenti si sceglie per punteggio.
  final Puzzle? puzzle;
  final String title;

  /// Riceve un `PuzzleSolved` per ogni puzzle risolto, per XP e obiettivi.
  final ActivityRecorder? onActivity;
  final Duration replyDelay;

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  late PuzzleSession _session;
  _Feedback _feedback = _Feedback.find;
  double? _delta;
  Square? _hint;
  int _revision = 0;
  bool _recorded = false;
  Timer? _replyTimer;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _start(widget.puzzle ?? widget.trainer.next(theme: widget.theme));
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    super.dispose();
  }

  void _start(Puzzle puzzle) {
    _session = PuzzleSession(puzzle);
    _feedback = _Feedback.find;
    _delta = null;
    _hint = null;
    _recorded = false;
    _stopwatch
      ..reset()
      ..start();
  }

  void _onMove(Move move) {
    final result = _session.tryMove(move);
    setState(() {
      _hint = null;
      switch (result) {
        case PuzzleMoveResult.wrong || PuzzleMoveResult.illegal:
          _feedback = _Feedback.wrong;
          _revision++;
        case PuzzleMoveResult.correct:
          _feedback = _Feedback.correct;
          _scheduleReply();
        case PuzzleMoveResult.solved:
          _finish();
      }
    });
  }

  void _scheduleReply() {
    _replyTimer?.cancel();
    _replyTimer = Timer(widget.replyDelay, () {
      if (!mounted) return;
      setState(() => _session.playReply());
    });
  }

  void _finish() {
    _feedback = _session.firstTry ? _Feedback.solved : _Feedback.revealed;
    if (_recorded) return;
    _recorded = true;
    final solved = _session.firstTry;
    _stopwatch.stop();
    widget.trainer.record(_session.puzzle, solved: solved).then((delta) {
      if (mounted) setState(() => _delta = delta);
    });
    final record = widget.onActivity;
    if (record != null && !_session.revealed) {
      record(PuzzleSolved(duration: _stopwatch.elapsed)).then((update) {
        if (mounted && update != null) showProgressFeedback(context, update);
      });
    }
  }

  void _showHint() => setState(() => _hint = _session.hint());

  void _showSolution() {
    _replyTimer?.cancel();
    setState(() {
      _hint = null;
      _session.playReply();
      _session.showNextMove();
      if (_session.state == PuzzleState.solved) {
        _finish();
      } else {
        _feedback = _Feedback.revealed;
        _scheduleReply();
      }
    });
  }

  void _next() {
    _replyTimer?.cancel();
    setState(() => _start(widget.trainer.next(theme: widget.theme)));
  }

  String get _message {
    final side = _session.puzzle.playerSide == Side.white ? 'Bianco' : 'Nero';
    final rating = widget.trainer.rating.rating.round();
    final delta = _delta == null
        ? ''
        : ' (${_delta! >= 0 ? '+' : ''}${_delta!.round()})';
    return switch (_feedback) {
      _Feedback.find => 'Trova la mossa migliore per il $side.',
      _Feedback.correct => 'Giusto! Continua.',
      _Feedback.wrong => 'Non è la mossa giusta. Riprova.',
      _Feedback.solved => 'Risolto! Punteggio $rating$delta.',
      _Feedback.revealed =>
        _session.state == PuzzleState.solved
            ? 'Puzzle concluso. Punteggio $rating$delta.'
            : 'Ecco la mossa giusta.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final done = _session.state == PuzzleState.solved;
    final puzzle = _session.puzzle;
    final themes = puzzle.themes
        .map((t) => puzzleThemeLabels[t])
        .whereType<String>()
        .take(3)
        .join(', ');
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final size = math.min(c.maxWidth, c.maxHeight - 200);
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _message,
                              key: const Key('puzzle-message'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        TrainingBoard(
                          size: size,
                          position: _session.position,
                          lastMove: _session.lastMove,
                          player: puzzle.playerSide,
                          enabled: !done && !_session.awaitingReply,
                          revision: _revision,
                          shapes: {
                            if (_hint != null)
                              Circle(color: Colors.green, orig: _hint!),
                          },
                          onMove: _onMove,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            done
                                ? 'Puzzle ${puzzle.rating}'
                                      '${themes.isEmpty ? '' : ' · $themes'}'
                                : 'Il tuo punteggio: '
                                      '${widget.trainer.rating.rating.round()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _PuzzleActions(
                  onHint: done ? null : _showHint,
                  onSolution: done ? null : _showSolution,
                  onNext: widget.puzzle == null && done ? _next : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PuzzleActions extends StatelessWidget {
  const _PuzzleActions({
    required this.onHint,
    required this.onSolution,
    required this.onNext,
  });

  final VoidCallback? onHint;
  final VoidCallback? onSolution;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: onHint,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Suggerimento'),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: onSolution,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Soluzione'),
            ),
          ),
          Expanded(
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Prossimo'),
            ),
          ),
        ],
      ),
    );
  }
}
