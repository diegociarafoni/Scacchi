import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import 'variant.dart';

/// Motivo per cui la partita è terminata.
enum GameEndReason {
  checkmate,
  stalemate,
  insufficientMaterial,
  threefoldRepetition,
  fiftyMoveRule,
  resignation,
  agreement,
  timeout,

  /// Vittoria propria della variante: re al centro, terzo scacco.
  variantEnd,
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

/// Stato della partita: cronologia, annullamento e condizioni di fine partita.
class ChessGame {
  ChessGame({Position? initial, this.variant = Variant.standard})
    : initial =
          initial ?? initialPosition(variant, chess960Id: standardChess960Id) {
    // Le regole vengono dalla posizione: devono essere quelle della variante.
    if (this.initial.rule != variant.rule) {
      throw ArgumentError.value(variant, 'variant', 'diversa dalla posizione');
    }
  }

  /// Partita ricostruita da mosse già giocate, per esempio da un PGN. Ignora
  /// ripetizioni e regola delle 50 mosse non reclamate; `null` se una mossa è
  /// illegale o segue un matto o uno stallo.
  static ChessGame? replay(
    Position initial,
    Iterable<Move> moves, {
    Variant variant = Variant.standard,
  }) {
    final game = ChessGame(initial: initial, variant: variant);
    for (final move in moves) {
      final pos = game.position;
      if (pos.isGameOver || !pos.isLegal(move)) return null;
      final (after, san) = pos.makeSan(move);
      game._moves.add(PlayedMove(move: move, san: san, after: after));
    }
    return game;
  }

  final Position initial;
  final Variant variant;
  final List<PlayedMove> _moves = [];
  Side? _resigned;
  bool _drawAgreed = false;
  Side? _flagged;

  List<PlayedMove> get moves => List.unmodifiable(_moves);

  Position get position => _moves.isEmpty ? initial : _moves.last.after;

  Move? get lastMove => _moves.isEmpty ? null : _moves.last.move;

  bool get canUndo =>
      _moves.isNotEmpty || _resigned != null || _drawAgreed || _flagged != null;

  /// Gioca [move] se è legale. Restituisce `false` se la mossa viene rifiutata.
  bool play(Move move) {
    if (isOver || !position.isLegal(move)) return false;
    final (after, san) = position.makeSan(move);
    _moves.add(PlayedMove(move: move, san: san, after: after));
    return true;
  }

  /// Revoca abbandono, patta concordata o tempo scaduto se presenti, altrimenti toglie l'ultima mossa.
  void undo() {
    if (_resigned != null || _drawAgreed || _flagged != null) {
      _resigned = null;
      _drawAgreed = false;
      _flagged = null;
    } else if (_moves.isNotEmpty) {
      _moves.removeLast();
    }
  }

  void resign(Side side) {
    if (!isOver) _resigned = side;
  }

  void agreeDraw() {
    if (!isOver) _drawAgreed = true;
  }

  /// Registra il tempo scaduto per [side].
  void flag(Side side) {
    if (!isOver) _flagged = side;
  }

  GameEndReason? get endReason {
    if (_resigned != null) return GameEndReason.resignation;
    if (_drawAgreed) return GameEndReason.agreement;
    if (_flagged != null) return GameEndReason.timeout;
    final pos = position;
    if (pos.isVariantEnd) return GameEndReason.variantEnd;
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
    GameEndReason.timeout =>
      position.hasInsufficientMaterial(_flagged!.opposite)
          ? Outcome.draw
          : Outcome(winner: _flagged!.opposite),
    GameEndReason.variantEnd => position.variantOutcome,
    _ => Outcome.draw,
  };

  /// Confronta solo le posizioni successive all'ultima cattura o mossa di pedone.
  bool get _isThreefoldRepetition {
    final positions = [initial, for (final m in _moves) m.after];
    final last = positions.length - 1;
    final first = math.max(0, last - position.halfmoves);
    if (last - first < 8) return false;
    final current = _repetitionKey(position);
    var count = 0;
    for (var i = first; i <= last; i++) {
      if (_repetitionKey(positions[i]) == current) count++;
    }
    return count >= 3;
  }

  /// Chiave di confronto per la ripetizione: la FEN senza i contatori delle
  /// mosse, quindi con gli scacchi rimasti a Tre scacchi.
  static String _repetitionKey(Position pos) {
    final fields = pos.fen.split(' ');
    return fields.take(fields.length - 2).join(' ');
  }
}
