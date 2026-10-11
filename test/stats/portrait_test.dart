import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/stats/portrait.dart';

// Matto del barbiere: 1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 4. Qxf7#
const _scholars = '1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 4. Qxf7# 1-0';
// Matto del giullare: 1. f3 e5 2. g4 Qh4#
const _fools = '1. f3 e5 2. g4 Qh4# 0-1';

void main() {
  final now = DateTime(2026, 10, 11, 12);

  SavedGame game(
    String result, {
    String movetext = '1. e4 e5 *',
    Side? side = Side.white,
    int daysAgo = 1,
    String? opening,
    double? accuracy,
    int? elo,
    String mode = SavedGame.computer,
    String id = 'g',
  }) => SavedGame(
    id: '$id$daysAgo$result$opening$elo',
    createdAt: now.subtract(Duration(days: daysAgo)),
    updatedAt: now.subtract(Duration(days: daysAgo)),
    white: 'Tu',
    black: 'Computer',
    mode: mode,
    result: result,
    pgn: '[Result "$result"]\n\n$movetext',
    playerSide: side,
    opening: opening,
    accuracy: accuracy,
    opponentElo: elo,
  );

  PlayerPortrait portrait(List<SavedGame> games) =>
      PlayerPortrait.from(games, now: now);

  test('senza partite nella settimana il ritratto è vuoto', () {
    expect(portrait([]).isEmpty, isTrue);
    expect(portrait([game('1-0', daysAgo: 8)]).isEmpty, isTrue);
  });

  test('conta solo partite finite con un colore, non importate', () {
    final p = portrait([
      game('1-0'),
      game('*'),
      game('1-0', side: null),
      game('1-0', mode: SavedGame.imported),
    ]);
    expect(p.score.games, 1);
  });

  test('risultati della settimana', () {
    final p = portrait([game('1-0'), game('1/2-1/2'), game('0-1')]);
    expect((p.score.wins, p.score.draws, p.score.losses), (1, 1, 1));
  });

  test('aperture preferite, al massimo tre, dalla più giocata', () {
    final p = portrait([
      game('1-0', opening: 'Italiana'),
      game('1-0', opening: 'Italiana', daysAgo: 2),
      game('0-1', opening: 'Siciliana'),
      game('1-0', opening: 'Francese'),
      game('1-0', opening: 'Inglese'),
    ]);
    expect(p.openings.map((o) => o.name), ['Italiana', 'Francese', 'Inglese']);
  });

  test('precisione media delle partite riviste', () {
    final p = portrait([
      game('1-0', accuracy: 70),
      game('1-0', accuracy: 90, daysAgo: 2),
      game('1-0', daysAgo: 3),
    ]);
    expect(p.accuracy, 80);
  });

  test('pezzo che dà più spesso matto nelle vittorie', () {
    final p = portrait([
      game('1-0', movetext: _scholars),
      game('1-0', movetext: _scholars, daysAgo: 2),
      game('0-1', movetext: _fools, side: Side.black, daysAgo: 3),
    ]);
    expect(p.matingPiece, Role.queen);
    expect(p.matingGames, 3);
  });

  test('un risultato non riconosciuto non rompe il ritratto', () {
    expect(portrait([game('0-0'), game('1-0')]).score.games, 1);
  });

  test('il matto subito non conta', () {
    final p = portrait([game('0-1', movetext: _fools)]);
    expect(p.matingPiece, isNull);
  });

  test('avversario più forte battuto', () {
    final p = portrait([
      game('1-0', elo: 1200),
      game('1-0', elo: 1600, daysAgo: 2),
      game('0-1', elo: 2000, daysAgo: 3),
    ]);
    expect(p.strongestBeaten, 1600);
  });

  test('giorno con più partite', () {
    // 11 ottobre 2026 è domenica: 10 ottobre sabato, 9 venerdì.
    final p = portrait([
      game('1-0', id: 'a'),
      game('1-0', id: 'b'),
      game('1-0', daysAgo: 2),
    ]);
    expect(p.busiestWeekday, DateTime.saturday);
  });

  test('la finestra è di sette giorni', () {
    expect(portrait([game('1-0', daysAgo: 7)]).isEmpty, isFalse);
    expect(portrait([game('1-0', daysAgo: 8)]).isEmpty, isTrue);
  });
}
