import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/xp.dart';

void main() {
  group('RG-01 punti esperienza', () {
    test('una partita persa vale XP', () {
      expect(xpFor(const GamePlayed(result: GameResult.loss)), greaterThan(0));
    });

    test('la vittoria vale più della sconfitta', () {
      expect(
        xpFor(const GamePlayed(result: GameResult.win)),
        greaterThan(xpFor(const GamePlayed(result: GameResult.loss))),
      );
    });

    test('lezioni e revisioni valgono più della sola vittoria', () {
      final win = xpFor(const GamePlayed(result: GameResult.win));
      expect(xpFor(const LessonCompleted()), greaterThan(win));
      expect(xpFor(const ReviewCompleted()), greaterThan(win));
    });

    test('un minigioco concluso vale XP come un puzzle', () {
      expect(
        xpFor(const MinigameFinished(game: 'coordinate', score: 3)),
        xpFor(const PuzzleSolved()),
      );
      expect(xpFor(const MinigameFinished(game: 'coordinate', score: 0)), 0);
    });

    test('un torneo concluso vale più di una vittoria', () {
      expect(
        xpFor(const TournamentFinished(rank: 3, players: 6)),
        greaterThan(xpFor(const GamePlayed(result: GameResult.win))),
      );
    });

    test('un puzzle risolto vale XP', () {
      expect(xpFor(const PuzzleSolved()), greaterThan(0));
    });
  });

  group('RG-01 livelli', () {
    test('si parte dal livello 1', () {
      expect(levelForXp(0), 1);
    });

    test('le soglie crescono a ogni livello', () {
      expect(xpForLevel(1), 0);
      expect(xpForLevel(2), 100);
      expect(xpForLevel(3), 300);
      for (var l = 2; l < 30; l++) {
        expect(
          xpForLevel(l + 1) - xpForLevel(l),
          greaterThan(xpForLevel(l) - xpForLevel(l - 1)),
        );
      }
    });

    test('il livello cambia esattamente alla soglia', () {
      expect(levelForXp(99), 1);
      expect(levelForXp(100), 2);
      expect(levelForXp(299), 2);
      expect(levelForXp(300), 3);
    });

    test('progresso nel livello tra 0 e 1', () {
      expect(levelProgress(0), 0);
      expect(levelProgress(50), closeTo(0.5, 1e-9));
      expect(levelProgress(100), 0);
    });
  });
}
