import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/path/exercise.dart';

void main() {
  test('RG-03 capitoli richiesti nell\'ordine del percorso', () {
    expect(curriculum.map((c) => c.title), [
      'Il movimento dei pezzi',
      'Matti elementari',
      'Tattiche',
      'Finali',
      'Aperture',
    ]);
  });

  test('identificativi unici e tappe non vuote', () {
    final ids = [
      for (final c in curriculum)
        for (final s in c.stages) s.id,
    ];
    expect(ids.toSet(), hasLength(ids.length));
    for (final c in curriculum) {
      for (final s in c.stages) {
        expect(s.title, isNotEmpty);
        expect(
          s.exercises.isNotEmpty || s.guardianElo != null,
          isTrue,
          reason: s.id,
        );
      }
    }
  });

  test('ogni capitolo dopo il primo ha un bot guardiano finale', () {
    for (final c in curriculum.skip(1)) {
      expect(c.stages.last.guardianElo, isNotNull, reason: c.id);
    }
  });

  group('contenuti validi', () {
    for (final c in curriculum) {
      for (final s in c.stages) {
        for (final (i, e) in s.exercises.indexed) {
          test('${s.id} #${i + 1}', () {
            switch (e) {
              case StarsExercise():
                expect(e.stars, isNotEmpty);
                expect(e.stars, isNot(contains(e.start)));
                expect(e.optimalMoves, greaterThan(0));
              case LineExercise():
                _checkLine(e);
            }
          });
        }
      }
    }
  });
}

/// La soluzione è legale, ogni risposta è legale e, per i matti, le risposte
/// sono forzate e l'ultima mossa dà matto.
void _checkLine(LineExercise e) {
  Position pos = Chess.fromSetup(Setup.parseFen(e.fen));
  expect(pos.isGameOver, isFalse);
  for (final (i, step) in e.steps.indexed) {
    final playerStep = i.isEven;
    final options = step.split('|');
    if (!playerStep) {
      expect(options, hasLength(1));
      if (e.goal == LineGoal.mate) {
        expect(pos.legalMoves.values.fold(0, (n, s) => n + s.size), 1);
      }
    }
    for (final uci in options) {
      expect(
        pos.isLegal(Move.parse(uci)!),
        isTrue,
        reason: '$uci in ${pos.fen}',
      );
    }
    pos = pos.play(Move.parse(options.first)!);
  }
  expect(e.steps.length.isOdd, isTrue);
  if (e.goal == LineGoal.mate) expect(pos.isCheckmate, isTrue);
}
