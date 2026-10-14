import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/puzzles/puzzle.dart';
import 'package:rokko/puzzles/puzzle_goal.dart';

import 'fixtures.dart';

Puzzle withThemes(String themes) => Puzzle.parseCsv(
  'x,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,800,$themes',
);

void main() {
  group('obiettivo dai temi', () {
    test('matto in N', () {
      expect(PuzzleGoal.of(backRank), PuzzleGoal.mateIn1);
      expect(PuzzleGoal.of(withThemes('mateIn2 short')), PuzzleGoal.mateIn2);
      expect(PuzzleGoal.of(withThemes('mateIn3')), PuzzleGoal.mateIn3);
      expect(PuzzleGoal.of(withThemes('mateIn4')), PuzzleGoal.mateIn4);
      expect(PuzzleGoal.of(withThemes('mateIn5')), PuzzleGoal.mate);
    });

    test('vantaggio, vantaggio decisivo e parità', () {
      expect(PuzzleGoal.of(hangingQueen), PuzzleGoal.crushing);
      expect(PuzzleGoal.of(withThemes('advantage fork')), PuzzleGoal.advantage);
      expect(PuzzleGoal.of(withThemes('equality')), PuzzleGoal.equality);
    });

    test('il matto prevale sul tema di valutazione', () {
      expect(PuzzleGoal.of(withThemes('crushing mateIn2')), PuzzleGoal.mateIn2);
    });

    test('senza temi utili non c\'è obiettivo', () {
      expect(PuzzleGoal.of(castle), isNull);
      expect(PuzzleGoal.of(withThemes('')), isNull);
    });

    test('solo gli obiettivi di matto sono di matto', () {
      expect(PuzzleGoal.values.where((g) => g.isMate), [
        PuzzleGoal.mateIn1,
        PuzzleGoal.mateIn2,
        PuzzleGoal.mateIn3,
        PuzzleGoal.mateIn4,
        PuzzleGoal.mate,
      ]);
    });
  });

  test('ogni obiettivo ha un testo, in italiano e in inglese', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final goal in PuzzleGoal.values) {
        // Una chiave mancante nei file ARB ricadrebbe sul testo generico.
        expect(l10n.puzzleGoal(goal.key), isNot(l10n.puzzleGoal('other')));
      }
    }
    expect(
      lookupAppLocalizations(const Locale('it')).puzzleGoal('mateIn2'),
      'Matto in 2',
    );
    expect(
      lookupAppLocalizations(const Locale('it')).puzzleGoal('advantage'),
      'Ottieni il vantaggio',
    );
  });
}
