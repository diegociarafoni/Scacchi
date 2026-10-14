import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import '../theme/sheets.dart';
import 'minigame.dart';
import 'quiz.dart';

/// Sessione di dieci domande a scelta multipla, senza tempo.
class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.title,
    required this.next,
    required this.random,
    required this.onFinished,
  });

  static const questions = 10;

  final String title;
  final QuizItem Function(Random random, AppLocalizations l10n) next;
  final Random random;

  /// Chiamata con il numero di risposte giuste a fine sessione.
  final ValueChanged<MinigameResult> onFinished;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late QuizItem _item = widget.next(
    widget.random,
    AppLocalizations.of(context),
  );
  int _index = 0;
  int _score = 0;
  int? _chosen;
  bool _finished = false;
  final _clock = Stopwatch()..start();

  void _choose(int i) {
    if (_chosen != null) return;
    setState(() {
      _chosen = i;
      if (i == _item.answer) _score++;
    });
  }

  void _advance() {
    if (_index + 1 == QuizPage.questions) {
      setState(() => _finished = true);
      widget.onFinished((score: _score, duration: _clock.elapsed));
      return;
    }
    setState(() {
      _index++;
      _chosen = null;
      _item = widget.next(widget.random, AppLocalizations.of(context));
    });
  }

  void _again() {
    setState(() {
      _index = 0;
      _score = 0;
      _chosen = null;
      _finished = false;
      _item = widget.next(widget.random, AppLocalizations.of(context));
    });
    _clock.reset();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final item = _item;
    final chosen = _chosen;
    final fen = chosen == null ? item.fen : item.revealFen;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: _finished
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.minigamesQuizResult(_score, QuizPage.questions),
                      style: text.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _again,
                      child: Text(l10n.minigamesAgain),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.minigamesDone),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) => ListView(
                  padding: context.withSystemBottom(const EdgeInsets.all(16)),
                  children: [
                    Text(
                      l10n.minigamesQuizQuestion(
                        _index + 1,
                        QuizPage.questions,
                      ),
                      style: text.labelLarge,
                    ),
                    if (item.intro case final intro?) ...[
                      const SizedBox(height: 8),
                      Text(intro, style: text.titleMedium),
                    ],
                    if (fen != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: StaticChessboard(
                          size: min(constraints.maxWidth - 32, 360),
                          orientation: Side.white,
                          fen: fen,
                          settings: StaticChessboardSettings.fromBoardSettings(
                            AppSettings.of(context).exerciseBoard,
                          ),
                          squareHighlights: {
                            if (chosen != null && item.highlight != null)
                              item.highlight!: const SquareHighlight(
                                details: HighlightDetails(
                                  solidColor: Color(0x80F2B01E),
                                ),
                              ),
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(item.prompt, style: text.titleMedium),
                    const SizedBox(height: 8),
                    for (final (i, label) in item.choices.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton.icon(
                          key: Key('choice-$i'),
                          onPressed: chosen == null ? () => _choose(i) : null,
                          icon: Icon(
                            chosen == null
                                ? Icons.circle_outlined
                                : i == item.answer
                                ? Icons.check_circle
                                : i == chosen
                                ? Icons.cancel
                                : Icons.circle_outlined,
                          ),
                          label: Text(label),
                        ),
                      ),
                    if (chosen != null) ...[
                      Text(
                        chosen == item.answer
                            ? l10n.minigamesQuizCorrect
                            : l10n.minigamesQuizAnswer(
                                item.choices[item.answer],
                              ),
                        textAlign: TextAlign.center,
                        style: text.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _advance,
                        child: Text(l10n.minigamesNext),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
