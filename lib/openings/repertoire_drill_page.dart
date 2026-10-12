import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../settings/settings.dart';
import '../training/training_board.dart';
import 'repertoire.dart';

/// Ripasso delle mosse in scadenza, una linea dopo l'altra (RF-93).
class RepertoireDrillPage extends StatefulWidget {
  const RepertoireDrillPage({
    super.key,
    required this.trainer,
    required this.side,
  });

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
  String _message = '';

  @override
  void initState() {
    super.initState();
    _nextLine();
  }

  void _nextLine() {
    _drill = widget.trainer.nextDrill(widget.side);
    _showAnswer = false;
    _message = _drill == null
        ? 'Ripasso completato: $_reviewed mosse.'
        : _prompt(_drill!);
  }

  String _prompt(RepertoireDrill d) => d.isNew
      ? 'Nuova mossa: gioca quella indicata dalla freccia.'
      : 'Linea "${d.line.name}": qual è la tua mossa?';

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
          _message = 'Non è la mossa del repertorio: ecco quella giusta.';
        case DrillResult.correct:
          _reviewed++;
          _showAnswer = false;
          _message = _prompt(drill);
        case DrillResult.finished:
          _reviewed++;
          _nextLine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final drill = _drill;
    final expected = drill?.expected;
    final settings = AppSettings.of(context);
    final arrow = expected is NormalMove && (_showAnswer || drill!.isNew)
        ? settings.marks.arrow(settings.hintColor, expected.from, expected.to)
        : const <Shape>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Ripasso del repertorio')),
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
                      _message,
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
