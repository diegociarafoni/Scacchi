import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/path/exercise.dart';

/// Gioca ogni combinazione di alternative previste e verifica che
/// l'esercizio resti completabile fino alla fine.
void _explore(LineExercise e, List<String> played, List<String> failures) {
  final run = LineRun(e);
  for (final uci in played) {
    run.play(Move.parse(uci)!);
  }
  if (run.done) return;
  final last = run.step == e.steps.length - 1;
  // All'ultimo passo di un matto vale qualunque matto, come nel gioco.
  final listed = e.steps[run.step].split('|');
  final options = last && e.goal == LineGoal.mate
      ? [
          ...listed,
          for (final m in run.position.legalMoves.entries)
            for (final to in m.value.squares)
              for (final promotion in [null, Role.queen])
                if (run.position.isLegal(
                      NormalMove(from: m.key, to: to, promotion: promotion),
                    ) &&
                    run.position
                        .play(
                          NormalMove(from: m.key, to: to, promotion: promotion),
                        )
                        .isCheckmate)
                  NormalMove(from: m.key, to: to, promotion: promotion).uci,
        ]
      : listed;
  final legal = options.where((u) => run.position.isLegal(Move.parse(u)!));
  if (legal.isEmpty) {
    failures.add('${e.fen} dopo $played: nessuna mossa legale');
  }
  for (final uci in legal) {
    final move = Move.parse(uci)!;
    final probe = LineRun(e);
    for (final p in played) {
      probe.play(Move.parse(p)!);
    }
    final verdict = probe.play(move);
    if (verdict == MoveVerdict.wrong) {
      failures.add('${e.fen} dopo $played: $uci rifiutata');
    } else if (verdict == MoveVerdict.correct) {
      _explore(e, [...played, uci], failures);
    }
  }
}

void main() {
  test(
    'ogni lezione a mosse attese si può completare con ogni alternativa',
    () {
      final failures = <String>[];
      for (final c in curriculum) {
        for (final s in c.stages) {
          for (final e in s.exercises.whereType<LineExercise>()) {
            final before = failures.length;
            _explore(e, const [], failures);
            if (failures.length > before) failures.insert(before, s.id);
          }
        }
      }
      expect(failures, isEmpty);
    },
  );
}
