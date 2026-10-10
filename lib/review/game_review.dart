import 'package:dartchess/dartchess.dart';

import '../engine/uci.dart';
import 'accuracy.dart' as acc;
import 'move_classification.dart';
import 'sacrifice.dart';
import 'win_probability.dart';

/// Varianti del motore per la posizione [fen], dal punto di vista di chi
/// muove, ordinate per `multipv`.
typedef PositionEvaluator = Future<List<InfoLine>> Function(String fen);

/// Esito della revisione di una singola mossa.
class MoveReview {
  const MoveReview({
    required this.ply,
    required this.side,
    required this.move,
    required this.san,
    required this.fenBefore,
    required this.classification,
    required this.winBefore,
    required this.winAfter,
    required this.accuracy,
    this.bestMove,
    this.bestSan,
    this.bestLine = const [],
  });

  /// Indice della mossa a partire da 0.
  final int ply;
  final Side side;
  final Move move;
  final String san;
  final String fenBefore;
  final MoveClass classification;

  /// Probabilità di vittoria di chi muove con la mossa migliore e con quella
  /// giocata.
  final double winBefore;
  final double winAfter;
  final double accuracy;

  /// Mossa migliore secondo il motore e sua variante in UCI.
  final Move? bestMove;
  final String? bestSan;
  final List<String> bestLine;

  bool get playedBest => bestSan == san;
}

class GameReview {
  const GameReview({required this.moves, required this.whiteWinCurve});

  final List<MoveReview> moves;

  /// Probabilità di vittoria del Bianco per ogni posizione, iniziale compresa.
  final List<double> whiteWinCurve;

  Iterable<MoveReview> _of(Side side) => moves.where((m) => m.side == side);

  double? accuracy(Side side) =>
      acc.gameAccuracy([for (final m in _of(side)) m.accuracy]);

  int count(Side side, MoveClass c) =>
      _of(side).where((m) => m.classification == c).length;

  int estimatedElo(Side side) => acc.estimatedElo(accuracy(side) ?? 0);

  /// Indici delle mosse da evidenziare nel grafico.
  List<int> get keyMoments => [
    for (final m in moves)
      if (_keyClasses.contains(m.classification)) m.ply,
  ];

  static const _keyClasses = {
    MoveClass.brilliant,
    MoveClass.great,
    MoveClass.miss,
    MoveClass.mistake,
    MoveClass.blunder,
  };
}

/// Analizza tutte le posizioni della partita e classifica ogni mossa.
/// Restituisce `null` se [isCancelled] diventa vero.
Future<GameReview?> reviewGame({
  required Position initial,
  required List<Move> moves,
  required PositionEvaluator evaluate,
  void Function(int done, int total)? onProgress,
  bool Function()? isCancelled,
  bool Function(int ply)? isBook,
}) async {
  final positions = <Position>[initial];
  for (final m in moves) {
    positions.add(positions.last.play(m));
  }
  final total = positions.length;
  onProgress?.call(0, total);

  final lines = <List<InfoLine>>[];
  final wins = <double>[];
  for (var i = 0; i < total; i++) {
    if (isCancelled?.call() ?? false) return null;
    final pos = positions[i];
    final terminal = _terminalScore(pos);
    final l = terminal == null ? await evaluate(pos.fen) : const <InfoLine>[];
    lines.add(l);
    wins.add(
      winPercent(terminal ?? l.firstOrNull?.score ?? const EngineScore.cp(0)),
    );
    onProgress?.call(i + 1, total);
  }

  final reviews = <MoveReview>[];
  double? previousLoss;
  for (var i = 0; i < moves.length; i++) {
    final before = positions[i];
    final move = moves[i];
    final (_, san) = before.makeSan(move);
    final winBefore = wins[i];
    final winAfter = 100 - wins[i + 1];

    final best = lines[i].firstOrNull;
    final bestMove = _parse(before, best?.pv.firstOrNull);
    final bestSan = bestMove == null ? null : before.makeSan(bestMove).$2;
    final second = lines[i].elementAtOrNull(1)?.score;

    final facts = MoveFacts(
      winBefore: winBefore,
      winAfter: winAfter,
      isBestMove: bestSan == san,
      secondBestWin: second == null ? null : winPercent(second),
      isSacrifice: isSacrifice(
        before,
        move,
        lines[i + 1].firstOrNull?.pv ?? const [],
      ),
      isBook: isBook?.call(i) ?? false,
      opponentPreviousLoss: previousLoss,
    );
    reviews.add(
      MoveReview(
        ply: i,
        side: before.turn,
        move: move,
        san: san,
        fenBefore: before.fen,
        classification: classifyMove(facts),
        winBefore: winBefore,
        winAfter: winAfter,
        accuracy: acc.moveAccuracy(winBefore, winAfter),
        bestMove: bestMove,
        bestSan: bestSan,
        bestLine: best?.pv ?? const [],
      ),
    );
    previousLoss = facts.loss;
  }

  return GameReview(
    moves: reviews,
    whiteWinCurve: [
      for (var i = 0; i < total; i++)
        positions[i].turn == Side.white ? wins[i] : 100 - wins[i],
    ],
  );
}

EngineScore? _terminalScore(Position pos) {
  if (pos.isCheckmate) return const EngineScore.mate(0);
  if (pos.isStalemate || pos.isInsufficientMaterial) {
    return const EngineScore.cp(0);
  }
  return null;
}

Move? _parse(Position pos, String? uci) {
  final m = uci == null ? null : Move.parse(uci);
  if (m == null) return null;
  final move = m is NormalMove ? pos.normalizeMove(m) : m;
  return pos.isLegal(move) ? move : null;
}
