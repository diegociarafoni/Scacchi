import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../progress/activity.dart';
import '../settings/settings.dart';
import '../training/training_board.dart';
import 'repertoire.dart';

/// Ripasso delle mosse in scadenza, una linea dopo l'altra (RF-93).
class RepertoireDrillPage extends StatefulWidget {
  const RepertoireDrillPage({
    super.key,
    required this.trainer,
    required this.side,
    this.onActivity,
  });

  /// Registra la sessione di ripasso nei progressi.
  final RecordActivity? onActivity;
  final RepertoireTrainer trainer;
  final Side side;

  @override
  State<RepertoireDrillPage> createState() => _RepertoireDrillPageState();
}

class _RepertoireDrillPageState extends State<RepertoireDrillPage> {
  RepertoireDrill? _drill;
  bool _showAnswer = false;
  int _revision = 0;
  int _reviewed = 0;

  /// Quale messaggio mostrare; il testo si compone a ogni build, nella lingua
  /// dell'app.
  _DrillMessage _message = _DrillMessage.prompt;

  @override
  void initState() {
    super.initState();
    _nextLine();
  }

  @override
  void dispose() {
    // Una sessione conta se si è risposto ad almeno una mossa.
    if (_reviewed > 0) {
      unawaited(widget.onActivity?.call(const RepertoireReviewed()));
    }
    super.dispose();
  }

  void _nextLine() {
    _drill = widget.trainer.nextDrill(widget.side);
    _showAnswer = false;
    _message = _drill == null ? _DrillMessage.done : _DrillMessage.prompt;
  }

  String _messageText(AppLocalizations l10n) => switch (_message) {
    _DrillMessage.done => l10n.openingsDrillDone(_reviewed),
    _DrillMessage.wrong => l10n.openingsDrillWrong,
    _DrillMessage.prompt =>
      _drill!.isNew
          ? l10n.openingsDrillNew
          : l10n.openingsDrillPrompt(_drill!.line.name),
  };

  Future<void> _onMove(Move move) async {
    final drill = _drill;
    if (drill == null) return;
    final result = await drill.tryMove(move);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case DrillResult.illegal:
          _revision++;
        case DrillResult.wrong:
          _revision++;
          _showAnswer = true;
          _message = _DrillMessage.wrong;
        case DrillResult.correct:
          _reviewed++;
          _showAnswer = false;
          _message = _DrillMessage.prompt;
        case DrillResult.finished:
          _reviewed++;
          _nextLine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final drill = _drill;
    final expected = drill?.expected;
    final settings = AppSettings.of(context);
    final arrow = expected is NormalMove && (_showAnswer || drill!.isNew)
        ? settings.marks.arrow(settings.hintColor, expected.from, expected.to)
        : const <Shape>{};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.openingsDrillTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final size = math.min(c.maxWidth, c.maxHeight - 120);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _messageText(l10n),
                      key: const Key('drill-message'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                if (drill != null)
                  TrainingBoard(
                    size: size,
                    position: drill.position,
                    lastMove: drill.lastMove,
                    player: widget.side,
                    revision: _revision,
                    shapes: arrow,
                    onMove: _onMove,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _DrillMessage { prompt, wrong, done }
