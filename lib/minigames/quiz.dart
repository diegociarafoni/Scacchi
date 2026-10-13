import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';
import 'blind.dart';
import 'material_quiz.dart';

/// Domanda a scelta multipla di un minigioco.
class QuizItem {
  const QuizItem({
    this.intro,
    required this.prompt,
    this.fen,
    required this.revealFen,
    this.highlight,
    required this.choices,
    required this.answer,
  });

  /// Testo prima della domanda, per esempio le mosse da visualizzare.
  final String? intro;
  final String prompt;

  /// Posizione mostrata durante la domanda; `null` per giocare alla cieca.
  final String? fen;

  /// Posizione mostrata dopo la risposta.
  final String revealFen;
  final Square? highlight;
  final List<String> choices;

  /// Indice della scelta giusta.
  final int answer;
}

QuizItem blindItem(Random random, AppLocalizations l10n) {
  final q = BlindQuestion.generate(random);
  return QuizItem(
    intro: q.movesText,
    prompt: q.prompt(l10n),
    revealFen: q.position.board.fen,
    highlight: q.square,
    choices: [for (final c in q.choices) pieceLabel(l10n, c)],
    answer: q.choices.indexOf(q.answer),
  );
}

QuizItem materialItem(Random random, AppLocalizations l10n) {
  final q = MaterialQuestion.generate(random);
  final fen = q.position.board.fen;
  return QuizItem(
    prompt: l10n.minigamesMaterialPrompt,
    fen: fen,
    revealFen: fen,
    choices: [for (final c in q.choices) balanceLabel(l10n, c)],
    answer: q.choices.indexOf(q.answer),
  );
}
