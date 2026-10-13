import 'package:dartchess/dartchess.dart';

import '../engine/uci.dart';
import 'accuracy.dart' as acc;
import 'board_utils.dart';
import 'game_phase.dart';
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
    this.bestScore,
    this.secondBestScore,
    this.replyLine = const [],
    this.replyScore,
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

  /// Valutazione della mossa migliore, dal punto di vista di chi muove.
  final EngineScore? bestScore;

  /// Valutazione della seconda scelta del motore, se analizzata.
  final EngineScore? secondBestScore;

  /// Risposta prevista dell'avversario dopo la mossa giocata e sua
  /// valutazione dal punto di vista dell'avversario.
  final List<String> replyLine;
  final EngineScore? replyScore;

  /// La mossa giocata è la prima scelta del motore.
  final bool playedBest;

  Map<String, Object?> toJson() => {
    'ply': ply,
    'side': side.name,
    'move': move.uci,
    'san': san,
    'fenBefore': fenBefore,
    'class': classification.name,
    'winBefore': winBefore,
    'winAfter': winAfter,
    'accuracy': accuracy,
    'playedBest': playedBest,
    'bestMove': bestMove?.uci,
    'bestSan': bestSan,
    'bestLine': bestLine,
    'bestScore': _scoreToJson(bestScore),
    'secondBestScore': _scoreToJson(secondBestScore),
    'replyLine': replyLine,
    'replyScore': _scoreToJson(replyScore),
  };

  static MoveReview fromJson(Map<String, Object?> json) => MoveReview(
    ply: json['ply']! as int,
    side: Side.values.byName(json['side']! as String),
    move: Move.parse(json['move']! as String)!,
    san: json['san']! as String,
    fenBefore: json['fenBefore']! as String,
    classification: MoveClass.values.byName(json['class']! as String),
    winBefore: (json['winBefore']! as num).toDouble(),
    winAfter: (json['winAfter']! as num).toDouble(),
    accuracy: (json['accuracy']! as num).toDouble(),
    playedBest: json['playedBest']! as bool,
    bestMove: switch (json['bestMove']) {
      final String uci => Move.parse(uci),
      _ => null,
    },
    bestSan: json['bestSan'] as String?,
    bestLine: [for (final m in json['bestLine']! as List) m as String],
    bestScore: _scoreFromJson(json['bestScore']),
    secondBestScore: _scoreFromJson(json['secondBestScore']),
    replyLine: [for (final m in json['replyLine']! as List) m as String],
    replyScore: _scoreFromJson(json['replyScore']),
  );
}

Map<String, Object?>? _scoreToJson(EngineScore? s) => s == null
    ? null
    : {if (s.cp != null) 'cp': s.cp, if (s.mate != null) 'mate': s.mate};

EngineScore? _scoreFromJson(Object? json) {
  if (json is! Map) return null;
  final mate = json['mate'] as int?;
  return mate != null
      ? EngineScore.mate(mate)
      : EngineScore.cp(json['cp']! as int);
}

class GameReview {
  const GameReview({
    required this.moves,
    required this.whiteWinCurve,
    required this.whiteScores,
  });

  final List<MoveReview> moves;

  /// Probabilità di vittoria del Bianco per ogni posizione, iniziale compresa.
  final List<double> whiteWinCurve;

  /// Valutazione del motore per ogni posizione, dal punto di vista del Bianco.
  final List<EngineScore> whiteScores;

  Map<String, Object?> toJson() => {
    'moves': [for (final m in moves) m.toJson()],
    'whiteWinCurve': whiteWinCurve,
    'whiteScores': [for (final s in whiteScores) _scoreToJson(s)],
  };

  static GameReview fromJson(Map<String, Object?> json) => GameReview(
    moves: [
      for (final m in json['moves']! as List)
        MoveReview.fromJson((m as Map).cast()),
    ],
    whiteWinCurve: [
      for (final w in json['whiteWinCurve']! as List) (w as num).toDouble(),
    ],
    whiteScores: [
      for (final s in json['whiteScores']! as List) _scoreFromJson(s)!,
    ],
  );

  Iterable<MoveReview> _of(Side side) => moves.where((m) => m.side == side);

  double? accuracy(Side side) =>
      acc.gameAccuracy([for (final m in _of(side)) m.accuracy]);

  /// Precisione di [side] in ciascuna fase; `null` se in quella fase non ha
  /// mosse.
  Map<GamePhase, double?> accuracyByPhase(Side side) {
    final byPhase = {for (final p in GamePhase.values) p: <double>[]};
    for (final m in _of(side)) {
      byPhase[phaseOfFen(m.fenBefore)]!.add(m.accuracy);
    }
    return {for (final e in byPhase.entries) e.key: acc.gameAccuracy(e.value)};
  }

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
  final scores = <EngineScore>[];
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
      throw StateError(
        'Nessuna valutazione del motore per ${pos.fen}', // l10n-ok
      );
    }
    lines.add(l);
    scores.add(score);
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
    final bestMove = parseEngineMove(before, best?.pv.firstOrNull);
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
        bestScore: scores[i],
        secondBestScore: second,
        replyLine: lines[i + 1].firstOrNull?.pv ?? const [],
        replyScore: scores[i + 1],
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
    whiteScores: [
      for (var i = 0; i < total; i++)
        positions[i].turn == Side.white ? scores[i] : scores[i].negated,
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
