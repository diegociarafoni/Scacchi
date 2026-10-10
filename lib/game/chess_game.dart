import 'package:dartchess/dartchess.dart';

/// Motivo per cui la partita è terminata.
enum GameEndReason {
  checkmate,
  stalemate,
  insufficientMaterial,
  threefoldRepetition,
  fiftyMoveRule,
  resignation,
}

/// Una mossa giocata, con la notazione algebrica (SAN) e la posizione risultante.
class PlayedMove {
  const PlayedMove({
    required this.move,
    required this.san,
    required this.after,
  });

  final Move move;
  final String san;
  final Position after;
}

/// Stato di una partita di scacchi standard, indipendente dall'interfaccia.
///
/// Le regole di movimento vengono da `dartchess`; qui si aggiungono la
/// cronologia, l'annullamento delle mosse e le patte per ripetizione e per
/// la regola delle 50 mosse, che `dartchess` non rileva da sola.
class ChessGame {
  ChessGame({Position? initial}) : initial = initial ?? Chess.initial;

  final Position initial;
  final List<PlayedMove> _moves = [];
  Side? _resigned;

  List<PlayedMove> get moves => List.unmodifiable(_moves);

  Position get position => _moves.isEmpty ? initial : _moves.last.after;

  Move? get lastMove => _moves.isEmpty ? null : _moves.last.move;

  bool get canUndo => _moves.isNotEmpty;

  /// Gioca [move] se è legale. Restituisce `false` se la mossa viene rifiutata.
  bool play(Move move) {
    if (isOver || !position.isLegal(move)) return false;
    final (after, san) = position.makeSan(move);
    _moves.add(PlayedMove(move: move, san: san, after: after));
    return true;
  }

  void undo() {
    _resigned = null;
    if (_moves.isNotEmpty) _moves.removeLast();
  }

  void resign(Side side) {
    if (!isOver) _resigned = side;
  }

  GameEndReason? get endReason {
    if (_resigned != null) return GameEndReason.resignation;
    final pos = position;
    if (pos.isCheckmate) return GameEndReason.checkmate;
    if (pos.isStalemate) return GameEndReason.stalemate;
    if (pos.isInsufficientMaterial) return GameEndReason.insufficientMaterial;
    if (_isThreefoldRepetition) return GameEndReason.threefoldRepetition;
    if (pos.halfmoves >= 100) return GameEndReason.fiftyMoveRule;
    return null;
  }

  bool get isOver => endReason != null;

  Outcome? get outcome => switch (endReason) {
    null => null,
    GameEndReason.checkmate => Outcome(winner: position.turn.opposite),
    GameEndReason.resignation => Outcome(winner: _resigned!.opposite),
    _ => Outcome.draw,
  };

  bool get _isThreefoldRepetition {
    final current = _repetitionKey(position);
    var count = _repetitionKey(initial) == current ? 1 : 0;
    for (final m in _moves) {
      if (_repetitionKey(m.after) == current) count++;
    }
    return count >= 3;
  }

  /// Pezzi, tratto, arrocco ed en passant: i campi che contano per la ripetizione.
  static String _repetitionKey(Position pos) =>
      pos.fen.split(' ').take(4).join(' ');
}
