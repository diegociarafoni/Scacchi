import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import 'board_layout.dart';
import 'coordinates.dart';
import 'minigame.dart';

/// Allenatore delle coordinate a tempo: la scacchiera è senza lettere né
/// numeri, si tocca la casa indicata.
class CoordinatesPage extends StatefulWidget {
  const CoordinatesPage({
    super.key,
    required this.random,
    required this.onFinished,
  });

  final Random random;

  /// Chiamata alla fine di ogni sessione completa; chi esce prima la abbandona.
  final ValueChanged<MinigameResult> onFinished;

  @override
  State<CoordinatesPage> createState() => _CoordinatesPageState();
}

class _CoordinatesPageState extends State<CoordinatesPage> {
  Side _side = Side.white;
  CoordinateDrill? _drill;
  Timer? _timer;
  int _left = 0;
  (Square, bool)? _lastTap;

  bool get _running => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _drill = CoordinateDrill(widget.random);
      _left = CoordinateDrill.duration.inSeconds;
      _lastTap = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _left--);
      if (_left <= 0) _stop();
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _timer = null);
    widget.onFinished((
      score: _drill!.score,
      duration: CoordinateDrill.duration,
    ));
  }

  void _tap(Square square) {
    if (!_running) return;
    final correct = _drill!.answer(square);
    setState(() => _lastTap = (square, correct));
  }

  @override
  Widget build(BuildContext context) {
    final drill = _drill;
    final text = Theme.of(context).textTheme;
    final highlight = _lastTap;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.minigamesCoordinatesTitle)),
      body: BoardLayout(
        board: (size) => StaticChessboard(
          size: size,
          orientation: _side,
          fen: '8/8/8/8/8/8/8/8',
          onTouchedSquare: _tap,
          squareHighlights: {
            if (highlight != null)
              highlight.$1: SquareHighlight(
                details: HighlightDetails(
                  solidColor: AppSettings.of(context).answerColor(highlight.$2),
                ),
              ),
          },
        ),
        panel: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_running) ...[
              Semantics(
                liveRegion: true,
                label: l10n.minigamesCoordinatesTarget(drill!.target.name),
                child: ExcludeSemantics(
                  child: Text(
                    drill.target.name,
                    key: const Key('coordinate-target'),
                    textAlign: TextAlign.center,
                    style: text.displayMedium,
                  ),
                ),
              ),
              Text(
                l10n.minigamesCoordinatesScore(drill.score),
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              Text(
                l10n.minigamesCoordinatesSecondsLeft(_left),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              if (drill != null) ...[
                Text(
                  l10n.minigamesCoordinatesTimeUp,
                  textAlign: TextAlign.center,
                  style: text.titleLarge,
                ),
                Text(
                  l10n.minigamesCoordinatesSummary(drill.score, drill.mistakes),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ] else
                Text(l10n.minigamesCoordinatesIntro),
              const SizedBox(height: 12),
              SegmentedButton<Side>(
                segments: [
                  ButtonSegment(
                    value: Side.white,
                    label: Text(l10n.minigamesCoordinatesWhite),
                  ),
                  ButtonSegment(
                    value: Side.black,
                    label: Text(l10n.minigamesCoordinatesBlack),
                  ),
                ],
                selected: {_side},
                onSelectionChanged: (s) => setState(() => _side = s.first),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _start,
                child: Text(
                  drill == null
                      ? l10n.minigamesCoordinatesStart
                      : l10n.minigamesAgain,
                ),
              ),
              if (drill != null)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.minigamesDone),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
