import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/engine/levels.dart';
import 'package:rokko/path/curriculum.dart';
import 'package:rokko/path/exercise.dart';

void main() {
  test('RG-03 capitoli richiesti nell\'ordine del percorso', () {
    expect(curriculum.map((c) => c.title), [
      'Come si muovono i pezzi',
      'Catturare e difendere',
      'Le regole',
      'Matti elementari',
      'Tattiche',
      'Finali',
      'La strategia',
      'Aperture',
      'La scuola di Capablanca',
    ]);
    expect(curriculum.map((c) => c.id), [
      'moves',
      'pieces',
      'rules',
      'mates',
      'tactics',
      'endgames',
      'strategy',
      'openings',
      'capablanca',
    ]);
  });

  test(
    'RG-03 il capitolo 0 insegna le mosse dei pezzi, una lezione per pezzo',
    () {
      final moves = curriculum.firstWhere((c) => c.id == 'moves');
      expect(moves.stages.map((s) => s.id), [
        'moves.board',
        'pieces.rook',
        'pieces.bishop',
        'pieces.queen',
        'pieces.king',
        'pieces.knight',
        'pieces.pawn',
        'moves.pawn-capture',
        'moves.which-piece',
      ]);
      expect(moves.stages.any((s) => s.isGuardian), isFalse);
      final pieces = curriculum.firstWhere((c) => c.id == 'pieces');
      expect(pieces.stages.map((s) => s.id), [
        'pieces.capture',
        'pieces.hanging',
        'pieces.defend',
      ]);
    },
  );

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
      'mates.patterns-2',
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
      'tactics.overload',
      'tactics.decoy',
      'tactics.interference',
      'tactics.zwischenzug',
      'tactics.trapped',
      'tactics.xray',
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
      'endgames.key-squares',
      'endgames.triangulation',
      'endgames.breakthrough',
      'endgames.rook-behind',
      'endgames.wrong-bishop',
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

  test('RG-03 la strategia insegna i piani di base', () {
    final strategy = curriculum.firstWhere((c) => c.id == 'strategy');
    expect(strategy.stages.map((s) => s.id), [
      'strategy.value',
      'strategy.open-file',
      'strategy.outpost',
      'strategy.bishops',
      'strategy.passed-pawn',
      'strategy.active',
      'strategy.guardian',
    ]);
    expect(strategy.stages.last.guardianElo, 1100);
  });

  test('la scuola di Capablanca chiude il percorso', () {
    final capablanca = curriculum.last;
    expect(capablanca.id, 'capablanca');
    expect(capablanca.stages.map((s) => s.id), [
      'capablanca.race',
      'capablanca.distant-opposition',
      'capablanca.combinations',
      'capablanca.opening-rules',
      'capablanca.guardian',
    ]);
    expect(capablanca.stages.last.guardianElo, 1300);
  });

  test('l\'Elo dei guardiani cresce capitolo dopo capitolo', () {
    final elos = [
      for (final c in curriculum)
        for (final s in c.stages) ?s.guardianElo,
    ];
    expect(elos, [400, 800, 1000, 1100, 1200, 1300]);
    for (var i = 1; i < elos.length; i++) {
      expect(elos[i], greaterThan(elos[i - 1]));
    }
  });

  test('il livello del motore dei guardiani non scende mai', () {
    final levels = [
      for (final c in curriculum)
        for (final s in c.stages)
          if (s.guardianElo case final elo?) engineLevelForElo(elo).id,
    ];
    for (var i = 1; i < levels.length; i++) {
      expect(levels[i], greaterThanOrEqualTo(levels[i - 1]), reason: '$levels');
    }
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

  test(
    'gli esercizi «difendi» hanno un solo passo e un pezzo del giocatore',
    () {
      for (final s in curriculum.expand((c) => c.stages)) {
        for (final e in s.exercises.whereType<LineExercise>()) {
          if (e.goal != LineGoal.defend) continue;
          final pos = Chess.fromSetup(Setup.parseFen(e.fen));
          expect(e.steps, hasLength(1), reason: s.id);
          expect(pos.board.sideAt(e.guard!), pos.turn, reason: s.id);
        }
      }
    },
  );

  test('negli esercizi «difendi» non ci sono catture gratuite', () {
    const value = {
      Role.pawn: 1,
      Role.knight: 3,
      Role.bishop: 3,
      Role.rook: 5,
      Role.queen: 9,
      Role.king: 100,
    };
    for (final s in curriculum.expand((c) => c.stages)) {
      for (final e in s.exercises.whereType<LineExercise>()) {
        if (e.goal != LineGoal.defend) continue;
        final pos = Chess.fromSetup(Setup.parseFen(e.fen));
        for (final m in pos.legalMoves.entries) {
          for (final to in m.value.squares) {
            final victim = pos.board.roleAt(to);
            if (victim == null) continue;
            final mover = pos.board.roleAt(m.key)!;
            final promotes = mover == Role.pawn && (to.value >> 3 == 7);
            final after = pos.play(
              NormalMove(
                from: m.key,
                to: to,
                promotion: promotes ? Role.queen : null,
              ),
            );
            final recaptured = after.board
                .attacksTo(to, pos.turn.opposite)
                .isNotEmpty;
            expect(
              recaptured && value[victim]! <= value[mover]!,
              isTrue,
              reason:
                  '${s.id}: ${Move.parse('${m.key.name}${to.name}')} è '
                  'una cattura che conviene in ${e.fen}',
            );
          }
        }
      }
    }
  });

  test('la lezione «Difendere un pezzo» accetta ogni difesa del pezzo', () {
    final stage = stageById('pieces.defend')!;
    final accepted = [
      for (final e in stage.exercises.cast<LineExercise>()) _accepted(e),
    ];
    // Torre: Td1 e Ta2 difendono il cavallo, Tf1 no.
    expect(accepted[0], {'a1d1', 'a1a2'});
    // Pedone e4: il re lo difende da d3, e3 e f3.
    expect(accepted[1], {'e2d3', 'e2e3', 'e2f3'});
    // Alfiere d4: solo e3 lo difende con un pedone.
    expect(accepted[2], {'e2e3'});
    // Torre f3: la donna da a3, c3, d1 o a8, o il re da f2.
    expect(accepted[3], {'a1a3', 'a1c3', 'a1d1', 'a1a8', 'e1f2'});
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

/// Tutte le mosse legali che il gioco accetta al primo passo.
Set<String> _accepted(LineExercise e) {
  final pos = Chess.fromSetup(Setup.parseFen(e.fen));
  return {
    for (final m in pos.legalMoves.entries)
      for (final to in m.value.squares)
        if (LineRun(e).play(NormalMove(from: m.key, to: to)) !=
            MoveVerdict.wrong)
          NormalMove(from: m.key, to: to).uci,
  };
}
