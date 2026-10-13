import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../training/training_board.dart';
import 'guess_run.dart';
import 'master_game.dart';
import 'masters_controller.dart';

/// «Indovina la mossa» (RF-88): si gioca un lato di una partita storica e a
/// ogni turno si confronta la propria mossa con quella del maestro.
class GuessPage extends StatefulWidget {
  const GuessPage({
    super.key,
    required this.game,
    required this.side,
    required this.controller,
    this.simple = false,
  });

  final MasterGame game;
  final Side side;
  final MastersController controller;

  /// Profilo bambino: niente percentuali né conteggi.
  final bool simple;

  @override
  State<GuessPage> createState() => _GuessPageState();
}

class _GuessPageState extends State<GuessPage> {
  late GuessRun _run;
  final Stopwatch _clock = Stopwatch()..start();
  String? _feedback;
  String? _note;
  bool _busy = false;

  /// Cambia a ogni «Rigioca»: una risposta della partita precedente si scarta.
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _run = GuessRun(widget.game, widget.side);
    _feedback = null;
    _note = null;
    _busy = false;
    // Con il Nero la prima mossa del Bianco è già sulla scacchiera.
    if (!_run.userToMove && !_run.finished) _run.playOpponent();
  }

  Future<void> _onMove(Move move) async {
    if (_busy || !_run.userToMove) return;
    final GuessResult result;
    try {
      result = _run.submit(move);
    } on ArgumentError {
      return;
    }
    final ply = _run.ply;
    final label = widget.game.label(ply);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = !_run.finished;
      _feedback = result.matched
          ? l10n.mastersSameAsMaster(label)
          : l10n.mastersMasterPlayed(label);
      _note = widget.game.noteAt(ply);
    });
    if (_run.finished) return _finish();
    final attempt = _attempt;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || attempt != _attempt) return;
    _run.playOpponent();
    final opponentPly = _run.ply;
    final reply = widget.game.noteAt(opponentPly);
    final answer = AppLocalizations.of(context)
        .mastersReply(widget.game.label(opponentPly));
    setState(() {
      _busy = false;
      _feedback = '$_feedback $answer';
      if (reply != null) _note = [?_note, reply].join('\n\n');
    });
    if (_run.finished) await _finish();
  }

  Future<void> _finish() async {
    _clock.stop();
    setState(() {});
    try {
      await widget.controller.finish(
        widget.game.id,
        _run.percent,
        _clock.elapsed,
      );
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('Risultato della partita non salvato: $e'); // l10n-ok
      }
    }
  }

  void _retry() {
    setState(() {
      _attempt++;
      _start();
    });
    _clock
      ..reset()
      ..start();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final game = widget.game;
    return Scaffold(
      appBar: AppBar(title: Text('${game.white} – ${game.black}')),
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
            final board = TrainingBoard(
              size: size,
              position: _run.position,
              player: widget.side,
              lastMove: _run.lastMove,
              enabled: !_busy && !_run.finished,
              revision: _attempt,
              onMove: _onMove,
            );
            final panel = SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_run.finished)
                    _Outcome(run: _run, simple: widget.simple, onRetry: _retry)
                  else ...[
                    Text(
                      widget.side == Side.white
                          ? l10n.mastersYourTurnWhite
                          : l10n.mastersYourTurnBlack,
                      style: text.titleMedium,
                    ),
                    if (!widget.simple && _run.attempts > 0)
                      Text(l10n.mastersGuessed(_run.correct, _run.attempts)),
                  ],
                  if (_feedback != null) ...[
                    const SizedBox(height: 12),
                    Text(_feedback!, style: text.titleMedium),
                  ],
                  if (_note != null) ...[
                    const SizedBox(height: 8),
                    Text(_note!),
                  ],
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

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.run,
    required this.simple,
    required this.onRetry,
  });

  final GuessRun run;
  final bool simple;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final stars = run.stars;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.mastersFinished, style: text.titleLarge),
        if (!simple) Text('${run.percent}%', style: text.headlineSmall),
        Text(
          '${'★' * stars}${'☆' * (3 - stars)}',
          semanticsLabel: l10n.mastersStars(stars),
          style: TextStyle(
            fontSize: 32,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(onPressed: onRetry, child: Text(l10n.mastersReplay)),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.mastersDone),
            ),
          ],
        ),
      ],
    );
  }
}
