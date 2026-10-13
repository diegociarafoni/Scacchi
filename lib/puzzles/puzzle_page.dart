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
import '../theme/rokko_theme.dart';
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
    this.title,
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

  /// Titolo della barra; senza, quello predefinito dei puzzle.
  final String? title;

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

  String _sideName(AppLocalizations l) => l.puzzleSide(
    _session.puzzle.playerSide == Side.white ? 'white' : 'black',
  );

  /// Obiettivo e colore che muove in una riga. Il profilo bambino non ha cifre:
  /// «matto in N» diventa «dai matto».
  String _goalLine(AppLocalizations l) {
    final goal = PuzzleGoal.of(_session.puzzle);
    final shown = goal != null && AppSettings.of(context).kidMode && goal.isMate
        ? PuzzleGoal.mate
        : goal;
    return l.puzzleGoalSide(l.puzzleGoal(shown?.key ?? 'other'), _sideName(l));
  }

  String _message(AppLocalizations l) {
    final rating = widget.trainer.rating.rating.round();
    final delta = _delta;
    // Profilo bambino (RP-06): l'esito non cita il punteggio.
    final outcome = AppSettings.of(context).kidMode
        ? ''
        : _repeat
        ? ' ${l.puzzleOutcomeRepeat}'
        : delta == null
        ? ''
        : ' ${l.puzzleOutcomeRating(rating, '${delta >= 0 ? '+' : ''}${delta.round()}')}';
    return switch (_feedback) {
      _Feedback.find => _goalLine(l),
      _Feedback.correct => l.puzzleCorrect,
      _Feedback.restarted => l.puzzleRestarted(_sideName(l)),
      _Feedback.wrong => l.puzzleWrong,
      _Feedback.solved => '${l.puzzleSolved}$outcome',
      _Feedback.revealed =>
        _session.state == PuzzleState.solved
            ? '${l.puzzleDone}$outcome'
            : l.puzzleRevealed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_empty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title ?? l.puzzleDefaultTitle)),
        body: Center(child: Text(l.puzzleEmpty)),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? l.puzzleDefaultTitle),
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
              tooltip: l.puzzleHelp,
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
                    math.min(c.maxWidth, c.maxHeight - 190),
                  );
                  // Scorrevole come ultima difesa su schermi molto bassi.
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FeedbackBanner(
                            feedback: _feedback,
                            message: _message(l),
                            side: puzzle.playerSide,
                          ),
                          // Con una sola mossa «0 di 1» non dice nulla.
                          if (_session.playerMoves > 1)
                            _Progress(
                              done: _session.playerMovesDone,
                              total: _session.playerMoves,
                              showNumbers: !kid,
                            ),
                          KeyedSubtree(
                            key: const Key('puzzle-board'),
                            child: TrainingBoard(
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
                          ),
                          // Difficoltà e temi si rivelano a puzzle finito: prima
                          // sarebbero un indizio.
                          if (last || done)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                last
                                    ? l.puzzleNoMore
                                    : kid
                                    ? themes
                                    : '${l.puzzleDifficulty(puzzle.rating)}'
                                          '${themes.isEmpty ? '' : ' · $themes'}',
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
              solving: !done,
              onRetry: _canRetry ? _retry : null,
              onNext: canSkip ? _next : null,
              kid: kid,
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
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Semantics(
        label: showNumbers
            ? l.puzzleProgress(done, total)
            : l.puzzleProgressKid,
        value: showNumbers || total == 0
            ? null
            : '${(done * 100 / total).round()}%',
        excludeSemantics: true,
        child: Column(
          children: [
            if (showNumbers)
              Text(
                l.puzzleProgress(done, total),
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
    required this.solving,
    required this.onRetry,
    required this.onNext,
    required this.kid,
  });

  final VoidCallback? onHint;
  final VoidCallback? onSolution;

  /// Suggerimento e soluzione servono solo finché il puzzle è aperto.
  final bool solving;

  /// Nullo finché non c'è nulla da rifare: il pulsante compare solo dopo un errore.
  final VoidCallback? onRetry;
  final VoidCallback? onNext;
  final bool kid;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = RokkoTokens.of(context);
    final touch = kid ? tokens.kidTouch : tokens.minTouch;
    final size = Size(touch, touch);
    // Wrap invece di Row: su schermi stretti i pulsanti vanno su due righe
    // invece di spezzare le etichette a metà parola.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (solving) ...[
            OutlinedButton.icon(
              onPressed: onHint,
              style: OutlinedButton.styleFrom(minimumSize: size),
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(l.puzzleHint, softWrap: false),
            ),
            OutlinedButton.icon(
              onPressed: onSolution,
              style: OutlinedButton.styleFrom(minimumSize: size),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l.puzzleSolution, softWrap: false),
            ),
          ],
          if (onRetry != null)
            OutlinedButton.icon(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(minimumSize: size),
              icon: const Icon(Icons.replay),
              label: Text(l.puzzleRetry, softWrap: false),
            ),
          if (onNext != null)
            FilledButton.icon(
              onPressed: onNext,
              style: FilledButton.styleFrom(minimumSize: size),
              icon: const Icon(Icons.arrow_forward),
              label: Text(l.puzzleNext, softWrap: false),
            ),
        ],
      ),
    );
  }
}

/// Scheda unica sopra la scacchiera: all'inizio obiettivo e colore che muove,
/// poi l'esito dell'ultima mossa; colore, icona e testo, mai il solo colore.
class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.feedback,
    required this.message,
    required this.side,
  });

  final _Feedback feedback;
  final String message;
  final Side side;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = RokkoTokens.of(context);
    final (background, foreground, icon, iconKey) = switch (feedback) {
      _Feedback.wrong => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.cancel,
        const Key('puzzle-wrong-icon'),
      ),
      _Feedback.solved => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.check_circle,
        const Key('puzzle-solved-icon'),
      ),
      _Feedback.correct => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.check,
        const Key('puzzle-correct-icon'),
      ),
      _Feedback.revealed => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.visibility_outlined,
        const Key('puzzle-revealed-icon'),
      ),
      _ => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        null,
        const Key('puzzle-find-icon'),
      ),
    };
    final iconColor = feedback == _Feedback.wrong
        ? AppSettings.of(context).wrongColor
        : foreground;
    return Padding(
      key: const Key('puzzle-feedback'),
      padding: const EdgeInsets.all(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Semantics(
            liveRegion: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: icon == null
                      // Il colore che muove è già nel testo: qui è solo grafica.
                      ? Container(
                          key: iconKey,
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: side == Side.white
                                ? Colors.white
                                : Colors.black,
                            border: Border.all(color: foreground),
                          ),
                        )
                      : Icon(icon, key: iconKey, color: iconColor),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    key: const Key('puzzle-message'),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
