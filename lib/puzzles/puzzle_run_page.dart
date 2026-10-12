import 'dart:async';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../exchange/qr_receive_page.dart';
import '../progress/activity.dart';
import '../progress/progress_feedback.dart';
import '../progress/progress_tracker.dart';
import '../training/training_board.dart';
import 'activity_recorder.dart';
import 'challenge_result_panel.dart';
import 'friend_challenge.dart';
import 'guide_view.dart';
import 'mode_guide.dart';
import 'puzzle.dart';
import 'puzzle_run.dart';
import 'puzzle_trainer.dart';

/// Serie di puzzle a tempo o a errori (RF-82).
class PuzzleRunPage extends StatefulWidget {
  const PuzzleRunPage({
    super.key,
    required this.trainer,
    required this.mode,
    this.clock,
    this.onActivity,
    this.challenge,
    this.scanner = zxingScanner,
  });

  final PuzzleTrainer trainer;
  final PuzzleRunMode mode;

  /// Sfida a un amico (RF-95): stessi puzzle sui due telefoni grazie al seme,
  /// una sola prova e confronto dei punteggi a fine serie.
  final FriendChallenge? challenge;

  /// Lettore QR per il risultato dell'amico, sostituibile nei test.
  final QrScannerBuilder scanner;

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
  late final PuzzleGuide _guide = PuzzleGuide.forRun(widget.mode);
  Timer? _ticker;
  int _revision = 0;
  bool _intro = true;
  bool _ended = false;
  bool _newRecord = false;
  String? _flash;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    // Uscendo a metà serie, record e XP valgono comunque; durante la
    // spiegazione non è ancora cominciato nulla.
    if (!_ended && !_intro) _finalize();
    super.dispose();
  }

  /// Prepara la serie senza avviare il tempo: parte con "Inizia".
  void _prepare() {
    final challenge = widget.challenge;
    _run = PuzzleRun(
      widget.mode,
      widget.trainer.library,
      clock: widget.clock ?? () => _stopwatch.elapsed,
      random: challenge == null ? null : math.Random(challenge.seed),
    );
    _ended = false;
    _newRecord = false;
    _flash = null;
  }

  void _begin() {
    setState(() => _intro = false);
    _startClock();
  }

  void _restart() {
    _prepare();
    _startClock();
  }

  void _startClock() {
    _stopwatch
      ..reset()
      ..start();
    _ticker?.cancel();
    if (widget.mode.limit != null) {
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        setState(() {});
        _checkEnd();
      });
    }
  }

  /// Rilegge le regole a metà serie; il tempo continua a scorrere.
  Future<void> _showGuide() => showPuzzleGuide(context, _guide);

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
    _finalize();
    setState(() {});
  }

  void _finalize() {
    _ended = true;
    _stopwatch.stop();
    _ticker?.cancel();
    unawaited(
      widget.trainer.records.submit(widget.mode, _run.score).then((record) {
        if (mounted) setState(() => _newRecord = record);
      }),
    );
    unawaited(_recordActivities(_run.solved, _stopwatch.elapsed));
  }

  /// Registra i puzzle risolti e mostra un'unica notifica riassuntiva.
  Future<void> _recordActivities(List<Puzzle> solved, Duration elapsed) async {
    final record = widget.onActivity;
    if (record == null) return;
    // Il tempo è diviso tra i puzzle risolti; il resto va alla sessione.
    final each = solved.isEmpty ? Duration.zero : elapsed ~/ solved.length;
    final activities = <Activity>[
      for (final p in solved) PuzzleSolved(themes: p.themes, duration: each),
      PuzzleRunFinished(
        mode: widget.mode.name,
        score: solved.length,
        duration: elapsed - each * solved.length,
      ),
    ];
    final updates = <ProgressUpdate>[];
    for (final a in activities) {
      final update = await record(a);
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
    final guide = _guide;
    final best = widget.trainer.records.best(widget.mode);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.label),
        actions: [
          if (!_intro && !_ended)
            IconButton(
              tooltip: 'Come funziona',
              icon: const Icon(Icons.help_outline),
              onPressed: _showGuide,
            ),
        ],
      ),
      body: SafeArea(
        child: _intro
            ? Center(
                child: GuideBody(
                  guide: guide,
                  actionLabel: 'Inizia',
                  onAction: _begin,
                  footer: best > 0 ? 'Il tuo record: $best puzzle.' : null,
                ),
              )
            : _ended
            ? _Result(
                score: _run.score,
                best: best,
                bestCombo: _run.bestCombo,
                newRecord: _newRecord,
                reason: _endText(),
                // Con la stessa sfida rigiocare darebbe gli stessi puzzle.
                onAgain: widget.challenge == null
                    ? () => setState(_restart)
                    : null,
                extra: widget.challenge == null
                    ? null
                    : ChallengeResultPanel(
                        challenge: widget.challenge!,
                        score: _run.score,
                        scanner: widget.scanner,
                      ),
              )
            : _playing(context, guide),
      ),
    );
  }

  /// Frase che dice perché la serie è finita.
  String? _endText() {
    final max = widget.mode.maxMistakes;
    return switch (_run.endReason) {
      RunEnd.mistakes when max == 1 =>
        'Hai sbagliato un puzzle: la serie è finita.',
      RunEnd.mistakes => 'Hai perso tutte e tre le vite.',
      RunEnd.time => 'Il tempo è scaduto.',
      RunEnd.exhausted => 'Hai risolto tutti i puzzle disponibili.',
      null => null,
    };
  }

  Widget _playing(BuildContext context, PuzzleGuide guide) {
    final text = Theme.of(context).textTheme;
    final remaining = _run.remaining;
    final total = _run.totalTime;
    final max = widget.mode.maxMistakes;
    return LayoutBuilder(
      builder: (context, c) {
        final size = math.max(0.0, math.min(c.maxWidth, c.maxHeight - 230));
        // Scorrevole come ultima difesa su schermi bassi o con testo grande.
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    guide.goal,
                    key: const Key('run-goal'),
                    textAlign: TextAlign.center,
                    style: text.bodyMedium,
                  ),
                ),
                if (remaining != null && total != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    // La barra è solo grafica: il tempo lo legge il testo sotto.
                    child: ExcludeSemantics(
                      child: LinearProgressIndicator(
                        value: total.inMilliseconds == 0
                            ? 0
                            : remaining.inMilliseconds / total.inMilliseconds,
                      ),
                    ),
                  ),
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
                        Semantics(
                          label: 'Tempo rimasto: ${_format(remaining)}',
                          excludeSemantics: true,
                          child: Text(
                            _format(remaining),
                            key: const Key('run-clock'),
                            style: text.titleLarge,
                          ),
                        ),
                      if (max != null) _Lives(total: max, lost: _run.mistakes),
                      if (widget.mode == PuzzleRunMode.storm)
                        Text('Combo ${_run.combo}', style: text.titleMedium),
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
                        child: Text(_flash ?? '', style: text.titleMedium),
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
            ),
          ),
        );
      },
    );
  }
}

/// Vite rimaste come cuori, con un'etichetta per i lettori di schermo.
class _Lives extends StatelessWidget {
  const _Lives({required this.total, required this.lost});

  final int total;
  final int lost;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Semantics(
      label: 'Vite: ${total - lost} su $total',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Icon(
              i < total - lost ? Icons.favorite : Icons.favorite_border,
              color: color,
            ),
        ],
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
    required this.reason,
    required this.onAgain,
    this.extra,
  });

  final int score;
  final int best;
  final int bestCombo;
  final bool newRecord;
  final String? reason;
  final VoidCallback? onAgain;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Serie conclusa', style: text.headlineSmall),
            if (reason != null) ...[
              const SizedBox(height: 8),
              Text(reason!, style: text.bodyLarge),
            ],
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
            if (onAgain != null)
              FilledButton.icon(
                onPressed: onAgain,
                icon: const Icon(Icons.replay),
                label: const Text('Gioca ancora'),
              ),
            ?extra,
          ],
        ),
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
  challengesCompleted: [for (final u in updates) ...u.challengesCompleted],
  weeklyCompleted: updates.any((u) => u.weeklyCompleted),
  newRecords: {for (final u in updates) ...u.newRecords}.toList(),
);
