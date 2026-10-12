import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../progress/activity.dart';
import '../progress/progress_feedback.dart';
import '../settings/board_marks.dart';
import '../settings/settings.dart';
import '../share/position_image.dart';
import '../share/position_image_page.dart';
import '../training/training_board.dart';
import 'activity_recorder.dart';
import 'guide_view.dart';
import 'mode_guide.dart';
import 'puzzle.dart';
import 'puzzle_feed.dart';
import 'puzzle_goal.dart';
import 'puzzle_session.dart';
import 'puzzle_trainer.dart';
import 'themes.dart';

enum _Feedback { find, restarted, correct, wrong, solved, revealed }

/// Risoluzione di puzzle uno dopo l'altro, con punteggio.
class PuzzlePage extends StatefulWidget {
  const PuzzlePage({
    super.key,
    required this.trainer,
    this.theme,
    this.puzzle,
    this.feed,
    this.title = 'Puzzle',
    this.guide,
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

  /// Spiegazione della modalità: si apre da sola la prima volta e dall'icona.
  final PuzzleGuide? guide;

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

  /// Mossa sbagliata appena tentata, mostrata in rosso finché non si riprova.
  Move? _wrongMove;
  int _revision = 0;
  bool _recorded = false;
  bool _repeat = false;

  /// Cambia a ogni puzzle: un esito in ritardo non tocca il puzzle successivo.
  int _epoch = 0;
  Timer? _replyTimer;
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _showGuideOnce();
    final first = _feed.next();
    if (first == null) {
      _empty = true;
    } else {
      _start(first);
    }
  }

  /// Apre la spiegazione la prima volta che si entra nella modalità; il profilo
  /// bambino non la riceve, perché è fatta di regole e numeri.
  void _showGuideOnce() {
    final guide = widget.guide;
    if (guide == null || widget.trainer.guideSeen(guide.id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || AppSettings.of(context).kidMode) return;
      await showPuzzleGuide(context, guide);
      // Letta davvero solo se è stata chiusa; un errore di salvataggio non
      // deve interrompere nulla.
      try {
        await widget.trainer.markGuideSeen(guide.id);
      } on Object {
        // Al prossimo ingresso la spiegazione si riapre.
      }
    });
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
    _wrongMove = null;
    _recorded = false;
    _repeat = false;
    _epoch++;
    _stopwatch
      ..reset()
      ..start();
  }

  void _onMove(Move move) {
    final result = _session.tryMove(move);
    if (result == PuzzleMoveResult.wrong && AppSettings.of(context).haptics) {
      unawaited(HapticFeedback.heavyImpact());
    }
    setState(() {
      _hint = null;
      switch (result) {
        case PuzzleMoveResult.wrong || PuzzleMoveResult.illegal:
          _feedback = _Feedback.wrong;
          _wrongMove = result == PuzzleMoveResult.wrong ? move : null;
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

  /// Dopo un errore o una soluzione mostrata si può ricominciare da capo.
  bool get _canRetry => !_session.firstTry;

  void _finish() {
    _feedback = _session.firstTry ? _Feedback.solved : _Feedback.revealed;
    if (_recorded) return;
    _recorded = true;
    _stopwatch.stop();
    unawaited(
      _record(
        _session.puzzle,
        solved: _session.firstTry,
        awardXp: !_session.revealed,
      ),
    );
  }

  /// [awardXp] è deciso da chi chiama, prima dell'attesa: dopo, la sessione
  /// potrebbe essere già un'altra.
  Future<void> _record(
    Puzzle puzzle, {
    required bool solved,
    required bool awardXp,
  }) async {
    final epoch = _epoch;
    final outcome = await _feed.finished(puzzle, solved: solved);
    final delta = outcome.ratingDelta;
    if (!mounted) return;
    if (epoch == _epoch) {
      setState(() {
        _delta = delta;
        _repeat = delta == null && !outcome.awardXp;
      });
    }
    final record = widget.onActivity;
    // Le ripetizioni e le soluzioni mostrate non valgono XP.
    if (record == null || !outcome.awardXp || !awardXp) return;
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

  /// Freccia e cerchio rossi sulla mossa sbagliata; il rosso non è l'unico
  /// segnale: ci sono anche l'icona e il testo.
  /// La mossa sbagliata usa il rosso della minaccia, scelto per stare a 3:1
  /// dentro il contorno del tema.
  Set<Shape> _wrongShapes(BoardMarks marks) =>
      switch (_feedback == _Feedback.wrong ? _wrongMove : null) {
        NormalMove(:final from, :final to) => {
          ...marks.arrow(marks.threat, from, to),
          ...marks.circle(marks.threat, to),
        },
        DropMove(:final to) => marks.circle(marks.threat, to),
        null => const {},
      };

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

  /// Ricomincia dalla posizione iniziale; l'errore già fatto resta registrato.
  void _retry() {
    _replyTimer?.cancel();
    setState(() {
      _session.restart();
      _feedback = _Feedback.restarted;
      _hint = null;
      _revision++;
    });
  }

  void _next() {
    _replyTimer?.cancel();
    // Passare oltre dopo un errore vale come puzzle fallito, senza XP.
    if (!_recorded && _session.state != PuzzleState.solved) {
      _recorded = true;
      _stopwatch.stop();
      unawaited(_record(_session.puzzle, solved: false, awardXp: false));
    }
    final next = _feed.next();
    if (next != null) setState(() => _start(next));
  }

  String get _message {
    final side = _session.puzzle.playerSide == Side.white ? 'Bianco' : 'Nero';
    final rating = widget.trainer.rating.rating.round();
    final delta = _delta;
    // Profilo bambino (RP-06): l'esito non cita il punteggio.
    final outcome = AppSettings.of(context).kidMode
        ? ''
        : _repeat
        ? ' Già visto: punteggio invariato.'
        : delta == null
        ? ''
        : ' Punteggio $rating (${delta >= 0 ? '+' : ''}${delta.round()}).';
    return switch (_feedback) {
      _Feedback.find => 'Trova la mossa migliore per il $side.',
      _Feedback.correct => 'Giusto! Continua.',
      _Feedback.restarted =>
        'Posizione iniziale. Trova la mossa migliore per il $side.',
      _Feedback.wrong =>
        'Non è la mossa giusta. Premi «Riprova» per ricominciare.',
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
    final canSkip = (done || _canRetry) && _feed.hasNext;
    final puzzle = _session.puzzle;
    final themes = puzzle.themes
        .map((t) => puzzleThemeLabels[t])
        .whereType<String>()
        .take(3)
        .join(', ');
    final kid = AppSettings.of(context).kidMode;
    // Il profilo bambino non ha cifre: «matto in N» diventa «dai matto».
    final goal = PuzzleGoal.of(puzzle);
    final goalText = goal == null
        ? null
        : Localizations.of<AppLocalizations>(
            context,
            AppLocalizations,
          )?.puzzleGoal((kid && goal.isMate ? PuzzleGoal.mate : goal).key);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!kid)
            PositionImageButton(
              image: () => PositionImage(
                fen: _session.position.fen,
                orientation: puzzle.playerSide,
                lastMove: _session.lastMove,
              ),
            ),
          if (widget.guide != null && !kid)
            IconButton(
              tooltip: 'Come funziona',
              icon: const Icon(Icons.help_outline),
              onPressed: () => showPuzzleGuide(context, widget.guide!),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  // Il lato segue lo spazio rimasto sopra i pulsanti, che
                  // salgono a due righe sugli schermi stretti.
                  final size = math.max(
                    0.0,
                    math.min(c.maxWidth, c.maxHeight - 170),
                  );
                  // Scorrevole come ultima difesa su schermi molto bassi.
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (goalText != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                              child: Semantics(
                                header: true,
                                child: Text(
                                  goalText,
                                  key: const Key('puzzle-goal'),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Semantics(
                              liveRegion: true,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_feedback == _Feedback.wrong) ...[
                                    Icon(
                                      Icons.cancel,
                                      key: const Key('puzzle-wrong-icon'),
                                      color: AppSettings.of(context).wrongColor,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      _message,
                                      key: const Key('puzzle-message'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _Progress(
                            done: _session.playerMovesDone,
                            total: _session.playerMoves,
                            showNumbers: !kid,
                          ),
                          TrainingBoard(
                            size: size,
                            position: _session.position,
                            lastMove: _session.lastMove,
                            player: puzzle.playerSide,
                            enabled: !done && !_session.awaitingReply,
                            revision: _revision,
                            shapes: {
                              ..._wrongShapes(AppSettings.of(context).marks),
                              if (_hint != null)
                                ...AppSettings.of(context).marks.circle(
                                  AppSettings.of(context).hintColor,
                                  _hint!,
                                ),
                            },
                            onMove: _onMove,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              last
                                  ? 'Non ci sono altri puzzle per ora.'
                                  : kid
                                  // Restano i temi, senza difficoltà né punteggio.
                                  ? (done
                                        ? themes
                                        : AppLocalizations.of(context)
                                              .kidPuzzleKeepGoing)
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
                  );
                },
              ),
            ),
            _PuzzleActions(
              onHint: done ? null : _showHint,
              onSolution: done ? null : _showSolution,
              onRetry: _canRetry ? _retry : null,
              onNext: canSkip ? _next : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Avanzamento nel puzzle: mosse trovate sul totale. Nel profilo bambino c'è
/// solo la barra, senza cifre.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.done,
    required this.total,
    required this.showNumbers,
  });

  final int done;
  final int total;
  final bool showNumbers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Semantics(
        label: showNumbers
            ? 'Mosse trovate: $done di $total'
            : 'Avanzamento del puzzle',
        value: showNumbers || total == 0
            ? null
            : '${(done * 100 / total).round()}%',
        excludeSemantics: true,
        child: Column(
          children: [
            if (showNumbers)
              Text(
                'Mosse trovate: $done di $total',
                key: const Key('puzzle-progress'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: total == 0 ? 0 : done / total),
          ],
        ),
      ),
    );
  }
}

class _PuzzleActions extends StatelessWidget {
  const _PuzzleActions({
    required this.onHint,
    required this.onSolution,
    required this.onRetry,
    required this.onNext,
  });

  final VoidCallback? onHint;
  final VoidCallback? onSolution;

  /// Nullo finché non c'è nulla da rifare: il pulsante compare solo dopo un errore.
  final VoidCallback? onRetry;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    // Wrap invece di Row: su schermi stretti i pulsanti vanno su due righe
    // invece di spezzare le etichette a metà parola.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          TextButton.icon(
            onPressed: onHint,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Suggerimento', softWrap: false),
          ),
          TextButton.icon(
            onPressed: onSolution,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Soluzione', softWrap: false),
          ),
          if (onRetry != null)
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay),
              label: const Text('Riprova', softWrap: false),
            ),
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Prossimo', softWrap: false),
          ),
        ],
      ),
    );
  }
}
