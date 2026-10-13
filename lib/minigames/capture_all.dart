import 'dart:collection';
import 'dart:math';

import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';
import '../path/exercise.dart' show starsForMoves;

/// Pezzi dei turni, dal più semplice da guidare.
const _roles = [Role.rook, Role.bishop, Role.knight, Role.queen, Role.knight];

/// Scacchiera di "cattura tutto": un pezzo bianco e alcuni pedoni neri fermi.
/// I pezzi lunghi non scavalcano i pedoni: il primo sulla linea si cattura.
class CaptureAllBoard {
  const CaptureAllBoard({
    required this.role,
    required this.start,
    required this.targets,
  });

  /// Scacchiera casuale del turno [round]: i pedoni crescono turno dopo turno.
  factory CaptureAllBoard.random(Random random, {required int round}) {
    final role = _roles[round % _roles.length];
    final start = Square(random.nextInt(64));
    // L'alfiere raggiunge solo le case del proprio colore.
    bool reachable(Square s) =>
        role != Role.bishop || _isLight(s) == _isLight(start);
    final candidates = [
      for (var i = 0; i < 64; i++)
        if (i != start.value && reachable(Square(i))) Square(i),
    ]..shuffle(random);
    return CaptureAllBoard(
      role: role,
      start: start,
      targets: candidates.take(3 + round * 3 ~/ 4).toList(),
    );
  }

  final Role role;
  final Square start;
  final List<Square> targets;

  String instructions(AppLocalizations l10n) =>
      l10n.minigamesCaptureAllInstructions(role.name);

  /// Minimo di mosse per catturare tutti i pedoni.
  int get optimalMoves => solution.length;

  /// Una sequenza di case di arrivo più breve possibile; vuota se i pedoni
  /// non si possono catturare tutti.
  List<Square> get solution {
    final index = {for (final (i, s) in targets.indexed) s: i};
    final all = (1 << targets.length) - 1;
    SquareSet left(int mask) => SquareSet.fromSquares([
      for (final (i, s) in targets.indexed)
        if (mask & (1 << i) == 0) s,
    ]);
    final parent = <(Square, int), (Square, int)?>{(start, 0): null};
    final queue = Queue.of([(start, 0)]);
    while (queue.isNotEmpty) {
      final state = queue.removeFirst();
      final (square, mask) = state;
      for (final to in captureDests(role, square, left(mask))) {
        final i = index[to];
        final next = (to, i == null ? mask : mask | (1 << i));
        if (parent.containsKey(next)) continue;
        parent[next] = state;
        if (next.$2 == all) {
          final path = <Square>[];
          for (var s = next; s != (start, 0); s = parent[s]!) {
            path.add(s.$1);
          }
          return path.reversed.toList();
        }
        queue.add(next);
      }
    }
    return const [];
  }
}

/// Case raggiungibili da [role] in [from] con i pedoni [pawns] come ostacoli
/// catturabili.
Set<Square> captureDests(Role role, Square from, SquareSet pawns) =>
    switch (role) {
      Role.rook => rookAttacks(from, pawns),
      Role.bishop => bishopAttacks(from, pawns),
      Role.queen => queenAttacks(from, pawns),
      Role.knight => knightAttacks(from),
      Role.king || Role.pawn => kingAttacks(from),
    }.squares.toSet();

bool _isLight(Square s) => (s.file + s.rank) % 2 == 1;

/// Svolgimento di una scacchiera.
class CaptureAllRun {
  CaptureAllRun(this.board, {int? optimalMoves})
    : square = board.start,
      remaining = [...board.targets],
      optimalMoves = optimalMoves ?? board.optimalMoves;

  final CaptureAllBoard board;
  final int optimalMoves;
  Square square;
  final List<Square> remaining;
  int moves = 0;

  bool get done => remaining.isEmpty;

  Set<Square> get validMoves => done
      ? const {}
      : captureDests(board.role, square, SquareSet.fromSquares(remaining));

  /// Stelle da 1 a 3, valide a scacchiera finita.
  int get stars => starsForMoves(moves, optimalMoves);

  /// Muove il pezzo in [to]; `false` se la mossa non è possibile.
  bool move(Square to) {
    if (!validMoves.contains(to)) return false;
    square = to;
    remaining.remove(to);
    moves++;
    return true;
  }
}

/// Cinque scacchiere di fila; il punteggio è la somma delle stelle.
class CaptureAllSession {
  CaptureAllSession(this._random)
    : run = CaptureAllRun(CaptureAllBoard.random(_random, round: 0));

  static const rounds = 5;
  static const maxScore = rounds * 3;

  final Random _random;
  CaptureAllRun run;
  int round = 0;
  int score = 0;

  bool get done => round >= rounds;

  /// Chiude il turno con [stars] stelle e prepara la scacchiera successiva.
  void finishRound(int stars) {
    score += stars;
    round++;
    if (!done) {
      run = CaptureAllRun(CaptureAllBoard.random(_random, round: round));
    }
  }
}
