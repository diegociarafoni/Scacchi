import 'package:dartchess/dartchess.dart';

import '../engine/uci.dart';
import '../review/board_utils.dart';
import '../review/coach.dart';
import '../review/game_review.dart';
import '../review/move_classification.dart';

/// Giudizio dell'allenatore su una mossa appena giocata.
class MoveVerdict {
  const MoveVerdict(this.review, this.comment, {required this.shouldWarn});

  final MoveReview review;
  final CoachComment? comment;

  /// La mossa è abbastanza debole da fermare l'utente e offrirgli di
  /// riprenderla.
  final bool shouldWarn;
}

enum HintLevel { piece, move }

/// Suggerimento a livelli: prima solo il pezzo da muovere, poi la mossa.
class CoachHint {
  const CoachHint({required this.from, this.to, this.san});

  final Square from;
  final Square? to;
  final String? san;
}

/// Allenatore della partita in corso (RF-72…RF-75): riusa la
/// classificazione e le spiegazioni della revisione, ma una mossa alla volta.
class CoachSession {
  CoachSession({
    required PositionEvaluator evaluate,
    this.warnFrom = MoveClass.mistake,
  }) : _evaluate = _memoize(evaluate);

  final PositionEvaluator _evaluate;

  /// Categoria minima che fa scattare l'avviso.
  final MoveClass warnFrom;

  int hintsUsed = 0;

  Future<MoveVerdict> judge(Position before, Move move) async {
    final review = await reviewGame(
      initial: before,
      moves: [move],
      evaluate: _evaluate,
    );
    final m = review!.moves.single;
    return MoveVerdict(m, explainMove(m), shouldWarn: _warns(m.classification));
  }

  // L'occasione mancata non peggiora la posizione: si segnala nel commento,
  // senza fermare la partita.
  bool _warns(MoveClass c) =>
      (c == MoveClass.mistake || c == MoveClass.blunder) &&
      c.index >= warnFrom.index;

  /// `null` se il motore non indica una mossa.
  Future<CoachHint?> hint(Position pos, HintLevel level) async {
    final lines = await _evaluate(pos.fen);
    final best = parseEngineMove(pos, lines.firstOrNull?.pv.firstOrNull);
    if (best is! NormalMove) return null;
    hintsUsed++;
    if (level == HintLevel.piece) return CoachHint(from: best.from);
    return CoachHint(from: best.from, to: best.to, san: pos.makeSan(best).$2);
  }
}

/// Evita di analizzare due volte la stessa posizione, per esempio il
/// suggerimento seguito dal giudizio sulla mossa.
PositionEvaluator _memoize(PositionEvaluator inner) {
  final cache = <String, Future<List<InfoLine>>>{};
  return (fen) => cache.putIfAbsent(fen, () => inner(fen));
}
