import 'package:dartchess/dartchess.dart';

import '../archive/pgn.dart';
import '../archive/saved_game.dart';
import '../game/variant.dart';
import 'opening_book.dart';

/// Mossa giocata nelle partite dell'archivio da una posizione, con i risultati
/// visti da chi ha giocato.
class PersonalMove {
  PersonalMove(this.move, this.san);

  final Move move;
  final String san;
  int wins = 0;
  int draws = 0;
  int losses = 0;

  int get games => wins + draws + losses;
}

/// Albero delle aperture costruito dalle partite concluse dell'utente (RF-96).
///
/// Le posizioni si confrontano per EPD, come nel libro delle aperture, quindi
/// le trasposizioni condividono le statistiche.
class PersonalOpeningTree {
  PersonalOpeningTree._();

  /// Costruisce l'albero dalle partite concluse con un colore dell'utente.
  /// [side] e [opponent] restringono le partite considerate.
  factory PersonalOpeningTree.build(
    Iterable<SavedGame> games, {
    Side? side,
    String? opponent,
  }) {
    final tree = PersonalOpeningTree._();
    for (final saved in games) {
      final mine = saved.playerSide;
      if (mine == null || !saved.finished || saved.mode == SavedGame.imported) {
        continue;
      }
      if (side != null && mine != side) continue;
      if (opponent != null && opponentOf(saved) != opponent) continue;
      final score = saved.playerScore;
      final record = importPgn(saved.pgn).games;
      if (score == null || record.isEmpty) continue;
      final game = record.first.game;
      if (game.moves.isEmpty) continue;
      // Le varianti e le posizioni di partenza libere non hanno un albero.
      if (game.variant != Variant.standard ||
          game.initial.fen != Chess.initial.fen) {
        continue;
      }
      tree._add(game.initial, [
        for (final m in game.moves) (m.move, m.san),
      ], score);
    }
    return tree;
  }

  final Map<String, Map<String, PersonalMove>> _moves = {};

  /// Partite considerate.
  int games = 0;

  void _add(Position start, List<(Move, String)> moves, double score) {
    games++;
    final seen = <String>{};
    var pos = start;
    for (final (move, san) in moves) {
      final key = OpeningBook.key(pos);
      if (seen.add('$key|$san')) {
        final entry = _moves
            .putIfAbsent(key, () => {})
            .putIfAbsent(san, () => PersonalMove(move, san));
        if (score == 1) {
          entry.wins++;
        } else if (score == 0) {
          entry.losses++;
        } else {
          entry.draws++;
        }
      }
      pos = pos.play(move);
    }
  }

  /// Mosse giocate da [pos], dalla più frequente.
  List<PersonalMove> continuationsAt(Position pos) {
    final moves = _moves[OpeningBook.key(pos)];
    if (moves == null) return const [];
    return moves.values.toList()..sort(
      (a, b) => b.games != a.games
          ? b.games.compareTo(a.games)
          : a.san.compareTo(b.san),
    );
  }

  /// Nome dell'avversario in [game]; vuoto se non c'è un colore dell'utente.
  static String opponentOf(SavedGame game) => switch (game.playerSide) {
    Side.white => game.black,
    Side.black => game.white,
    null => '',
  };

  /// Avversari delle partite con un colore dell'utente, senza doppioni.
  static List<String> opponents(Iterable<SavedGame> games) => {
    for (final g in games)
      if (g.playerSide != null) opponentOf(g),
  }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
