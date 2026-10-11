import 'package:dartchess/dartchess.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/review/game_review.dart';

// 1.e4 e5 2.Ac4 Cc6 3.Dh5 Cf6?? 4.Dxf7#
const scholar = ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7'];

List<Move> moves(List<String> uci) => [for (final m in uci) Move.parse(m)!];

/// Motore finto per i test della revisione: ogni mossa giocata è la migliore a +0.2, tranne dove indicato.
PositionEvaluator fakeEngine(
  List<String> game, {
  Map<int, List<InfoLine>> overrides = const {},
  List<String>? calls,
}) {
  final fens = <String, int>{};
  Position p = Chess.initial;
  for (var i = 0; i < game.length; i++) {
    fens[p.fen] = i;
    p = p.play(Move.parse(game[i])!);
  }
  return (fen) async {
    calls?.add(fen);
    final ply = fens[fen];
    if (ply == null) {
      return [const InfoLine(multipv: 1, pv: [], score: EngineScore.cp(0))];
    }
    return overrides[ply] ??
        [
          InfoLine(
            multipv: 1,
            depth: 12,
            pv: [game[ply]],
            score: EngineScore.cp(ply.isEven ? 20 : -20),
          ),
        ];
  };
}

/// Cf6 è un errore grave: g6 parava il matto, dopo Cf6 il Bianco matta in uno.
const scholarOverrides = {
  5: [
    InfoLine(multipv: 1, depth: 12, pv: ['g7g6'], score: EngineScore.cp(-30)),
  ],
  6: [
    InfoLine(multipv: 1, depth: 12, pv: ['h5f7'], score: EngineScore.mate(1)),
  ],
};
