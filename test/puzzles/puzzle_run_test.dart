import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/puzzles/puzzle.dart';
import 'package:scacchi/puzzles/puzzle_library.dart';
import 'package:scacchi/puzzles/puzzle_run.dart';

Puzzle p(String id, int rating) => Puzzle.parseCsv(
  '$id,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,$rating,mateIn1',
);

final library = PuzzleLibrary([
  for (var r = 400; r <= 2800; r += 50) p('p$r', r),
]);

final good = Move.parse('a1a8')!;
final bad = Move.parse('a1a7')!;

class FakeClock {
  Duration elapsed = Duration.zero;
  Duration call() => elapsed;
}

void main() {
  group('RF-82 Combo a tempo', () {
    test('dura 3 minuti e finisce allo scadere del tempo', () {
      final clock = FakeClock();
      final run = PuzzleRun(PuzzleRunMode.storm, library, clock: clock.call);
      expect(run.remaining, const Duration(minutes: 3));
      clock.elapsed = const Duration(minutes: 3);
      expect(run.isOver, isTrue);
    });

    test('la difficoltà cresce a ogni puzzle risolto', () {
      final run = PuzzleRun(
        PuzzleRunMode.storm,
        library,
        clock: FakeClock().call,
      );
      final first = run.current.puzzle.rating;
      run.tryMove(good);
      expect(run.current.puzzle.rating, greaterThan(first));
      expect(run.score, 1);
    });

    test('le combo danno secondi di bonus, gli errori li tolgono', () {
      final clock = FakeClock();
      final run = PuzzleRun(PuzzleRunMode.storm, library, clock: clock.call);
      for (var i = 0; i < 5; i++) {
        run.tryMove(good);
      }
      expect(run.combo, 5);
      expect(run.remaining, const Duration(minutes: 3, seconds: 3));
      run.tryMove(bad);
      expect(run.combo, 0);
      expect(run.remaining, const Duration(minutes: 2, seconds: 53));
      expect(run.mistakes, 1);
    });

    test('dopo un errore si passa al puzzle successivo', () {
      final run = PuzzleRun(
        PuzzleRunMode.storm,
        library,
        clock: FakeClock().call,
      );
      final first = run.current.puzzle.id;
      run.tryMove(bad);
      expect(run.current.puzzle.id, isNot(first));
    });

    test('non ripropone lo stesso puzzle nella stessa serie', () {
      final run = PuzzleRun(
        PuzzleRunMode.storm,
        library,
        clock: FakeClock().call,
      );
      final ids = <String>{};
      for (var i = 0; i < 30; i++) {
        expect(ids.add(run.current.puzzle.id), isTrue);
        run.tryMove(i.isEven ? good : bad);
      }
    });
  });

  group('RF-82 Corsa e sopravvivenza', () {
    test('Corsa 5 minuti finisce al terzo errore', () {
      final run = PuzzleRun(
        PuzzleRunMode.rush5,
        library,
        clock: FakeClock().call,
      );
      expect(run.remaining, const Duration(minutes: 5));
      run.tryMove(bad);
      run.tryMove(bad);
      expect(run.isOver, isFalse);
      run.tryMove(bad);
      expect(run.isOver, isTrue);
    });

    test('sopravvivenza: nessun limite di tempo, tre errori', () {
      final clock = FakeClock();
      final run = PuzzleRun(PuzzleRunMode.survival, library, clock: clock.call);
      clock.elapsed = const Duration(hours: 1);
      expect(run.remaining, isNull);
      expect(run.isOver, isFalse);
      for (var i = 0; i < 3; i++) {
        run.tryMove(bad);
      }
      expect(run.isOver, isTrue);
    });
  });

  group('RF-82 Serie', () {
    test('finisce al primo errore', () {
      final run = PuzzleRun(
        PuzzleRunMode.streak,
        library,
        clock: FakeClock().call,
      );
      run.tryMove(good);
      run.tryMove(bad);
      expect(run.isOver, isTrue);
      expect(run.score, 1);
    });

    test('concede un solo salto', () {
      final run = PuzzleRun(
        PuzzleRunMode.streak,
        library,
        clock: FakeClock().call,
      );
      final first = run.current.puzzle.id;
      expect(run.skip(), isTrue);
      expect(run.current.puzzle.id, isNot(first));
      expect(run.skip(), isFalse);
      expect(run.score, 0);
    });
  });

  test('in cima alla raccolta prosegue con i più difficili rimasti', () {
    final small = PuzzleLibrary([p('x', 600), p('y', 700), p('z', 2000)]);
    final run = PuzzleRun(
      PuzzleRunMode.survival,
      small,
      clock: FakeClock().call,
    );
    final ratings = [run.current.puzzle.rating];
    run.tryMove(good);
    ratings.add(run.current.puzzle.rating);
    run.tryMove(good);
    ratings.add(run.current.puzzle.rating);
    expect(ratings, [600, 700, 2000]);
    run.tryMove(good);
    expect(run.isOver, isTrue);
    expect(run.score, 3);
  });

  test('a serie finita le mosse vengono ignorate', () {
    final run = PuzzleRun(
      PuzzleRunMode.streak,
      library,
      clock: FakeClock().call,
    );
    run.tryMove(bad);
    expect(run.tryMove(good), RunMoveResult.over);
    expect(run.score, 0);
  });
}
