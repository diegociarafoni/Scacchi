import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import 'choose.dart';
import 'computer_player.dart';
import 'levels.dart';
import 'uci.dart';

/// Esegue [task] lontano dal thread dell'interfaccia; nei test, in linea.
typedef SearchRunner = Future<R> Function<R>(R Function() task);

/// Avversario per Chess960, Re della collina e Tre scacchi (RF-123). Stockfish
/// non conosce le ultime due, quindi la ricerca (alfa-beta con quiescenza) usa
/// le regole di dartchess, che valgono per ogni variante. Vedi
/// docs/avversario-computer.md.
class VariantEngine {
  VariantEngine({math.Random? random, SearchRunner? runner})
    : _random = random ?? math.Random(),
      _runner = runner ?? Isolate.run;

  final math.Random _random;
  final SearchRunner _runner;
  int _epoch = 0;

  /// Scarta le ricerche in corso: il loro risultato non viene più consegnato.
  void stop() => _epoch++;

  /// Mossa del computer in [position]; `null` senza mosse legali o se la
  /// ricerca è stata fermata con [stop]. Con la [history] delle posizioni
  /// precedenti la partita riconosce le ripetizioni: le evita se è in
  /// vantaggio e le cerca se è in svantaggio.
  Future<EngineMove?> bestMove(
    Position position,
    EngineLevel level, {
    List<Position> history = const [],
  }) async {
    final epoch = _epoch;
    final started = Stopwatch()..start();
    final request = _Request(
      fen: position.fen,
      rule: position.rule.name,
      depth: _depthFor(level),
      budgetMs: (level.movetime < _maxThinking ? level.movetime : _maxThinking)
          .inMilliseconds,
      temperatureCp: level.temperatureCp,
      seed: _random.nextInt(1 << 31),
      history: [for (final p in history) p.fen],
    );
    final reply = await _runner(() => _chooseMove(request));
    if (epoch != _epoch) return null;
    final uci = reply.uci;
    if (uci == null) return null;
    final wait = level.minReply - started.elapsed;
    if (wait > Duration.zero) {
      await Future<void>.delayed(wait);
      if (epoch != _epoch) return null;
    }
    return EngineMove(
      move: Move.parse(uci)!,
      pv: [uci],
      score: _toScore(reply.score),
      depth: reply.depth,
    );
  }

  /// Valutazione di [position] dal punto di vista di chi muove.
  Future<EngineScore?> evaluate(
    Position position, {
    List<Position> history = const [],
  }) async {
    final epoch = _epoch;
    final request = _Request(
      fen: position.fen,
      rule: position.rule.name,
      depth: 3,
      budgetMs: 300,
      temperatureCp: 0,
      seed: 0,
      history: [for (final p in history) p.fen],
    );
    final reply = await _runner(() => _evaluate(request));
    return epoch != _epoch ? null : _toScore(reply.score);
  }

  /// Profondità dal livello: i livelli bassi guardano una o due mosse avanti
  /// e sbagliano anche per la temperatura, gli alti fino a cinque.
  static int _depthFor(EngineLevel level) => switch (level.approxElo) {
    < 1000 => 1,
    < 1500 => 2,
    < 1900 => 3,
    < 2300 => 4,
    _ => 5,
  };

  /// Oltre questo tempo il telefono sembrerebbe bloccato.
  static const _maxThinking = Duration(seconds: 3);
}

class _Request {
  const _Request({
    required this.fen,
    required this.rule,
    required this.depth,
    required this.budgetMs,
    required this.temperatureCp,
    required this.seed,
    this.history = const [],
  });

  final String fen;
  final String rule;
  final int depth;
  final int budgetMs;
  final int temperatureCp;
  final int seed;

  /// Posizioni (FEN) già comparse nella partita, prima di quella da muovere.
  final List<String> history;

  Position get position =>
      Position.setupPosition(Rule.values.byName(rule), Setup.parseFen(fen));
}

typedef _Reply = ({String? uci, int score, int depth});

const _mate = 30000;
const _mateBound = _mate - 256;

EngineScore _toScore(int score) {
  if (score.abs() < _mateBound) return EngineScore.cp(score);
  final plies = _mate - score.abs();
  return score > 0
      ? EngineScore.mate((plies + 1) ~/ 2)
      : EngineScore.mate(-(plies ~/ 2));
}

/// Ricerca alla radice, eseguita nell'isolate.
_Reply _chooseMove(_Request request) {
  final root = request.position;
  final search = _Search(request.budgetMs)..seed(request);
  final moves = search.orderedMoves(root);
  if (moves.isEmpty) return (uci: null, score: 0, depth: 0);
  if (request.temperatureCp > 0) {
    return _chooseWithNoise(request, search, root, moves);
  }
  var best = moves.first;
  var bestScore = 0;
  var reached = 0;
  for (var depth = 1; depth <= request.depth; depth++) {
    try {
      search.limited = depth > 1;
      var alpha = -_inf;
      var iterationBest = best;
      var iterationScore = -_inf;
      // La mossa migliore dell'iterazione precedente si prova per prima.
      final ordered = [best, ...moves.where((m) => m != best)];
      for (final move in ordered) {
        final score = -search.negamax(
          root.playUnchecked(move),
          depth - 1,
          -_inf,
          -alpha,
          1,
        );
        if (score > iterationScore) {
          iterationScore = score;
          iterationBest = move;
        }
        if (score > alpha) alpha = score;
      }
      best = iterationBest;
      bestScore = iterationScore;
      reached = depth;
      if (bestScore.abs() >= _mateBound) break;
    } on _OutOfTime {
      break;
    }
  }
  return (uci: best.uci, score: bestScore, depth: reached);
}

/// Livelli bassi: si valutano tutte le mosse e si sceglie con la temperatura,
/// come per le candidate di Stockfish.
_Reply _chooseWithNoise(
  _Request request,
  _Search search,
  Position root,
  List<Move> moves,
) {
  var scores = <Move, int>{};
  var reached = 0;
  for (var depth = 1; depth <= request.depth; depth++) {
    try {
      search.limited = depth > 1;
      final iteration = <Move, int>{
        for (final move in moves)
          move: -search.negamax(
            root.playUnchecked(move),
            depth - 1,
            -_inf,
            _inf,
            1,
          ),
      };
      scores = iteration;
      reached = depth;
    } on _OutOfTime {
      break;
    }
  }
  final lines = <InfoLine>[
    for (final (i, MapEntry(:key, :value)) in scores.entries.indexed)
      InfoLine(
        multipv: i + 1,
        pv: [key.uci],
        depth: reached,
        score: _toScore(value),
      ),
  ];
  final picked = chooseCandidate(
    lines,
    request.temperatureCp,
    math.Random(request.seed),
  )!;
  final pickedMove = moves.firstWhere((m) => m.uci == picked.pv.first);
  return (uci: pickedMove.uci, score: scores[pickedMove]!, depth: reached);
}

_Reply _evaluate(_Request request) {
  final root = request.position;
  final search = _Search(request.budgetMs)..seed(request);
  var score = 0;
  var reached = 0;
  for (var depth = 1; depth <= request.depth; depth++) {
    try {
      search.limited = depth > 1;
      score = search.negamax(root, depth, -_inf, _inf, 0);
      reached = depth;
    } on _OutOfTime {
      break;
    }
  }
  return (uci: null, score: score, depth: reached);
}

const _inf = 1000000;

class _OutOfTime implements Exception {
  const _OutOfTime();
}

const _values = {
  Role.pawn: 100,
  Role.knight: 320,
  Role.bishop: 330,
  Role.rook: 500,
  Role.queen: 900,
  Role.king: 0,
};

class _Search {
  _Search(this._budgetMs);

  final int _budgetMs;

  /// Quante volte ogni posizione è già comparsa, nella partita e nella linea
  /// in esame. Già la seconda comparsa vale patta (la regola ne chiede tre)
  /// per non far girare a vuoto la ricerca.
  final _seen = <int, int>{};

  void seed(_Request request) {
    for (final fen in request.history) {
      final key = _key(
        Position.setupPosition(
          Rule.values.byName(request.rule),
          Setup.parseFen(fen),
        ),
      );
      _seen[key] = (_seen[key] ?? 0) + 1;
    }
    final root = _key(request.position);
    _seen[root] = (_seen[root] ?? 0) + 1;
  }

  static int _key(Position pos) => Object.hash(
    pos.board,
    pos.turn,
    pos.castles.castlingRights,
    pos is ThreeCheck ? pos.remainingChecks : null,
  );
  final _clock = Stopwatch()..start();
  int _nodes = 0;

  /// Falso per la prima iterazione, che deve sempre finire.
  bool limited = false;

  void _tick() {
    if (limited &&
        (++_nodes & 127) == 0 &&
        _clock.elapsedMilliseconds >= _budgetMs) {
      throw const _OutOfTime();
    }
  }

  int negamax(Position pos, int depth, int alpha, int beta, int ply) {
    _tick();
    if (pos.isVariantEnd) return _variantEnd(pos, ply);
    if (pos.isInsufficientMaterial || pos.halfmoves >= 100) return 0;
    if (depth <= 0) return _quiesce(pos, alpha, beta, ply, 0);
    final key = _key(pos);
    // Una posizione già vista non era finita, quindi si può uscire prima di
    // generare le mosse.
    if (ply > 0 && (_seen[key] ?? 0) > 0) return 0;
    final moves = orderedMoves(pos);
    if (moves.isEmpty) return pos.isCheck ? ply - _mate : 0;
    _seen[key] = (_seen[key] ?? 0) + 1;
    var best = -_inf;
    try {
      for (final move in moves) {
        final score = -negamax(
          pos.playUnchecked(move),
          depth - 1,
          -beta,
          -alpha,
          ply + 1,
        );
        if (score > best) best = score;
        if (score > alpha) alpha = score;
        if (alpha >= beta) break;
      }
    } finally {
      _seen[key] = _seen[key]! - 1;
    }
    return best;
  }

  /// Chi ha la mossa ha perso: la variante finisce con la vittoria dell'altro.
  int _variantEnd(Position pos, int ply) =>
      pos.variantOutcome?.winner == pos.turn ? _mate - ply : ply - _mate;

  /// Solo mosse "calde" (catture, promozioni, scacchi a Tre scacchi, mosse del
  /// re verso la collina): senza, la valutazione si fiderebbe di posizioni
  /// nel mezzo di uno scambio.
  int _quiesce(Position pos, int alpha, int beta, int ply, int depth) {
    _tick();
    if (pos.isVariantEnd) return _variantEnd(pos, ply);
    if (pos.isInsufficientMaterial || pos.halfmoves >= 100) return 0;
    final inCheck = pos.isCheck;
    if (inCheck && depth < 6) {
      final moves = orderedMoves(pos);
      if (moves.isEmpty) return ply - _mate;
      var best = -_inf;
      for (final move in moves) {
        final score = -_quiesce(
          pos.playUnchecked(move),
          -beta,
          -alpha,
          ply + 1,
          depth + 1,
        );
        if (score > best) best = score;
        if (score > alpha) alpha = score;
        if (alpha >= beta) break;
      }
      return best;
    }
    final stand = evaluate(pos);
    if (depth >= 6) return stand;
    if (stand >= beta) return stand;
    if (stand > alpha) alpha = stand;
    var best = stand;
    for (final move in orderedMoves(pos, onlyHot: true, firstHot: depth == 0)) {
      final score = -_quiesce(
        pos.playUnchecked(move),
        -beta,
        -alpha,
        ply + 1,
        depth + 1,
      );
      if (score > best) best = score;
      if (score > alpha) alpha = score;
      if (alpha >= beta) break;
    }
    return best;
  }

  /// Mosse legali, con le promozioni a donna e a cavallo, ordinate: prima le
  /// catture più preziose con il pezzo meno prezioso.
  List<Move> orderedMoves(
    Position pos, {
    bool onlyHot = false,
    bool firstHot = false,
  }) {
    final board = pos.board;
    final scored = <(int, Move)>[];
    final hillGame = pos.rule == Rule.kingofthehill;
    final checkGame = pos.rule == Rule.threecheck;
    for (final MapEntry(key: from, value: targets) in pos.legalMoves.entries) {
      final piece = board.pieceAt(from)!;
      final promotes = piece.role == Role.pawn;
      for (final to in targets.squares) {
        final target = board.pieceAt(to);
        final captured = target != null && target.color != piece.color
            ? _values[target.role]!
            : (piece.role == Role.pawn &&
                      (from & 7) != (to & 7) &&
                      target == null
                  ? _values[Role.pawn]!
                  : 0);
        final rank = to >> 3;
        final last = promotes && (rank == 0 || rank == 7);
        var hot = captured > 0 || last;
        if (!hot && firstHot) {
          hot =
              (hillGame && piece.role == Role.king) ||
              (checkGame &&
                  pos.playUnchecked(NormalMove(from: from, to: to)).isCheck);
        }
        if (onlyHot && !hot) continue;
        final order = captured * 16 - _values[piece.role]!;
        if (last) {
          scored.add((
            order + 8000,
            NormalMove(from: from, to: to, promotion: Role.queen),
          ));
          scored.add((
            order,
            NormalMove(from: from, to: to, promotion: Role.knight),
          ));
        } else {
          scored.add((order, NormalMove(from: from, to: to)));
        }
      }
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final (_, move) in scored) move];
  }

  /// Valutazione statica dal punto di vista di chi muove, in centipedoni.
  int evaluate(Position pos) {
    var score = 0;
    var material = 0;
    final pieces = [...pos.board.pieces];
    for (final (_, piece) in pieces) {
      if (piece.role != Role.pawn && piece.role != Role.king) {
        material += _values[piece.role]!;
      }
    }
    final middlegame = material > 2400;
    for (final (square, piece) in pieces) {
      final file = square & 7;
      final rank = square >> 3;
      final relative = piece.color == Side.white ? rank : 7 - rank;
      // Distanza dal centro in mezze case: 1 al centro, 7 all'angolo.
      final fromCentre = ((2 * file - 7).abs() + (2 * rank - 7).abs()) ~/ 2;
      var value = _values[piece.role]!;
      switch (piece.role) {
        case Role.pawn:
          value += relative * 8 + (relative >= 5 ? 20 : 0);
          if (file >= 2 && file <= 5) value += 4;
        case Role.knight || Role.bishop:
          value += (7 - fromCentre) * 5 - (relative == 0 ? 12 : 0);
        case Role.queen:
          value += (7 - fromCentre) * 2;
        case Role.rook:
          value += relative == 6 ? 15 : 0;
        case Role.king:
          value += middlegame ? (relative == 0 ? 15 : 0) : (7 - fromCentre) * 8;
          if (pos.rule == Rule.kingofthehill) {
            value += _hillPull(file, rank) ~/ (middlegame ? 2 : 1);
          }
      }
      score += piece.color == Side.white ? value : -value;
    }
    if (pos is ThreeCheck) {
      final (whiteLeft, blackLeft) = pos.remainingChecks;
      score += _checkBonus[3 - whiteLeft.clamp(0, 3)];
      score -= _checkBonus[3 - blackLeft.clamp(0, 3)];
    }
    return (pos.turn == Side.white ? score : -score) + 10;
  }

  static const _checkBonus = [0, 60, 220, 0];

  /// Quanto vale per un re essere vicino alle quattro case centrali.
  static int _hillPull(int file, int rank) {
    final dFile = file < 3 ? 3 - file : (file > 4 ? file - 4 : 0);
    final dRank = rank < 3 ? 3 - rank : (rank > 4 ? rank - 4 : 0);
    final distance = math.max(dFile, dRank);
    return distance > 3 ? 0 : (3 - distance) * 30;
  }
}
