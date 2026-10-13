import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import '../progress/activity.dart' show GameResult;
import '../progress/challenges.dart' show mix32;

/// Formula del torneo (RG-09).
enum TournamentFormat { roundRobin, knockout }

/// Partecipante: l'utente o un bot con il suo livello del motore.
class Player {
  const Player({required this.name, required this.elo, this.levelId});

  final String name;
  final int elo;

  /// Livello del motore che gioca per il bot; `null` per l'utente.
  final int? levelId;

  Map<String, Object?> toJson() => {
    'name': name,
    'elo': elo,
    'levelId': levelId,
  };

  static Player fromJson(Map<String, Object?> json) => Player(
    name: json['name']! as String,
    elo: json['elo']! as int,
    levelId: json['levelId'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is Player &&
      other.name == name &&
      other.elo == elo &&
      other.levelId == levelId;

  @override
  int get hashCode => Object.hash(name, elo, levelId);
}

/// I [count] bot più vicini a [userElo], dal più debole.
List<Player> chooseBots(
  List<Player> bots, {
  required int userElo,
  required int count,
}) {
  final byDistance = [...bots]
    ..sort((a, b) {
      final d = (a.elo - userElo).abs().compareTo((b.elo - userElo).abs());
      return d != 0 ? d : a.elo.compareTo(b.elo);
    });
  return byDistance.take(count).toList()
    ..sort((a, b) => a.elo.compareTo(b.elo));
}

/// Abbinamento di un turno. Senza [black] è un turno di riposo.
class Pairing {
  const Pairing({required this.white, this.black, this.result, this.tiebreak});

  final int white;
  final int? black;

  /// Punti del bianco (1, ½, 0) nella partita.
  final double? result;

  /// Punti del bianco nello spareggio Armageddon, giocato a colori invertiti:
  /// qui [white] ha il nero e la patta lo qualifica.
  final double? tiebreak;

  bool get isBye => black == null;

  bool includes(int player) => white == player || black == player;

  /// Vero se il risultato è deciso; nell'eliminazione diretta la patta
  /// richiede lo spareggio.
  bool decided(TournamentFormat format) =>
      isBye ||
      (result != null &&
          (format == TournamentFormat.roundRobin ||
              result != 0.5 ||
              tiebreak != null));

  /// Chi passa il turno nell'eliminazione diretta.
  int? get winner {
    if (isBye) return white;
    if (result == null) return null;
    if (result != 0.5) return result == 1 ? white : black;
    if (tiebreak == null) return null;
    // Nell'Armageddon [white] ha il nero: gli basta la patta.
    return tiebreak! >= 0.5 ? white : black;
  }

  Pairing copyWith({double? result, double? tiebreak}) => Pairing(
    white: white,
    black: black,
    result: result ?? this.result,
    tiebreak: tiebreak ?? this.tiebreak,
  );

  Map<String, Object?> toJson() => {
    'w': white,
    'b': black,
    'r': result,
    't': tiebreak,
  };

  static Pairing fromJson(Map<String, Object?> json) => Pairing(
    white: json['w']! as int,
    black: json['b'] as int?,
    result: (json['r'] as num?)?.toDouble(),
    tiebreak: (json['t'] as num?)?.toDouble(),
  );
}

/// Prossima partita dell'utente.
class UserGame {
  const UserGame({
    required this.opponent,
    required this.color,
    this.armageddon = false,
  });

  final Player opponent;
  final Side color;

  /// Spareggio dopo una patta: con il nero basta pattare.
  final bool armageddon;
}

/// Punti dell'utente per l'esito di [game]: 1, ½ o 0; nello spareggio
/// Armageddon la patta vale una vittoria per il nero e una sconfitta per il
/// bianco.
double tournamentPoints(GameResult result, UserGame game) => switch (result) {
  GameResult.win => 1,
  GameResult.loss => 0,
  _ when game.armageddon => game.color == Side.black ? 1 : 0,
  _ => 0.5,
};

/// Riga della classifica del girone.
class Standing {
  const Standing({
    required this.player,
    required this.points,
    required this.sonnebornBerger,
    required this.wins,
  });

  final int player;
  final double points;

  /// Somma dei punti degli avversari battuti più metà di quelli pattati.
  final double sonnebornBerger;
  final int wins;
}

/// Punti del bianco in una partita simulata tra bot, ripetibile dato il seme.
/// La patta è più probabile tra giocatori vicini.
double simulateGame(int whiteElo, int blackElo, {required int seed}) {
  final expected = 1 / (1 + math.pow(10, (blackElo - whiteElo) / 400));
  final draw = 0.3 * (1 - (2 * expected - 1).abs());
  final u = mix32(seed) / 0x100000000;
  final win = expected - draw / 2;
  return u < win
      ? 1
      : u < win + draw
      ? 0.5
      : 0;
}

/// Torneo offline contro bot: l'utente è sempre il giocatore 0 e gioca
/// partite vere; le partite tra bot si simulano in modo ripetibile.
class Tournament {
  const Tournament._({
    required this.format,
    required this.players,
    required this.seed,
    required this.createdAt,
    required this.rounds,
  });

  factory Tournament.create({
    required TournamentFormat format,
    required Player user,
    required List<Player> bots,
    required int seed,
    required DateTime createdAt,
  }) {
    final players = [user, ...bots];
    if (format == TournamentFormat.knockout &&
        players.length != 4 &&
        players.length != 8) {
      throw ArgumentError(
        'Eliminazione diretta con 4 o 8 giocatori',
      ); // l10n-ok
    }
    if (players.length < 3 || players.length > 8) {
      throw ArgumentError('Da 3 a 8 giocatori');
    }
    final t = Tournament._(
      format: format,
      players: players,
      seed: seed,
      createdAt: createdAt,
      rounds: const [],
    );
    final rounds = format == TournamentFormat.roundRobin
        ? _bergerRounds(players.length)
        : [t._firstKnockoutRound()];
    return t._with(rounds)._advance();
  }

  final TournamentFormat format;
  final List<Player> players;
  final int seed;
  final DateTime createdAt;
  final List<List<Pairing>> rounds;

  /// Indici dei giocatori per forza, dal più forte: le teste di serie.
  List<int> get seeds =>
      [for (var i = 0; i < players.length; i++) i]..sort((a, b) {
        final byElo = players[b].elo.compareTo(players[a].elo);
        return byElo != 0 ? byElo : a.compareTo(b);
      });

  /// Turni complessivi, anche quelli del tabellone non ancora abbinati.
  int get totalRounds => format == TournamentFormat.roundRobin
      ? rounds.length
      : (math.log(players.length) / math.ln2).round();

  /// Primo turno non concluso, o il numero di turni a torneo finito.
  int get currentRound {
    for (final (i, round) in rounds.indexed) {
      if (round.any((p) => !p.decided(format))) return i;
    }
    return rounds.length;
  }

  bool get finished =>
      rounds.length == totalRounds && currentRound == rounds.length;

  UserGame? get userGame {
    if (finished) return null;
    final round = rounds[currentRound];
    for (final p in round) {
      if (!p.includes(0) || p.isBye || p.decided(format)) continue;
      final userWhite = p.white == 0;
      final opponent = players[userWhite ? p.black! : p.white];
      if (p.result == null) {
        return UserGame(
          opponent: opponent,
          color: userWhite ? Side.white : Side.black,
        );
      }
      return UserGame(
        opponent: opponent,
        color: userWhite ? Side.black : Side.white,
        armageddon: true,
      );
    }
    return null;
  }

  /// Registra la partita dell'utente con i suoi [points]; poi si simulano le
  /// partite tra bot e, se serve, il turno successivo.
  Tournament recordUserGame(double points) {
    final game = userGame;
    if (game == null) throw StateError('Nessuna partita da giocare'); // l10n-ok
    final round = currentRound;
    final updated = [
      for (final p in rounds[round])
        if (!p.includes(0) || p.isBye)
          p
        else if (game.armageddon)
          p.copyWith(tiebreak: p.white == 0 ? points : 1 - points)
        else
          p.copyWith(result: p.white == 0 ? points : 1 - points),
    ];
    return _with([...rounds]..[round] = updated)._advance();
  }

  /// Simula le partite tra bot finché l'utente non ha una partita da giocare.
  Tournament _advance() {
    var t = this;
    while (!t.finished && t.userGame == null) {
      t = t._simulateRound();
    }
    return t;
  }

  Tournament _simulateRound() {
    final r = currentRound;
    final round = [
      for (final (board, p) in rounds[r].indexed)
        p.decided(format) || p.includes(0) ? p : _simulate(p, r, board),
    ];
    var next = [...rounds]..[r] = round;
    final done = round.every((p) => p.decided(format));
    if (format == TournamentFormat.knockout &&
        done &&
        next.length < totalRounds) {
      next = [...next, _nextKnockoutRound(round)];
    }
    return _with(next);
  }

  Pairing _simulate(Pairing p, int round, int board) {
    final base = mix32(seed ^ mix32(round * 16 + board));
    final w = players[p.white].elo;
    final b = players[p.black!].elo;
    final result = simulateGame(w, b, seed: base);
    if (format == TournamentFormat.roundRobin || result != 0.5) {
      return p.copyWith(result: result);
    }
    // Armageddon a colori invertiti: chi aveva il bianco ora ha il nero.
    final tiebreak = 1 - simulateGame(b, w, seed: base + 1);
    return p.copyWith(result: result, tiebreak: tiebreak);
  }

  List<Pairing> _firstKnockoutRound() {
    final s = seeds;
    final order = players.length == 8
        ? const [(0, 7), (3, 4), (1, 6), (2, 5)]
        : const [(0, 3), (1, 2)];
    return [
      for (final (k, (a, b)) in order.indexed)
        k.isEven
            ? Pairing(white: s[a], black: s[b])
            : Pairing(white: s[b], black: s[a]),
    ];
  }

  List<Pairing> _nextKnockoutRound(List<Pairing> previous) => [
    for (var k = 0; k < previous.length; k += 2)
      (k ~/ 2).isEven
          ? Pairing(white: previous[k].winner!, black: previous[k + 1].winner!)
          : Pairing(white: previous[k + 1].winner!, black: previous[k].winner!),
  ];

  /// Classifica del girone: punti, Sonneborn-Berger, vittorie.
  List<Standing> standings() {
    final points = List.filled(players.length, 0.0);
    final wins = List.filled(players.length, 0);
    void add(int player, double p) {
      points[player] += p;
      if (p == 1) wins[player]++;
    }

    final games = [
      for (final round in rounds)
        for (final p in round)
          if (!p.isBye && p.result != null) p,
    ];
    for (final p in games) {
      add(p.white, p.result!);
      add(p.black!, 1 - p.result!);
    }
    final sb = List.filled(players.length, 0.0);
    for (final p in games) {
      sb[p.white] += p.result! * points[p.black!];
      sb[p.black!] += (1 - p.result!) * points[p.white];
    }
    final rows = [
      for (var i = 0; i < players.length; i++)
        Standing(
          player: i,
          points: points[i],
          sonnebornBerger: sb[i],
          wins: wins[i],
        ),
    ];
    return rows..sort((a, b) {
      for (final c in [
        b.points.compareTo(a.points),
        b.sonnebornBerger.compareTo(a.sonnebornBerger),
        b.wins.compareTo(a.wins),
      ]) {
        if (c != 0) return c;
      }
      return a.player.compareTo(b.player);
    });
  }

  /// Vincitore a torneo finito.
  int? get champion {
    if (!finished) return null;
    return format == TournamentFormat.roundRobin
        ? standings().first.player
        : rounds.last.single.winner;
  }

  /// Posizione finale dell'utente; nell'eliminazione diretta chi esce nello
  /// stesso turno condivide la posizione (3, 5).
  int? get userRank {
    if (!finished) return null;
    if (format == TournamentFormat.roundRobin) {
      return standings().indexWhere((s) => s.player == 0) + 1;
    }
    for (final (r, round) in rounds.indexed) {
      for (final p in round) {
        if (p.includes(0) && p.winner != 0) {
          return (1 << (totalRounds - 1 - r)) + 1;
        }
      }
    }
    return 1;
  }

  Tournament _with(List<List<Pairing>> rounds) => Tournament._(
    format: format,
    players: players,
    seed: seed,
    createdAt: createdAt,
    rounds: rounds,
  );

  Map<String, Object?> toJson() => {
    'format': format.name,
    'players': [for (final p in players) p.toJson()],
    'seed': seed,
    'createdAt': createdAt.toIso8601String(),
    'rounds': [
      for (final round in rounds) [for (final p in round) p.toJson()],
    ],
  };

  static Tournament fromJson(Map<String, Object?> json) => Tournament._(
    format: TournamentFormat.values.byName(json['format']! as String),
    players: [
      for (final p in json['players']! as List)
        Player.fromJson((p as Map).cast()),
    ],
    seed: json['seed']! as int,
    createdAt: DateTime.parse(json['createdAt']! as String),
    rounds: [
      for (final round in json['rounds']! as List)
        [for (final p in round as List) Pairing.fromJson((p as Map).cast())],
    ],
  );
}

/// Turni del girone all'italiana con il metodo del cerchio (tabelle di
/// Berger). Con giocatori dispari si aggiunge un riposo.
List<List<Pairing>> _bergerRounds(int count) {
  final n = count.isEven ? count : count + 1;
  // Con giocatori dispari il riposo è il giocatore fisso del cerchio: così
  // tutti hanno tanti bianchi quanti neri.
  final ring = [if (count.isOdd) count, for (var i = 0; i < count; i++) i];
  final rounds = <List<Pairing>>[];
  for (var r = 0; r < n - 1; r++) {
    final round = <Pairing>[];
    for (var i = 0; i < n ~/ 2; i++) {
      var a = ring[i];
      var b = ring[n - 1 - i];
      // Il giocatore fisso alterna i colori; gli altri seguono la posizione.
      final swap = i == 0 ? r.isOdd : i.isOdd;
      if (swap) (a, b) = (b, a);
      if (a >= count) {
        round.add(Pairing(white: b));
      } else if (b >= count) {
        round.add(Pairing(white: a));
      } else {
        round.add(Pairing(white: a, black: b));
      }
    }
    rounds.add(round);
    ring.insert(1, ring.removeLast());
  }
  return rounds;
}
