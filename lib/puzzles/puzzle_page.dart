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
import 'puzzle_feed.dart';
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
    this.feed,
    this.title = 'Puzzle',
    this.onActivity,
    this.replyDelay = const Duration(milliseconds: 400),
  });

  final PuzzleTrainer trainer;
  final String? theme;

  /// Puzzle fisso (per esempio quello del giorno); altrimenti si sceglie per punteggio.
  final Puzzle? puzzle;

  /// Sorgente alternativa, per esempio il ripasso degli errori.
  final PuzzleFeed? feed;
  final String title;

  /// Riceve un `PuzzleSolved` per ogni puzzle risolto, per XP e obiettivi.
  final ActivityRecorder? onActivity;
  final Duration replyDelay;

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  late final PuzzleFeed _feed =
      widget.feed ??
      (widget.puzzle != null
          ? SingleFeed(widget.trainer, widget.puzzle!)
          : RatedFeed(widget.trainer, theme: widget.theme));
  late PuzzleSession _session;
  bool _empty = false;
  _Feedback _feedback = _Feedback.find;
  double? _delta;
  Square? _hint;
  int _revision = 0;
  bool _recorded = false;
  bool _repeat = false;
  Timer? _replyTimer;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    final first = _feed.next();
    if (first == null) {
      _empty = true;
    } else {
      _start(first);
    }
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
    _repeat = false;
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
    _stopwatch.stop();
    _record(_session.puzzle, solved: _session.firstTry);
  }

  Future<void> _record(Puzzle puzzle, {required bool solved}) async {
    final outcome = await _feed.finished(puzzle, solved: solved);
    final delta = outcome.ratingDelta;
    if (!mounted) return;
    setState(() {
      _delta = delta;
      _repeat = delta == null && !outcome.awardXp;
    });
    final record = widget.onActivity;
    // Le ripetizioni e le soluzioni mostrate non valgono XP.
    if (record == null || !outcome.awardXp || _session.revealed) return;
    final update = await record(
      PuzzleSolved(
        themes: puzzle.themes,
        rating: widget.trainer.rating.rating.round(),
        duration: _stopwatch.elapsed,
      ),
    );
    if (mounted && update != null) showProgressFeedback(context, update);
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
    final next = _feed.next();
    if (next != null) setState(() => _start(next));
  }

  String get _message {
    final side = _session.puzzle.playerSide == Side.white ? 'Bianco' : 'Nero';
    final rating = widget.trainer.rating.rating.round();
    final delta = _delta;
    final outcome = _repeat
        ? ' Già visto: punteggio invariato.'
        : delta == null
        ? ''
        : ' Punteggio $rating (${delta >= 0 ? '+' : ''}${delta.round()}).';
    return switch (_feedback) {
      _Feedback.find => 'Trova la mossa migliore per il $side.',
      _Feedback.correct => 'Giusto! Continua.',
      _Feedback.wrong => 'Non è la mossa giusta. Riprova.',
      _Feedback.solved => 'Risolto!$outcome',
      _Feedback.revealed =>
        _session.state == PuzzleState.solved
            ? 'Puzzle concluso.$outcome'
            : 'Ecco la mossa giusta.',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_empty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Nessun puzzle da proporre.')),
      );
    }
    final done = _session.state == PuzzleState.solved;
    final last = done && !_feed.hasNext;
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
                            last
                                ? 'Non ci sono altri puzzle per ora.'
                                : done
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
                  onNext: done && !last ? _next : null,
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
