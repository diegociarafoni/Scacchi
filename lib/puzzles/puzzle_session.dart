import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import 'puzzle.dart';

enum PuzzleState { playing, solved }

enum PuzzleMoveResult { correct, solved, wrong, illegal }

/// Avanzamento di un giocatore dentro un singolo puzzle.
class PuzzleSession {
  PuzzleSession(this.puzzle)
    : _position = puzzle.start,
      _lastMove = puzzle.opponentMove;

  final Puzzle puzzle;
  Position _position;
  Move? _lastMove;
  int _ply = 0;
  bool _mistake = false;
  bool _revealed = false;
  PuzzleState _state = PuzzleState.playing;

  Position get position => _position;
  Move? get lastMove => _lastMove;
  PuzzleState get state => _state;

  /// Vero se almeno una mossa è stata mostrata con "Soluzione".
  bool get revealed => _revealed;

  /// Mosse che il giocatore deve trovare in tutto il puzzle.
  int get playerMoves => (_solution.length + 1) ~/ 2;

  /// Mosse del giocatore già giocate, anche mostrate con "Soluzione".
  int get playerMovesDone => math.min(playerMoves, (_ply + 1) ~/ 2);

  /// Vero se è stata giocata almeno una mossa sbagliata.
  bool get mistake => _mistake;

  /// Vero se il puzzle è stato risolto senza errori e senza vedere la soluzione.
  bool get firstTry => !_mistake && !_revealed;

  /// Ricomincia dalla posizione iniziale. Errori e soluzioni mostrate restano
  /// registrati, così un nuovo tentativo riuscito non vale "al primo colpo".
  void restart() {
    _position = puzzle.start;
    _lastMove = puzzle.opponentMove;
    _ply = 0;
    _state = PuzzleState.playing;
  }

  /// Vero quando tocca all'avversario rispondere.
  bool get awaitingReply =>
      _state == PuzzleState.playing && _ply.isOdd && _ply < _solution.length;

  List<Move> get _solution => puzzle.solution;

  Move? get _expected =>
      _state == PuzzleState.playing && _ply.isEven ? _solution[_ply] : null;

  PuzzleMoveResult tryMove(Move move) {
    final expected = _expected;
    if (expected == null || !_position.isLegal(move)) {
      return PuzzleMoveResult.illegal;
    }
    final after = _position.play(move);
    final isLast = _ply == _solution.length - 1;
    if (!_same(move, expected) && !(isLast && after.isCheckmate)) {
      _mistake = true;
      return PuzzleMoveResult.wrong;
    }
    _advance(move, after);
    return _state == PuzzleState.solved
        ? PuzzleMoveResult.solved
        : PuzzleMoveResult.correct;
  }

  /// Gioca la risposta dell'avversario e la restituisce.
  Move? playReply() {
    if (!awaitingReply) return null;
    final move = _solution[_ply];
    _advance(move, _position.play(move));
    return move;
  }

  Square? hint() {
    final expected = _expected;
    if (expected is! NormalMove) return null;
    return expected.from;
  }

  /// Gioca la mossa corretta al posto del giocatore.
  Move? showNextMove() {
    final expected = _expected;
    if (expected == null) return null;
    _revealed = true;
    _advance(expected, _position.play(expected));
    return expected;
  }

  void _advance(Move move, Position after) {
    _position = after;
    _lastMove = move;
    _ply++;
    if (_ply >= _solution.length) _state = PuzzleState.solved;
  }

  bool _same(Move a, Move b) {
    if (a is NormalMove && b is NormalMove) {
      return _position.normalizeMove(a) == _position.normalizeMove(b);
    }
    return a == b;
  }
}
