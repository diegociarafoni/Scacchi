import 'dart:async';

import 'package:dartchess/dartchess.dart';

import '../engine/uci.dart';
import '../l10n/app_localizations.dart';
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
  const CoachHint({required this.from, this.to, this.promotion, this.san});

  final Square from;
  final Square? to;
  final Role? promotion;
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

  final _hinted = <String>{};

  /// Posizioni per cui è stato chiesto almeno un suggerimento: i due livelli
  /// sulla stessa posizione contano come uno.
  int get hintsUsed => _hinted.length;

  /// Con [kid] (profilo bambino, RP-06) la spiegazione non cita numeri.
  Future<MoveVerdict> judge(
    Position before,
    Move move, {
    AppLocalizations? kid,
  }) async {
    final review = await reviewGame(
      initial: before,
      moves: [move],
      evaluate: _evaluate,
    );
    final m = review!.moves.single;
    return MoveVerdict(
      m,
      explainMove(m, kid: kid),
      shouldWarn: warnsFor(m.classification, warnFrom),
    );
  }

  /// `null` se il motore non indica una mossa.
  Future<CoachHint?> hint(Position pos, HintLevel level) async {
    final lines = await _evaluate(pos.fen);
    final uci = lines.firstOrNull?.pv.firstOrNull;
    final best = parseEngineMove(pos, uci);
    if (best is! NormalMove) return null;
    _hinted.add(pos.fen);
    if (level == HintLevel.piece) return CoachHint(from: best.from);
    // In dartchess l'arrocco è "re sulla torre": la destinazione da mostrare
    // è quella dell'UCI.
    final shown = Move.parse(uci!) as NormalMove;
    return CoachHint(
      from: shown.from,
      to: shown.to,
      promotion: shown.promotion,
      san: pos.makeSan(best).$2,
    );
  }

  /// La mossa che l'avversario giocherebbe se toccasse a lui (RF-56), con la
  /// destinazione da mostrare (il re per l'arrocco). `null` sotto scacco o se
  /// il motore non indica nulla.
  Future<NormalMove?> threat(Position pos) async {
    final fen = threatFen(pos);
    if (fen == null) return null;
    final uci = (await _evaluate(fen)).firstOrNull?.pv.firstOrNull;
    if (uci == null) return null;
    final move = Move.parse(uci);
    return move is NormalMove ? move : null;
  }
}

/// L'occasione mancata non peggiora la posizione: si segnala nel commento,
/// senza fermare la partita. [from] è la categoria minima che avverte.
bool warnsFor(MoveClass c, MoveClass from) =>
    c.isError && c != MoveClass.miss && c.index >= from.index;

/// Evita di analizzare due volte la stessa posizione, per esempio il
/// suggerimento seguito dal giudizio sulla mossa. Le analisi fallite non
/// restano in cache.
PositionEvaluator _memoize(PositionEvaluator inner) {
  final cache = <String, Future<List<InfoLine>>>{};
  return (fen) async {
    final f = cache.putIfAbsent(fen, () => inner(fen));
    try {
      final lines = await f;
      // Un'analisi interrotta torna vuota: non va ricordata.
      if (lines.isEmpty) unawaited(cache.remove(fen));
      return lines;
    } catch (_) {
      unawaited(cache.remove(fen));
      rethrow;
    }
  };
}
