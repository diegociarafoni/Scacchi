import 'package:dartchess/dartchess.dart';

import 'master_game.dart';

/// Stelle in base alla percentuale di mosse indovinate: tre da 70, due da 50.
/// Chi arriva in fondo ne ha comunque una.
int guessStars(int percent) => percent >= 70
    ? 3
    : percent >= 50
    ? 2
    : 1;

/// Esito di una mossa proposta: [matched] dice se coincide con quella giocata
/// dal maestro, [master].
class GuessResult {
  const GuessResult({required this.matched, required this.master});

  final bool matched;
  final Move master;
}

/// «Indovina la mossa» (RF-88): l'utente gioca le mosse di un lato della
/// partita e ognuna è confrontata con quella del maestro, che poi si gioca.
class GuessRun {
  GuessRun(this.game, this.side)
    : _positions = game.positions,
      _moves = game.moveList {
    total = [
      for (var i = 0; i < _moves.length; i++)
        if (_positions[i].turn == side) i,
    ].length;
  }

  final MasterGame game;
  final Side side;
  final List<Position> _positions;
  final List<Move> _moves;

  int _ply = 0;

  /// Mosse dell'utente nella partita.
  late final int total;
  int _correct = 0;
  int _attempts = 0;

  /// Mosse uguali a quelle del maestro.
  int get correct => _correct;

  /// Mosse proposte finora.
  int get attempts => _attempts;

  Position get position => _positions[_ply];

  /// Semimosse già giocate.
  int get ply => _ply;

  Move? get lastMove => _ply == 0 ? null : _moves[_ply - 1];

  bool get finished => _ply >= _moves.length;
  bool get userToMove => !finished && position.turn == side;

  /// Mossa del maestro nella posizione corrente.
  Move get expected => _moves[_ply];

  int get percent => total == 0 ? 0 : (_correct * 100 / total).round();
  int get stars => guessStars(percent);

  /// Gioca la mossa dell'utente e poi quella del maestro. Una mossa illegale
  /// lancia [ArgumentError] e non conta.
  GuessResult submit(Move move) {
    if (!userToMove) throw StateError('Non tocca all\'utente');
    if (!position.isLegal(move)) throw ArgumentError.value(move, 'move');
    final master = expected;
    final matched = _same(move, master);
    _attempts++;
    if (matched) _correct++;
    _ply++;
    return GuessResult(matched: matched, master: master);
  }

  /// Gioca la mossa dell'avversario nella partita storica.
  Move playOpponent() {
    if (finished || userToMove) throw StateError('Non tocca all\'avversario');
    return _moves[_ply++];
  }

  // L'arrocco può arrivare come re in g1 o come re sulla torre.
  bool _same(Move a, Move b) => a is NormalMove && b is NormalMove
      ? position.normalizeMove(a) == position.normalizeMove(b)
      : a == b;
}
