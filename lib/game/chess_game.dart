import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import 'move_note.dart';
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
    this.clock,
    this.note,
  });

  final Move move;
  final String san;
  final Position after;

  /// Tempo residuo di chi ha mosso, dopo la mossa; `null` senza orologio
  /// (RF-67).
  final Duration? clock;

  /// Simbolo e commento personali sulla mossa (RF-55).
  final MoveNote? note;

  PlayedMove withNote(MoveNote? note) => PlayedMove(
    move: move,
    san: san,
    after: after,
    clock: clock,
    note: note == null || note.isEmpty ? null : note,
  );
}

/// Stato della partita: cronologia, annullamento e condizioni di fine partita.
/// Mossa legale e, se porta un pedone in ultima traversa, con il pezzo di promozione.
bool isPlayableMove(Position pos, Move move) =>
    pos.isLegal(move) &&
    !(move is NormalMove &&
        move.promotion == null &&
        pos.board.pawns.has(move.from) &&
        SquareSet.backranks.has(move.to));

class ChessGame {
  ChessGame({Position? initial, this.variant = Variant.standard})
    : initial =
          initial ?? initialPosition(variant, chess960Id: standardChess960Id) {
    // Le regole vengono dalla posizione: devono essere quelle della variante.
    if (this.initial.rule != variant.rule) {
      throw ArgumentError.value(
        variant,
        'variant',
        'diversa dalla posizione', // l10n-ok
      );
    }
  }

  /// Partita ricostruita da mosse già giocate, per esempio da un PGN. Ignora
  /// ripetizioni e regola delle 50 mosse non reclamate; `null` se una mossa è
  /// illegale o segue un matto o uno stallo.
  static ChessGame? replay(
    Position initial,
    Iterable<Move> moves, {
    Variant variant = Variant.standard,
    List<Duration?> clocks = const [],
    List<MoveNote?> notes = const [],
  }) {
    final game = ChessGame(initial: initial, variant: variant);
    final list = moves.toList();
    assert(
      clocks.isEmpty || clocks.length == list.length,
      'un tempo per ogni mossa, o nessuno', // l10n-ok
    );
    assert(
      notes.isEmpty || notes.length == list.length,
      'una nota per ogni mossa, o nessuna', // l10n-ok
    );
    var i = 0;
    for (final move in list) {
      final pos = game.position;
      if (pos.isGameOver || !isPlayableMove(pos, move)) return null;
      final (after, san) = pos.makeSan(move);
      game._moves.add(
        PlayedMove(
          move: move,
          san: san,
          after: after,
          clock: i < clocks.length ? clocks[i] : null,
          note: i < notes.length ? notes[i] : null,
        ),
      );
      i++;
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
  bool play(Move move, {Duration? clock}) {
    if (isOver || !isPlayableMove(position, move)) return false;
    final (after, san) = position.makeSan(move);
    _moves.add(PlayedMove(move: move, san: san, after: after, clock: clock));
    return true;
  }

  /// Sostituisce la nota della mossa [ply]; `null` o una nota vuota la tolgono.
  void annotate(int ply, MoveNote? note) {
    RangeError.checkValidIndex(ply, _moves);
    _moves[ply] = _moves[ply].withNote(note);
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
