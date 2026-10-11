import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../game/material.dart';
import 'blind.dart';

/// Materiale del bianco meno quello del nero.
int materialBalance(Board board) {
  int score(Side side) => board
      .materialCount(side)
      .entries
      .fold(0, (sum, e) => sum + e.value * pieceValues[e.key]!);
  return score(Side.white) - score(Side.black);
}

String balanceLabel(int balance) => balance == 0
    ? 'Pari'
    : balance > 0
    ? 'Bianco +$balance'
    : 'Nero +${-balance}';

/// Domanda di conta del materiale su una posizione nata da una partita
/// casuale, con catture favorite per creare squilibri.
class MaterialQuestion {
  const MaterialQuestion({required this.position, required this.choices});

  factory MaterialQuestion.generate(Random random) {
    Position pos;
    do {
      pos = _randomGame(random, 20 + random.nextInt(30));
    } while (pos.isGameOver);
    final answer = materialBalance(pos.board);
    final distractors = {
      for (final d in [1, -1, 2, -2, 3, -3, 5, -5]) answer + d,
      -answer,
    }..remove(answer);
    final choices = [answer, ...(distractors.toList()..shuffle(random)).take(3)]
      ..shuffle(random);
    return MaterialQuestion(position: pos, choices: choices);
  }

  final Position position;
  final List<int> choices;

  int get answer => materialBalance(position.board);
}

Position _randomGame(Random random, int plies) {
  Position pos = Chess.initial;
  for (var i = 0; i < plies && !pos.isGameOver; i++) {
    final moves = legalMoves(pos);
    final captures = [
      for (final m in moves)
        if (pos.board.pieceAt(m.to) != null) m,
    ];
    final pool = captures.isNotEmpty && random.nextBool() ? captures : moves;
    pos = pos.play(pool[random.nextInt(pool.length)]);
  }
  return pos;
}
