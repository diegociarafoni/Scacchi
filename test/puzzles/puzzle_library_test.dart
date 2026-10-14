import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/puzzles/puzzle.dart';
import 'package:rokko/puzzles/puzzle_library.dart';

Puzzle p(String id, int rating, String themes) => Puzzle.parseCsv(
  '$id,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,$rating,$themes',
);

void main() {
  final library = PuzzleLibrary([
    p('a', 800, 'mateIn1 short'),
    p('b', 1200, 'fork short'),
    p('c', 1500, 'pin middlegame'),
    p('d', 1520, 'fork middlegame'),
    p('e', 2100, 'mateIn2 long'),
  ]);

  group('RF-81 scelta del puzzle adatto al punteggio', () {
    test('sceglie il puzzle più vicino al punteggio del giocatore', () {
      expect(library.next(rating: 1490).id, 'c');
    });

    test('salta i puzzle già visti', () {
      expect(library.next(rating: 1490, seen: {'c'}).id, 'd');
    });

    test('quando sono stati visti tutti ripropone il meno recente', () {
      expect(
        library.next(rating: 2000, seen: {'c', 'a', 'b', 'd', 'e'}).id,
        'c',
      );
    });
  });

  group('RF-83 filtro per tema', () {
    test('elenca i temi presenti', () {
      expect(library.themes, containsAll(['fork', 'pin', 'mateIn1']));
    });

    test('propone solo puzzle del tema scelto', () {
      expect(library.next(rating: 1500, theme: 'fork').id, 'd');
      expect(library.next(rating: 900, theme: 'fork').id, 'b');
    });

    test('conta i puzzle per tema', () {
      expect(library.countFor('fork'), 2);
    });
  });

  group('RF-84 puzzle del giorno', () {
    test('è lo stesso per tutta la giornata', () {
      final morning = library.daily(DateTime(2026, 10, 11, 8));
      final evening = library.daily(DateTime(2026, 10, 11, 23));
      expect(morning.id, evening.id);
    });

    test('cambia nei giorni successivi', () {
      final ids = {
        for (var d = 1; d <= 20; d++) library.daily(DateTime(2026, 10, d)).id,
      };
      expect(ids.length, greaterThan(1));
    });
  });
}
