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

/// Partita dell'archivio già letta: mosse, risultato e filtri.
class _ParsedGame {
  _ParsedGame(this.side, this.opponent, this.score, this.moves);

  final Side side;
  final String opponent;
  final double score;
  final List<(Move, String)> moves;
}

/// Partite dell'archivio utili all'albero, lette una sola volta: cambiare i
/// filtri non rilegge i PGN.
class PersonalGames {
  PersonalGames._(this._games);

  /// Tiene le partite concluse con un colore dell'utente, con regole standard
  /// e dalla posizione iniziale.
  factory PersonalGames.from(Iterable<SavedGame> games) {
    final parsed = <_ParsedGame>[];
    for (final saved in games) {
      final mine = saved.playerSide;
      final score = saved.playerScore;
      if (mine == null ||
          score == null ||
          !saved.finished ||
          saved.mode == SavedGame.imported) {
        continue;
      }
      final record = importPgn(saved.pgn).games;
      if (record.isEmpty) continue;
      final game = record.first.game;
      if (game.moves.isEmpty ||
          game.variant != Variant.standard ||
          game.initial.fen != Chess.initial.fen) {
        continue;
      }
      parsed.add(
        _ParsedGame(mine, PersonalOpeningTree.opponentOf(saved), score, [
          for (final m in game.moves) (m.move, m.san),
        ]),
      );
    }
    return PersonalGames._(parsed);
  }

  final List<_ParsedGame> _games;

  bool get isEmpty => _games.isEmpty;

  /// Avversari delle partite considerate, senza doppioni.
  List<String> get opponents =>
      {for (final g in _games) g.opponent}.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  /// Albero delle partite che rispettano [side] e [opponent].
  PersonalOpeningTree tree({Side? side, String? opponent}) {
    final tree = PersonalOpeningTree._();
    for (final g in _games) {
      if (side != null && g.side != side) continue;
      if (opponent != null && g.opponent != opponent) continue;
      tree._add(g.moves, g.score);
    }
    return tree;
  }
}

/// Albero delle aperture costruito dalle partite concluse dell'utente (RF-96).
///
/// Le posizioni si confrontano per EPD, come nel libro delle aperture, quindi
/// le trasposizioni condividono le statistiche.
class PersonalOpeningTree {
  PersonalOpeningTree._();

  /// Albero delle partite di [games] che rispettano [side] e [opponent].
  factory PersonalOpeningTree.build(
    Iterable<SavedGame> games, {
    Side? side,
    String? opponent,
  }) => PersonalGames.from(games).tree(side: side, opponent: opponent);

  final Map<String, Map<String, PersonalMove>> _moves = {};

  /// Partite considerate.
  int games = 0;

  void _add(List<(Move, String)> moves, double score) {
    games++;
    final seen = <String>{};
    Position pos = Chess.initial;
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
}
