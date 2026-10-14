import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/tournament/tournament.dart';

const bots = [
  Player(name: 'Principiante', elo: 600, levelId: 1),
  Player(name: 'Esordiente', elo: 900, levelId: 2),
  Player(name: 'Dilettante', elo: 1100, levelId: 3),
  Player(name: 'Giocatore di circolo', elo: 1350, levelId: 4),
  Player(name: 'Agonista', elo: 1600, levelId: 5),
  Player(name: 'Esperto', elo: 2000, levelId: 6),
  Player(name: 'Maestro', elo: 2400, levelId: 7),
  Player(name: 'Campione', elo: 3000, levelId: 8),
];

const me = Player(name: 'Tu', elo: 1000);

Tournament create(TournamentFormat format, int size, {int seed = 1}) =>
    Tournament.create(
      format: format,
      user: me,
      bots: chooseBots(bots, userElo: me.elo, count: size - 1),
      seed: seed,
      createdAt: DateTime(2026, 10, 11),
    );

/// Gioca tutto il torneo dando all'utente sempre [points].
Tournament playAll(Tournament t, double points) {
  var guard = 0;
  while (!t.finished && guard++ < 20) {
    t = t.recordUserGame(points);
  }
  return t;
}

void main() {
  realGames();
  group('scelta dei bot', () {
    test('i più vicini al livello dell\'utente, in ordine di forza', () {
      final chosen = chooseBots(bots, userElo: 1000, count: 3);
      expect(chosen.map((b) => b.elo), [900, 1100, 1350]);
    });

    test('senza posti per bot non ne sceglie nessuno', () {
      expect(chooseBots(bots, userElo: 1000, count: -1), isEmpty);
      expect(chooseBots(bots, userElo: 1000, count: 0), isEmpty);
    });

    test('non più di quelli disponibili', () {
      expect(chooseBots(bots, userElo: 1000, count: 20), hasLength(8));
    });
  });

  group('RG-09 girone all\'italiana', () {
    for (final size in [4, 5, 6, 8]) {
      test('$size giocatori: ognuno incontra tutti una volta', () {
        final t = create(TournamentFormat.roundRobin, size);
        expect(t.players, hasLength(size));
        expect(t.players.first, me);
        final n = size.isEven ? size : size + 1;
        expect(t.rounds, hasLength(n - 1));
        final met = <(int, int)>{};
        final whites = List.filled(size, 0);
        for (final round in t.rounds) {
          final busy = <int>{};
          for (final p in round) {
            if (p.black == null) {
              expect(busy.add(p.white), isTrue);
              continue;
            }
            expect(busy.add(p.white) && busy.add(p.black!), isTrue);
            final pair = p.white < p.black!
                ? (p.white, p.black!)
                : (p.black!, p.white);
            expect(met.add(pair), isTrue, reason: '$pair due volte');
            whites[p.white]++;
          }
        }
        expect(met, hasLength(size * (size - 1) ~/ 2));
        if (size.isOdd) {
          // Con il riposo fisso nel cerchio i colori sono pari per tutti.
          expect(whites, everyElement((size - 1) ~/ 2));
        }
        for (final w in whites) {
          expect(w, inInclusiveRange((n - 1) ~/ 2 - 1, (n - 1) ~/ 2 + 1));
        }
      });
    }

    test('la partita dell\'utente aggiorna la classifica a ogni turno', () {
      var t = create(TournamentFormat.roundRobin, 4);
      final game = t.userGame!;
      expect(game.opponent, isNot(me));
      expect(Side.values, contains(game.color));
      t = t.recordUserGame(1);
      expect(t.currentRound, 1);
      final standings = t.standings();
      expect(standings.fold(0.0, (s, r) => s + r.points), 2.0);
      expect(standings.firstWhere((r) => r.player == 0).points, 1);
    });

    test('vincendo tutto l\'utente è primo e prende il trofeo', () {
      final t = playAll(create(TournamentFormat.roundRobin, 6), 1);
      expect(t.finished, isTrue);
      expect(t.userGame, isNull);
      expect(t.userRank, 1);
      expect(t.standings().first.player, 0);
    });

    test('perdendo tutto l\'utente è ultimo', () {
      final t = playAll(create(TournamentFormat.roundRobin, 4), 0);
      expect(t.userRank, 4);
    });

    test('con giocatori dispari ognuno riposa una volta, senza punti', () {
      final t = playAll(create(TournamentFormat.roundRobin, 5), 0.5);
      final byes = List.filled(5, 0);
      for (final round in t.rounds) {
        for (final p in round) {
          if (p.black == null) byes[p.white]++;
        }
      }
      expect(byes, everyElement(1));
      final total = t.standings().fold(0.0, (s, r) => s + r.points);
      expect(total, 10.0, reason: '10 partite da un punto');
    });

    test('spareggio Sonneborn-Berger a parità di punti', () {
      final t = playAll(create(TournamentFormat.roundRobin, 8, seed: 7), 0.5);
      final s = t.standings();
      for (var i = 1; i < s.length; i++) {
        final a = s[i - 1], b = s[i];
        expect(
          a.points > b.points ||
              (a.points == b.points && a.sonnebornBerger >= b.sonnebornBerger),
          isTrue,
        );
      }
    });
  });

  group('RG-09 eliminazione diretta', () {
    test('8 giocatori: tre turni, testa di serie 1 contro 8', () {
      final t = create(TournamentFormat.knockout, 8);
      final first = t.rounds.first;
      expect(first, hasLength(4));
      final seeds = t.seeds;
      final pairs = {
        for (final p in first)
          {seeds.indexOf(p.white), seeds.indexOf(p.black!)},
      };
      expect(
        pairs,
        containsAll([
          {0, 7},
          {3, 4},
          {1, 6},
          {2, 5},
        ]),
      );
    });

    test('vincendo sempre l\'utente vince il torneo', () {
      final t = playAll(create(TournamentFormat.knockout, 8), 1);
      expect(t.finished, isTrue);
      expect(t.rounds, hasLength(3));
      expect(t.champion, 0);
      expect(t.userRank, 1);
    });

    test('eliminato al primo turno il torneo si chiude da solo', () {
      final t = create(TournamentFormat.knockout, 8).recordUserGame(0);
      expect(t.finished, isTrue);
      expect(t.userGame, isNull);
      expect(t.champion, isNot(0));
      expect(t.userRank, 5);
    });

    test('dopo una patta l\'utente gioca l\'Armageddon a colori invertiti', () {
      var t = create(TournamentFormat.knockout, 4);
      final first = t.userGame!;
      t = t.recordUserGame(0.5);
      final again = t.userGame!;
      expect(again.armageddon, isTrue);
      expect(again.opponent, first.opponent);
      expect(again.color, first.color.opposite);
      // Con il nero basta la patta, con il bianco no.
      t = t.recordUserGame(0.5);
      final mine = t.rounds.first.firstWhere((p) => p.includes(0));
      expect(mine.winner == 0, again.color == Side.black);
    });

    for (final (points, advances) in [(1.0, true), (0.0, false)]) {
      test('Armageddon: ${points == 1 ? 'vinto' : 'perso'} dall\'utente', () {
        for (var seed = 0; seed < 6; seed++) {
          var t = create(TournamentFormat.knockout, 4, seed: seed);
          t = t.recordUserGame(0.5).recordUserGame(points);
          final mine = t.rounds.first.firstWhere((p) => p.includes(0));
          expect(mine.winner == 0, advances, reason: 'seme $seed');
        }
      });
    }

    test('solo 4 o 8 giocatori', () {
      expect(() => create(TournamentFormat.knockout, 6), throwsArgumentError);
    });
  });

  group('partite tra bot', () {
    test('stesso seme, stessi risultati', () {
      final a = playAll(create(TournamentFormat.roundRobin, 8, seed: 3), 0.5);
      final b = playAll(create(TournamentFormat.roundRobin, 8, seed: 3), 0.5);
      expect(a.toJson(), b.toJson());
    });

    test('il bot più forte vince più spesso', () {
      var strong = 0.0;
      for (var seed = 0; seed < 200; seed++) {
        strong += simulateGame(2000, 1000, seed: seed);
      }
      expect(strong / 200, greaterThan(0.85));
      var even = 0.0;
      for (var seed = 0; seed < 400; seed++) {
        even += simulateGame(1200, 1200, seed: seed);
      }
      expect(even / 400, closeTo(0.5, 0.08));
    });
  });

  test('salvataggio e ripristino a metà torneo', () {
    final t = create(TournamentFormat.knockout, 8).recordUserGame(1);
    final back = Tournament.fromJson(t.toJson());
    expect(back.toJson(), t.toJson());
    expect(back.userGame?.opponent, t.userGame?.opponent);
  });

  group('tournamentPoints', () {
    const normal = UserGame(
      opponent: Player(name: 'x', elo: 1000),
      color: Side.white,
    );
    const armageddonWhite = UserGame(
      opponent: Player(name: 'x', elo: 1000),
      color: Side.white,
      armageddon: true,
    );
    const armageddonBlack = UserGame(
      opponent: Player(name: 'x', elo: 1000),
      color: Side.black,
      armageddon: true,
    );

    test('partita normale: 1, ½, 0', () {
      expect(tournamentPoints(GameResult.win, normal), 1);
      expect(tournamentPoints(GameResult.draw, normal), 0.5);
      expect(tournamentPoints(GameResult.loss, normal), 0);
    });

    test('Armageddon: la patta vale una vittoria per il nero', () {
      expect(tournamentPoints(GameResult.draw, armageddonBlack), 1);
      expect(tournamentPoints(GameResult.draw, armageddonWhite), 0);
      expect(tournamentPoints(GameResult.win, armageddonWhite), 1);
      expect(tournamentPoints(GameResult.loss, armageddonBlack), 0);
    });
  });
}

/// Risolve con [whitePoints] ogni partita tra bot in attesa e dà all'utente
/// sempre [user] punti, senza mai simulare.
Tournament playAllReal(
  Tournament t, {
  required double user,
  required double Function(BotGame game) whitePoints,
}) {
  var guard = 0;
  while (!t.finished && guard++ < 200) {
    if (t.userGame != null) {
      t = t.recordUserGame(user, simulateBots: false);
    } else {
      final pending = t.pendingBotGames;
      expect(pending, isNotEmpty, reason: 'il torneo non deve restare fermo');
      t = t.withBotGame(pending.first, whitePoints(pending.first));
    }
  }
  return t;
}

Tournament createReal(TournamentFormat format, int size, {int seed = 1}) =>
    Tournament.create(
      format: format,
      user: me,
      bots: chooseBots(bots, userElo: me.elo, count: size - 1),
      seed: seed,
      createdAt: DateTime(2026, 10, 11),
      simulateBots: false,
    );

void realGames() {
  group('RG-09 partite tra bot giocate davvero', () {
    test('senza simulazione le partite tra bot restano in attesa', () {
      final t = createReal(TournamentFormat.roundRobin, 4);
      expect(t.userGame, isNotNull);
      expect(t.pendingBotGames, isEmpty, reason: 'si gioca prima l\'utente');
      final after = t.recordUserGame(1, simulateBots: false);
      expect(after.pendingBotGames, hasLength(1));
      expect(after.finished, isFalse);
      expect(after.currentRound, 0);
    });

    test('un risultato reale chiude il turno e apre il successivo', () {
      var t = createReal(
        TournamentFormat.roundRobin,
        4,
      ).recordUserGame(1, simulateBots: false);
      final game = t.pendingBotGames.single;
      t = t.withBotGame(game, 1);
      expect(t.currentRound, 1);
      expect(t.userGame, isNotNull);
      final p = t.rounds[0].firstWhere((p) => !p.includes(0));
      expect(p.white, game.white);
      expect(p.result, 1);
    });

    for (final size in [4, 5, 6, 8]) {
      test('girone da $size: si arriva in fondo solo con partite reali', () {
        final t = playAllReal(
          createReal(TournamentFormat.roundRobin, size),
          user: 0.5,
          whitePoints: (_) => 0.5,
        );
        expect(t.finished, isTrue);
        expect(t.userRank, isNotNull);
        expect(
          t.rounds.expand((r) => r).where((p) => !p.isBye),
          everyElement(
            isA<Pairing>().having((p) => p.result, 'risultato', 0.5),
          ),
        );
      });
    }

    test('eliminazione diretta: i turni successivi nascono dai reali', () {
      final t = playAllReal(
        createReal(TournamentFormat.knockout, 8),
        user: 1,
        whitePoints: (_) => 1,
      );
      expect(t.finished, isTrue);
      expect(t.champion, 0);
      expect(t.userRank, 1);
    });

    test('la patta tra bot chiede lo spareggio a colori invertiti', () {
      var t = createReal(
        TournamentFormat.knockout,
        4,
      ).recordUserGame(1, simulateBots: false);
      final first = t.pendingBotGames.single;
      expect(first.tiebreak, isFalse);
      t = t.withBotGame(first, 0.5);
      final tie = t.pendingBotGames.single;
      expect(tie.tiebreak, isTrue);
      expect(tie.white, first.black, reason: 'colori invertiti');
      expect(tie.black, first.white);
      // Il nero dello spareggio (chi aveva il bianco) passa pattando.
      final settled = t.withBotGame(tie, 0.5);
      final pairing = settled.rounds[0].firstWhere((p) => !p.includes(0));
      expect(pairing.winner, first.white);
      // Se il bianco dello spareggio vince, passa lui.
      final other = t.withBotGame(tie, 1);
      expect(
        other.rounds[0].firstWhere((p) => !p.includes(0)).winner,
        first.black,
      );
    });

    test('la simulazione di una partita è la stessa di prima', () {
      final a = create(TournamentFormat.knockout, 8, seed: 5);
      var b = createReal(TournamentFormat.knockout, 8, seed: 5);
      b = b.recordUserGame(1, simulateBots: false);
      for (final g in b.pendingBotGames) {
        b = b.simulateBotGame(g);
      }
      b = b.settle();
      final a1 = a.recordUserGame(1);
      expect(b.toJson(), a1.toJson());
    });

    test('il torneo con partite in attesa si salva e si rilegge', () {
      final t = createReal(
        TournamentFormat.roundRobin,
        4,
      ).recordUserGame(1, simulateBots: false);
      final again = Tournament.fromJson(t.toJson());
      expect(
        again.pendingBotGames.single.board,
        t.pendingBotGames.single.board,
      );
    });
  });
}
