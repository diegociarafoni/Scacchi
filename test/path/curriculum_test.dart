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

  test('RG-03 le tattiche coprono i temi principali', () {
    final tactics = curriculum.firstWhere((c) => c.id == 'tactics');
    expect(tactics.stages.map((s) => s.id), [
      'tactics.hanging',
      'tactics.fork',
      'tactics.pin',
      'tactics.skewer',
      'tactics.discovered',
      'tactics.double-check',
      'tactics.defender',
      'tactics.guardian',
    ]);
  });

  test('RG-03 finali e aperture con le idee di base', () {
    List<String> ids(String chapter) => [
      for (final s in curriculum.firstWhere((c) => c.id == chapter).stages)
        s.id,
    ];
    expect(ids('endgames'), [
      'endgames.queen',
      'endgames.rook',
      'endgames.square',
      'endgames.opposition',
      'endgames.breakthrough',
      'endgames.guardian',
    ]);
    expect(ids('openings'), [
      'openings.center',
      'openings.develop',
      'openings.castle',
      'openings.scholar',
      'openings.guardian',
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

  test('ogni lezione ha da 4 a 5 esercizi', () {
    for (final c in curriculum) {
      for (final s in c.stages.where((s) => !s.isGuardian)) {
        expect(s.exercises.length, inInclusiveRange(4, 5), reason: s.id);
      }
    }
  });

  test('nessun esercizio ripete la partenza di un altro', () {
    final seen = <String, String>{};
    for (final c in curriculum) {
      for (final s in c.stages) {
        for (final (i, e) in s.exercises.indexed) {
          final start = switch (e) {
            StarsExercise() => '${e.role.name} ${e.start.name}',
            // Contatori ed en passant non cambiano la posizione.
            LineExercise() => e.fen.split(' ').take(3).join(' '),
          };
          final where = '${s.id} #${i + 1}';
          expect(seen.putIfAbsent(start, () => where), where, reason: start);
        }
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

/// La soluzione è legale, ogni risposta è legale dopo ogni alternativa
/// accettata e, per i matti, le risposte sono forzate e ogni ramo finisce con
/// il matto.
void _checkLine(LineExercise e) {
  final start = Chess.fromSetup(Setup.parseFen(e.fen));
  expect(start.isGameOver, isFalse);
  expect(e.steps.length.isOdd, isTrue);
  void walk(Position pos, int i, {required bool main}) {
    if (i == e.steps.length) {
      if (e.goal == LineGoal.mate) expect(pos.isCheckmate, isTrue);
      if (e.goal == LineGoal.check) expect(pos.isCheck, isTrue);
      return;
    }
    // L'ultimo passo di un matto accetta qualunque matto: dopo un'alternativa
    // può servirne uno diverso da quello scritto.
    if (!main && e.goal == LineGoal.mate && i == e.steps.length - 1) {
      expect(
        _legal(pos).any((m) => pos.play(m).isCheckmate),
        isTrue,
        reason: 'nessun matto in ${pos.fen}',
      );
      return;
    }
    final options = e.steps[i].split('|');
    if (i.isOdd) {
      expect(options, hasLength(1));
      if (e.goal == LineGoal.mate) {
        expect(pos.legalMoves.values.fold(0, (n, s) => n + s.size), 1);
      }
    }
    for (final (j, uci) in options.indexed) {
      final move = Move.parse(uci)!;
      expect(pos.isLegal(move), isTrue, reason: '$uci in ${pos.fen}');
      walk(pos.play(move), i + 1, main: main && j == 0);
    }
  }

  walk(start, 0, main: true);
  if (e.goal == LineGoal.mate) _checkAlternatives(e);
}

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
