import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/path/exercise.dart';

void main() {
  test('RG-03 capitoli richiesti nell\'ordine del percorso', () {
    expect(curriculum.map((c) => c.title), [
      'Il movimento dei pezzi',
      'Le regole',
      'Matti elementari',
      'Tattiche',
      'Finali',
      'Aperture',
    ]);
  });

  test('ogni lezione ha una spiegazione breve', () {
    for (final c in curriculum) {
      for (final s in c.stages.where((s) => !s.isGuardian)) {
        expect(s.intro, isNotNull, reason: s.id);
        expect(s.intro!.trim(), isNotEmpty, reason: s.id);
        expect(s.intro!.length, lessThanOrEqualTo(400), reason: s.id);
      }
    }
  });

  test('RG-03 i matti elementari coprono gli schemi principali', () {
    final mates = curriculum.firstWhere((c) => c.id == 'mates');
    expect(mates.stages.map((s) => s.id), [
      'mates.one',
      'mates.back-rank',
      'mates.queen',
      'mates.rooks',
      'mates.patterns',
      'mates.two',
      'mates.guardian',
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

  test('dai Matti in poi ogni capitolo ha un bot guardiano finale', () {
    final mates = curriculum.indexWhere((c) => c.id == 'mates');
    for (final c in curriculum.skip(mates)) {
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
  if (e.goal == LineGoal.mate) _checkAlternatives(e);
  if (e.goal == LineGoal.check) expect(pos.isCheck, isTrue);
}

/// Nei matti in più mosse ogni prima mossa che forza il matto è accettata.
void _checkAlternatives(LineExercise e) {
  final moves = (e.steps.length + 1) ~/ 2;
  if (moves < 2) return;
  final pos = Chess.fromSetup(Setup.parseFen(e.fen));
  final accepted = {
    for (final uci in e.steps.first.split('|'))
      pos.makeSan(Move.parse(uci)!).$2,
  };
  for (final m in _legal(pos)) {
    if (_forcesMate(pos.play(m), moves - 1)) {
      expect(accepted, contains(pos.makeSan(m).$2), reason: e.fen);
    }
  }
}

Iterable<Move> _legal(Position pos) sync* {
  for (final e in pos.legalMoves.entries) {
    for (final to in e.value.squares) {
      yield NormalMove(from: e.key, to: to);
    }
  }
}

/// Con il nero al tratto, il bianco dà matto in [n] mosse qualunque cosa
/// risponda il nero.
bool _forcesMate(Position pos, int n) {
  if (pos.isCheckmate) return true;
  if (n == 0 || pos.isGameOver) return false;
  return _legal(pos).every((reply) {
    final after = pos.play(reply);
    return _legal(after).any((m) => _forcesMate(after.play(m), n - 1));
  });
}
