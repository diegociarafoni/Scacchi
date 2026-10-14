import 'dart:collection';

import 'package:dartchess/dartchess.dart';

/// Esercizio di una tappa del percorso.
sealed class Exercise {
  const Exercise();
}

/// Un pezzo bianco da solo raccoglie le stelle sulla scacchiera.
class StarsExercise extends Exercise {
  const StarsExercise({
    required this.role,
    required this.start,
    required this.stars,
  });

  final Role role;
  final Square start;
  final List<Square> stars;

  /// Minimo di mosse per raccogliere tutte le stelle, in qualunque ordine.
  int get optimalMoves {
    final targets = {for (final (i, s) in stars.indexed) s: i};
    final all = (1 << stars.length) - 1;
    final seen = <(Square, Role, int)>{(start, role, 0)};
    final queue = Queue.of([(start, role, 0, 0)]);
    while (queue.isNotEmpty) {
      final (sq, r, mask, depth) = queue.removeFirst();
      for (final to in pieceDests(r, sq)) {
        final i = targets[to];
        final next = i == null ? mask : mask | (1 << i);
        if (next == all) return depth + 1;
        final role = promoted(r, to);
        if (seen.add((to, role, next))) queue.add((to, role, next, depth + 1));
      }
    }
    return -1;
  }
}

/// Case raggiungibili da [role] in [square] su una scacchiera vuota.
Set<Square> pieceDests(Role role, Square square) {
  const empty = SquareSet.empty;
  final attacks = switch (role) {
    Role.rook => rookAttacks(square, empty),
    Role.bishop => bishopAttacks(square, empty),
    Role.queen => queenAttacks(square, empty),
    Role.knight => knightAttacks(square),
    Role.king => kingAttacks(square),
    Role.pawn => _pawnPushes(square),
  };
  return attacks.squares.toSet();
}

SquareSet _pawnPushes(Square square) {
  final rank = square.value >> 3;
  if (rank == 7) return SquareSet.empty;
  var set = SquareSet.fromSquare(Square(square.value + 8));
  if (rank == 1) set = set.withSquare(Square(square.value + 16));
  return set;
}

/// Il pedone che arriva in ottava diventa donna.
Role promoted(Role role, Square to) =>
    role == Role.pawn && to.value >> 3 == 7 ? Role.queen : role;

/// Stelle da 1 a 3: tre al minimo di mosse, due con poco scarto.
int starsForMoves(int moves, int optimal) => moves <= optimal
    ? 3
    : moves <= optimal + 2
    ? 2
    : 1;

/// Svolgimento di un esercizio.
sealed class ExerciseRun {
  bool get done;

  /// Stelle da 1 a 3, valide a esercizio concluso.
  int get stars;

  static ExerciseRun start(Exercise exercise) => switch (exercise) {
    final StarsExercise e => StarsRun(e),
    final LineExercise e => LineRun(e),
  };
}

/// Svolgimento di uno [StarsExercise].
class StarsRun extends ExerciseRun {
  StarsRun(this.exercise)
    : square = exercise.start,
      role = exercise.role,
      remaining = [...exercise.stars],
      optimalMoves = exercise.optimalMoves;

  final StarsExercise exercise;
  final int optimalMoves;
  Square square;
  Role role;
  final List<Square> remaining;
  int moves = 0;

  Set<Square> get validMoves => done ? const {} : pieceDests(role, square);

  @override
  bool get done => remaining.isEmpty;

  /// Muove il pezzo in [to]; `false` se la mossa non è possibile.
  bool move(Square to) {
    if (!validMoves.contains(to)) return false;
    square = to;
    role = promoted(role, to);
    remaining.remove(to);
    moves++;
    return true;
  }

  @override
  int get stars => starsForMoves(moves, optimalMoves);
}

enum LineGoal {
  /// Basta dare matto: qualunque mossa che dà matto all'ultimo passo vale.
  mate,

  /// Vanno giocate le mosse indicate.
  line,

  /// Basta dare scacco: qualunque mossa che dà scacco all'ultimo passo vale.
  check,

  /// Vale ogni mossa dopo cui il pezzo in [LineExercise.guard] è difeso, anche
  /// se l'esercizio ne indica una sola: le alternative sono equivalenti.
  defend,
}

/// Posizione da cui trovare una sequenza di mosse. I passi pari sono del
/// giocatore (alternative separate da `|`, in UCI), quelli dispari sono le
/// risposte automatiche dell'avversario.
class LineExercise extends Exercise {
  const LineExercise({
    required this.fen,
    required this.steps,
    required this.goal,
    this.guard,
  }) : assert(goal != LineGoal.defend || guard != null);

  final String fen;
  final List<String> steps;
  final LineGoal goal;

  /// Casa del pezzo da difendere, per [LineGoal.defend] (un solo passo).
  final Square? guard;
}

enum MoveVerdict { wrong, correct, solved }

/// Svolgimento di un [LineExercise].
class LineRun extends ExerciseRun {
  LineRun(this.exercise)
    : position = Chess.fromSetup(Setup.parseFen(exercise.fen));

  final LineExercise exercise;
  Position position;
  int step = 0;
  int mistakes = 0;

  /// Ultima risposta automatica dell'avversario.
  Move? lastReply;

  /// Dopo l'ultima mossa sbagliata il pezzo da difendere non è più attaccato
  /// (si è spostato o l'attaccante è stato preso), ma non è difeso.
  bool savedWithoutDefending = false;

  @override
  bool get done => step >= exercise.steps.length;

  MoveVerdict play(Move move) {
    savedWithoutDefending = false;
    if (done || !position.isLegal(move)) return MoveVerdict.wrong;
    final san = position.makeSan(move).$2;
    final last = step == exercise.steps.length - 1;
    final after = position.play(move);
    // Dopo un'alternativa, quelle dell'altra scelta possono non essere legali.
    final expected = exercise.steps[step]
        .split('|')
        .map(Move.parse)
        .nonNulls
        .where(position.isLegal)
        .toList();
    final ok =
        expected.any((m) => position.makeSan(m).$2 == san) ||
        (last &&
            switch (exercise.goal) {
              LineGoal.mate => after.isCheckmate,
              // Lo scacco va dato con il pezzo che l'esercizio chiede.
              LineGoal.check =>
                after.isCheck && expected.any((m) => _role(m) == _role(move)),
              LineGoal.line => false,
              LineGoal.defend => _defends(move, after),
            });
    if (!ok) {
      mistakes++;
      if (exercise.goal == LineGoal.defend) {
        savedWithoutDefending = _isSafe(move, after);
      }
      return MoveVerdict.wrong;
    }
    position = after;
    step++;
    if (!done) {
      final reply = Move.parse(exercise.steps[step])!;
      position = position.play(reply);
      lastReply = reply;
      step++;
    }
    return done ? MoveVerdict.solved : MoveVerdict.correct;
  }

  /// Il pezzo da difendere, dopo [move], è su questa casa.
  Square _guardAfter(Move move) => switch (move) {
    NormalMove(:final from, :final to) when from == exercise.guard => to,
    _ => exercise.guard!,
  };

  /// Il pezzo resta al suo posto e un altro pezzo del giocatore lo difende.
  bool _defends(Move move, Position after) =>
      _guardAfter(move) == exercise.guard &&
      after.board.attacksTo(exercise.guard!, position.turn).isNotEmpty;

  /// Nessun pezzo avversario attacca più il pezzo da difendere né quello che
  /// è appena stato mosso (altrimenti si è solo cambiato il pezzo perso).
  bool _isSafe(Move move, Position after) {
    final opponent = position.turn.opposite;
    final moved = switch (move) {
      NormalMove(:final to) => to,
      DropMove(:final to) => to,
    };
    return after.board.attacksTo(_guardAfter(move), opponent).isEmpty &&
        after.board.attacksTo(moved, opponent).isEmpty;
  }

  Role? _role(Move move) => switch (move) {
    NormalMove(:final from) => position.board.roleAt(from),
    DropMove(:final role) => role,
  };

  @override
  int get stars => mistakes == 0
      ? 3
      : mistakes == 1
      ? 2
      : 1;
}
