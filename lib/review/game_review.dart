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
    required this.playedBest,
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

  /// La mossa giocata è la prima scelta del motore.
  final bool playedBest;
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

  /// `null` se il lato non ha mosse.
  int? estimatedElo(Side side) {
    final a = accuracy(side);
    return a == null ? null : acc.estimatedElo(a);
  }

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
/// Restituisce `null` se [isCancelled] diventa vero; per fermare subito il
/// motore chi interrompe chiama anche `ComputerPlayer.stop`.
/// Lancia [StateError] se il motore non dà una valutazione.
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
  bool cancelled() => isCancelled?.call() ?? false;
  for (var i = 0; i < total; i++) {
    if (cancelled()) return null;
    final pos = positions[i];
    final terminal = _terminalScore(positions, i);
    final l = terminal == null ? await evaluate(pos.fen) : const <InfoLine>[];
    if (cancelled()) return null;
    final score = terminal ?? l.firstOrNull?.score;
    if (score == null) {
      throw StateError('Nessuna valutazione del motore per ${pos.fen}');
    }
    lines.add(l);
    wins.add(winPercent(score));
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

    final isBest = bestSan == san;
    final facts = MoveFacts(
      winBefore: winBefore,
      winAfter: winAfter,
      isBestMove: isBest,
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
        playedBest: isBest,
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

/// Valutazione delle posizioni che chiudono la partita. Ripetizione e regola
/// delle 50 mosse dipendono dalla cronologia, che il motore non vede.
EngineScore? _terminalScore(List<Position> positions, int i) {
  final pos = positions[i];
  if (pos.isCheckmate) return const EngineScore.mate(0);
  if (pos.isStalemate || pos.isInsufficientMaterial || pos.halfmoves >= 100) {
    return const EngineScore.cp(0);
  }
  final key = _repetitionKey(pos);
  final seen = positions.take(i + 1).where((p) => _repetitionKey(p) == key);
  return seen.length >= 3 ? const EngineScore.cp(0) : null;
}

String _repetitionKey(Position pos) => pos.fen.split(' ').take(4).join(' ');

Move? _parse(Position pos, String? uci) {
  final m = uci == null ? null : Move.parse(uci);
  if (m == null) return null;
  final move = m is NormalMove ? pos.normalizeMove(m) : m;
  return pos.isLegal(move) ? move : null;
}
