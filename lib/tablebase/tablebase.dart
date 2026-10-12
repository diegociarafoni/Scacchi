import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';

import 'tb_material.dart';
import 'tb_set.dart';
import 'tb_table.dart';

enum TbOutcome { win, draw, loss }

/// Valutazione esatta di una posizione dal punto di vista di chi muove.
class TbEvaluation {
  const TbEvaluation(this.outcome, [this.plies]);

  final TbOutcome outcome;

  /// Semimosse al matto con il gioco migliore di entrambi: nelle vittorie
  /// dispari, nelle sconfitte pari (0 se è già matto). Nulla nelle patte.
  final int? plies;

  /// Mosse al matto contate dal lato che vince: una vittoria in 3 semimosse
  /// è «matto in 2».
  int? get mateInMoves => plies == null ? null : (plies! + 1) ~/ 2;

  @override
  bool operator ==(Object other) =>
      other is TbEvaluation && other.outcome == outcome && other.plies == plies;

  @override
  int get hashCode => Object.hash(outcome, plies);

  @override
  String toString() => 'TbEvaluation($outcome, $plies)';
}

/// Una mossa legale con la valutazione della posizione che ne segue, dal
/// punto di vista di chi la gioca.
class TbMove {
  const TbMove(this.move, this.evaluation);

  final Move move;
  final TbEvaluation evaluation;
}

/// Finali perfetti: risultato esatto e mossa migliore per le posizioni con
/// al massimo quattro pezzi (re compresi), senza rete. Le tabelle si leggono
/// da un [TbSet] già popolato: la generazione e il salvataggio sono in
/// `TablebaseService`.
class Tablebase {
  Tablebase(this.tables);

  final TbSet tables;

  /// Materiale della posizione, o nullo se supera i quattro pezzi.
  static TbMaterial? materialOf(Position pos) {
    final white = <int>[];
    final black = <int>[];
    var count = 0;
    for (final (_, piece) in pos.board.pieces) {
      if (++count > 4) return null;
      if (piece.role == Role.king) continue;
      (piece.color == Side.white ? white : black).add(_role(piece.role));
    }
    final material = TbMaterial(white, black);
    return material.supported ? material : null;
  }

  static int _role(Role role) => switch (role) {
    Role.pawn => TbRole.pawn,
    Role.knight => TbRole.knight,
    Role.bishop => TbRole.bishop,
    Role.rook => TbRole.rook,
    Role.queen => TbRole.queen,
    Role.king => TbRole.king,
  };

  /// Vero se la posizione ha un materiale gestito (anche se l'archivio non è
  /// ancora stato generato).
  static bool covers(Position pos) => materialOf(pos) != null;

  /// Valutazione di [pos], o nulla se non è coperta o se manca l'archivio.
  /// Il diritto di arrocco e la presa en passant sono ignorati: non
  /// esistono con questi materiali.
  TbEvaluation? probe(Position pos) {
    final material = materialOf(pos);
    if (material == null || tables.table(material) == null) return null;
    return _evaluate(pos, material);
  }

  TbEvaluation? _evaluate(Position pos, TbMaterial material) {
    final colors = Int32List(4);
    final roles = Int32List(4);
    final squares = Int32List(4);
    var count = 0;
    for (final (square, piece) in pos.board.pieces) {
      colors[count] = piece.color == Side.white ? 0 : 1;
      roles[count] = _role(piece.role);
      squares[count] = square.value;
      count++;
    }
    final value = tables.lookup(
      colors,
      roles,
      squares,
      count,
      pos.turn == Side.white ? 0 : 1,
    );
    if (value == TbValue.illegal) return null;
    if (value == TbValue.draw) return const TbEvaluation(TbOutcome.draw);
    return TbEvaluation(
      TbValue.isWin(value) ? TbOutcome.win : TbOutcome.loss,
      value,
    );
  }

  /// Tutte le mosse legali, dalla migliore: prima quelle che vincono nel
  /// minor numero di mosse, poi le patte, poi le sconfitte più lunghe. Vuoto
  /// se la posizione non è coperta o se manca un archivio.
  List<TbMove> rankedMoves(Position pos) {
    final material = materialOf(pos);
    if (material == null || tables.table(material) == null) return const [];
    final result = <TbMove>[];
    for (final move in _legalMoves(pos)) {
      final next = pos.playUnchecked(move);
      final nextMaterial = materialOf(next);
      final TbEvaluation? after;
      if (nextMaterial == null) {
        after = null;
      } else if (nextMaterial.pieces == 2) {
        after = const TbEvaluation(TbOutcome.draw);
      } else {
        after = tables.table(nextMaterial) == null
            ? null
            : _evaluate(next, nextMaterial);
      }
      if (after == null) return const [];
      result.add(TbMove(move, _fromOpponent(after)));
    }
    result.sort((a, b) => _rank(b.evaluation).compareTo(_rank(a.evaluation)));
    return result;
  }

  /// La migliore mossa per chi muove, o nulla se non c'è.
  Move? bestMove(Position pos) {
    final ranked = rankedMoves(pos);
    return ranked.isEmpty ? null : ranked.first.move;
  }

  static TbEvaluation _fromOpponent(TbEvaluation after) =>
      switch (after.outcome) {
        TbOutcome.draw => after,
        TbOutcome.loss => TbEvaluation(TbOutcome.win, after.plies! + 1),
        TbOutcome.win => TbEvaluation(TbOutcome.loss, after.plies! + 1),
      };

  /// Più alto è meglio: vincere subito, poi vincere piano, patta, perdere
  /// tardi, perdere subito.
  static int _rank(TbEvaluation e) => switch (e.outcome) {
    TbOutcome.win => 1000 - e.plies!,
    TbOutcome.draw => 0,
    TbOutcome.loss => -1000 + e.plies!,
  };

  static Iterable<Move> _legalMoves(Position pos) sync* {
    for (final entry in pos.legalMoves.entries) {
      final piece = pos.board.pieceAt(entry.key);
      for (final to in entry.value.squares) {
        final lastRank = to.rank == Rank.first || to.rank == Rank.eighth;
        if (piece?.role == Role.pawn && lastRank) {
          for (final role in const [
            Role.queen,
            Role.rook,
            Role.bishop,
            Role.knight,
          ]) {
            yield NormalMove(from: entry.key, to: to, promotion: role);
          }
        } else {
          yield NormalMove(from: entry.key, to: to);
        }
      }
    }
  }
}
