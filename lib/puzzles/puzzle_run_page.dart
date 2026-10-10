import 'dart:async';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../progress/activity.dart';
import '../progress/progress_feedback.dart';
import '../progress/progress_tracker.dart';
import '../training/training_board.dart';
import 'activity_recorder.dart';
import 'puzzle_run.dart';
import 'puzzle_trainer.dart';

const runModeLabels = <PuzzleRunMode, String>{
  PuzzleRunMode.storm: 'Puzzle Storm',
  PuzzleRunMode.rush3: 'Rush 3 minuti',
  PuzzleRunMode.rush5: 'Rush 5 minuti',
  PuzzleRunMode.survival: 'Sopravvivenza',
  PuzzleRunMode.streak: 'Serie',
};

const runModeDescriptions = <PuzzleRunMode, String>{
  PuzzleRunMode.storm: '3 minuti, secondi bonus con le combo',
  PuzzleRunMode.rush3: '3 minuti, tre errori',
  PuzzleRunMode.rush5: '5 minuti, tre errori',
  PuzzleRunMode.survival: 'Senza tempo, tre errori',
  PuzzleRunMode.streak: 'Senza tempo, finisce al primo errore',
};

/// Serie di puzzle a tempo o a errori (RF-82).
class PuzzleRunPage extends StatefulWidget {
  const PuzzleRunPage({
    super.key,
    required this.trainer,
    required this.mode,
    this.clock,
    this.onActivity,
  });

  final PuzzleTrainer trainer;
  final PuzzleRunMode mode;

  /// Tempo trascorso, sostituibile nei test.
  final Duration Function()? clock;

  /// Riceve un `PuzzleSolved` per ogni puzzle risolto, a fine serie.
  final ActivityRecorder? onActivity;

  @override
  State<PuzzleRunPage> createState() => _PuzzleRunPageState();
}

class _PuzzleRunPageState extends State<PuzzleRunPage> {
  final _stopwatch = Stopwatch();
  late PuzzleRun _run;
  Timer? _ticker;
  int _revision = 0;
  bool _ended = false;
  bool _newRecord = false;
  String? _flash;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _restart() {
    _stopwatch
      ..reset()
      ..start();
    _run = PuzzleRun(
      widget.mode,
      widget.trainer.library,
      clock: widget.clock ?? () => _stopwatch.elapsed,
    );
    _ended = false;
    _newRecord = false;
    _flash = null;
    _ticker?.cancel();
    if (widget.mode.limit != null) {
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        setState(() {});
        _checkEnd();
      });
    }
  }

  void _onMove(Move move) {
    final result = _run.tryMove(move);
    setState(() {
      _flash = switch (result) {
        RunMoveResult.solved => 'Giusto!',
        RunMoveResult.wrong => 'Sbagliato',
        _ => _flash,
      };
      if (result == RunMoveResult.wrong || result == RunMoveResult.illegal) {
        _revision++;
      }
    });
    _checkEnd();
  }

  void _checkEnd() {
    if (_ended || !_run.isOver) return;
    _ended = true;
    _stopwatch.stop();
    _ticker?.cancel();
    widget.trainer.records.submit(widget.mode, _run.score).then((record) {
      if (mounted) setState(() => _newRecord = record);
    });
    _recordActivities(_run.score, _stopwatch.elapsed);
    setState(() {});
  }

  /// Registra i puzzle risolti e mostra un'unica notifica riassuntiva.
  Future<void> _recordActivities(int solved, Duration elapsed) async {
    final record = widget.onActivity;
    if (record == null || solved == 0) return;
    final each = elapsed ~/ solved;
    final updates = <ProgressUpdate>[];
    for (var i = 0; i < solved; i++) {
      final update = await record(PuzzleSolved(duration: each));
      if (update != null) updates.add(update);
    }
    if (!mounted || updates.isEmpty) return;
    showProgressFeedback(context, mergeUpdates(updates));
  }

  String _format(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final remaining = _run.remaining;
    final max = widget.mode.maxMistakes;
    return Scaffold(
      appBar: AppBar(title: Text(runModeLabels[widget.mode]!)),
      body: SafeArea(
        child: _ended
            ? _Result(
                score: _run.score,
                best: widget.trainer.records.best(widget.mode),
                bestCombo: _run.bestCombo,
                newRecord: _newRecord,
                onAgain: () => setState(_restart),
              )
            : LayoutBuilder(
                builder: (context, c) {
                  final size = math.min(c.maxWidth, c.maxHeight - 160);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'Punti ${_run.score}',
                              key: const Key('run-score'),
                              style: text.titleLarge,
                            ),
                            if (remaining != null)
                              Text(
                                _format(remaining),
                                key: const Key('run-clock'),
                                style: text.titleLarge,
                              ),
                            if (max != null)
                              Text(
                                'Errori ${_run.mistakes}/$max',
                                style: text.titleMedium,
                              ),
                            if (widget.mode == PuzzleRunMode.storm)
                              Text(
                                'Combo ${_run.combo}',
                                style: text.titleMedium,
                              ),
                          ],
                        ),
                      ),
                      TrainingBoard(
                        size: size,
                        position: _run.current.position,
                        lastMove: _run.current.lastMove,
                        player: _run.current.puzzle.playerSide,
                        revision: _revision,
                        onMove: _onMove,
                      ),
                      SizedBox(
                        height: 56,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _flash ?? '',
                                style: text.titleMedium,
                              ),
                            ),
                            if (widget.mode == PuzzleRunMode.streak)
                              TextButton.icon(
                                onPressed: _run.canSkip
                                    ? () => setState(() => _run.skip())
                                    : null,
                                icon: const Icon(Icons.skip_next),
                                label: const Text('Salta'),
                              ),
                          ],
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
  const _Result({
    required this.score,
    required this.best,
    required this.bestCombo,
    required this.newRecord,
    required this.onAgain,
  });

  final int score;
  final int best;
  final int bestCombo;
  final bool newRecord;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Serie conclusa', style: text.headlineSmall),
          const SizedBox(height: 16),
          Text(
            '$score',
            key: const Key('run-final-score'),
            style: text.displayMedium,
          ),
          Text('puzzle risolti', style: text.titleMedium),
          const SizedBox(height: 16),
          if (newRecord)
            Text('Nuovo record personale!', style: text.titleLarge)
          else
            Text('Record: $best', style: text.titleMedium),
          if (bestCombo > 0) Text('Combo migliore: $bestCombo'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAgain,
            icon: const Icon(Icons.replay),
            label: const Text('Gioca ancora'),
          ),
        ],
      ),
    );
  }
}

/// Somma più aggiornamenti dei progressi in uno solo.
ProgressUpdate mergeUpdates(List<ProgressUpdate> updates) => ProgressUpdate(
  state: updates.last.state,
  xpGained: updates.fold(0, (sum, u) => sum + u.xpGained),
  newLevel: updates.map((u) => u.newLevel).whereType<int>().lastOrNull,
  goalReached: updates.any((u) => u.goalReached),
  freezeEarned: updates.any((u) => u.freezeEarned),
  unlocked: [for (final u in updates) ...u.unlocked],
);
