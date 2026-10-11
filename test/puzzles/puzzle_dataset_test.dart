import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/puzzles/puzzle.dart';
import 'package:scacchi/puzzles/themes.dart';

void main() {
  final puzzles = Puzzle.parseCsvFile(
    File('assets/puzzles/puzzles.csv').readAsStringSync(),
  );

  group('RF-80 raccolta inclusa nell\'app', () {
    test('contiene alcune migliaia di puzzle', () {
      expect(puzzles.length, inInclusiveRange(2000, 8000));
    });

    test('copre tutte le fasce di difficoltà', () {
      final ratings = puzzles.map((p) => p.rating);
      expect(ratings.reduce((a, b) => a < b ? a : b), lessThan(700));
      expect(ratings.reduce((a, b) => a > b ? a : b), greaterThan(2500));
    });

    test('ogni puzzle ha una soluzione legale', () {
      for (final p in puzzles) {
        var pos = p.initial;
        for (final m in p.moves) {
          expect(pos.isLegal(m), isTrue, reason: '${p.id} $m');
          pos = pos.play(m);
        }
      }
    });

    test('ogni tema proposto ha almeno qualche puzzle', () {
      for (final theme in puzzleThemeLabels.keys) {
        final n = puzzles.where((p) => p.themes.contains(theme)).length;
        expect(n, greaterThan(5), reason: theme);
      }
    });
  });
}
