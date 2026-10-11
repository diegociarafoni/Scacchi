import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/stats/local_rating.dart';
import 'package:scacchi/stats/stats.dart';

var _n = 0;

SavedGame game(
  String result, {
  Side? side = Side.white,
  String? tc,
  int? elo,
  double? accuracy,
  String? opening,
  int day = 1,
  String mode = 'computer',
}) => SavedGame(
  id: '${_n++}',
  createdAt: DateTime(2026, 10, day),
  updatedAt: DateTime(2026, 10, day),
  white: 'A',
  black: 'B',
  mode: mode,
  result: result,
  pgn: '',
  playerSide: side,
  timeControl: tc,
  opponentElo: elo,
  accuracy: accuracy,
  opening: opening,
);

void main() {
  group('RF-111 statistiche', () {
    final games = [
      game('1-0', tc: '5+0'),
      game('0-1', tc: '5+0'),
      game('1/2-1/2', side: Side.black, tc: '10+0'),
      game('0-1', side: Side.black, tc: '10+0'),
      game('*', side: Side.black),
      game('1-0', side: null, mode: 'locale'),
      game('1-0', side: null, mode: SavedGame.imported),
    ];
    final stats = GameStats.from(games);

    test('vittorie, patte e sconfitte per colore', () {
      expect(stats.all, const Score(wins: 2, draws: 1, losses: 1));
      expect(stats.byColor[Side.white], const Score(wins: 1, losses: 1));
      expect(stats.byColor[Side.black], const Score(wins: 1, draws: 1));
    });

    test('per cadenza, "senza tempo" se non indicata', () {
      expect(stats.byTimeControl['5+0'], const Score(wins: 1, losses: 1));
      expect(stats.byTimeControl['10+0'], const Score(wins: 1, draws: 1));
    });

    test('partite locali contate a parte, importate escluse', () {
      expect(stats.localGames, 1);
    });

    test('una partita al computer senza colore non è locale', () {
      final s = GameStats.from([game('1-0', side: null)]);
      expect(s.localGames, 0);
      expect(s.all.games, 0);
    });

    test('cadenze dalla più giocata', () {
      final s = GameStats.from([
        game('1-0', tc: '3+2'),
        game('1-0', tc: '10+0'),
        game('0-1', tc: '10+0'),
      ]);
      expect(s.byTimeControl.keys, ['10+0', '3+2']);
    });

    test('aperture a pari merito in ordine alfabetico', () {
      final s = GameStats.from([
        game('1-0', opening: 'Siciliana'),
        game('1-0', opening: 'Francese'),
      ]);
      expect(s.openings.map((o) => o.name), ['Francese', 'Siciliana']);
    });

    test('percentuale di punti', () {
      expect(stats.all.percent, closeTo(62.5, 1e-9));
      expect(const Score().percent, isNull);
    });

    test('aperture più giocate, in ordine', () {
      final s = GameStats.from([
        game('1-0', opening: 'Italiana'),
        game('0-1', opening: 'Siciliana'),
        game('1-0', opening: 'Italiana'),
        game('1-0'),
      ]);
      expect(s.openings.map((e) => (e.name, e.games)), [
        ('Italiana', 2),
        ('Siciliana', 1),
      ]);
    });

    test('precisione media e andamento nel tempo', () {
      final s = GameStats.from([
        game('1-0', accuracy: 70, day: 2),
        game('0-1', accuracy: 80),
        game('1-0'),
      ]);
      expect(s.averageAccuracy, 75);
      expect(s.accuracyTrend.map((p) => p.$2), [80, 70]);
    });
  });

  group('RF-110 rating locale contro il computer', () {
    test('si parte da 800 senza partite', () {
      expect(LocalRating.from(const []).rating, LocalRating.initial);
      expect(LocalRating.from(const []).provisional, isTrue);
    });

    test('battere un bot più forte fa salire di più', () {
      final weak = LocalRating.from([game('1-0', elo: 600)]).rating;
      final strong = LocalRating.from([game('1-0', elo: 1400)]).rating;
      expect(weak, greaterThan(LocalRating.initial));
      expect(strong, greaterThan(weak));
    });

    test('perdere fa scendere, pattare con un pari non cambia', () {
      expect(
        LocalRating.from([game('0-1', elo: 800)]).rating,
        lessThan(LocalRating.initial),
      );
      expect(
        LocalRating.from([game('1/2-1/2', elo: 800)]).rating,
        LocalRating.initial,
      );
    });

    test('ordine cronologico e solo partite contro il computer', () {
      final r = LocalRating.from([
        game('1-0', elo: 1000, day: 3),
        game('0-1', elo: 1000),
        game('1-0', side: null, mode: 'locale', day: 2),
        game('1-0', elo: 1000, mode: SavedGame.imported, day: 2),
      ]);
      expect(r.history, hasLength(2));
      expect(r.history.first.$1, DateTime(2026, 10));
    });

    test('partite alla stessa ora: ordine stabile per identificativo', () {
      final a = game('1-0', elo: 800);
      final b = game('0-1', elo: 800);
      expect(
        LocalRating.from([a, b]).history,
        LocalRating.from([b, a]).history,
      );
    });

    test('dopo 10 partite non è più provvisorio', () {
      final r = LocalRating.from([
        for (var i = 0; i < 10; i++) game('1-0', elo: 800, day: i + 1),
      ]);
      expect(r.provisional, isFalse);
    });
  });
}
