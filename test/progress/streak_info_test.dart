import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/daily_goal.dart';
import 'package:scacchi/progress/streak_info.dart';

StreakInfo info({
  int streak = 0,
  int best = 0,
  int freezes = 0,
  DailyGoal goal = const DailyGoal(GoalKind.games, 1),
  int progress = 0,
  bool restDayToday = false,
}) => describeStreak(
  streak: streak,
  bestStreak: best,
  freezes: freezes,
  goal: goal,
  progress: progress,
  restDayToday: restDayToday,
);

void main() {
  group('cosa serve ogni giorno', () {
    test('partite', () {
      expect(
        info().requirement,
        'Per tenere accesa la serie, ogni giorno: gioca 1 partita.',
      );
      expect(
        info(goal: const DailyGoal(GoalKind.games, 3)).requirement,
        'Per tenere accesa la serie, ogni giorno: gioca 3 partite.',
      );
    });

    test('puzzle e minuti', () {
      expect(
        info(goal: const DailyGoal(GoalKind.puzzles, 5)).requirement,
        'Per tenere accesa la serie, ogni giorno: risolvi 5 puzzle.',
      );
      expect(
        info(goal: const DailyGoal(GoalKind.minutes, 10)).requirement,
        'Per tenere accesa la serie, ogni giorno: allenati per 10 minuti.',
      );
    });
  });

  group('stato di oggi', () {
    test('da fare, con quanto manca', () {
      expect(info().today, 'Oggi: da fare. Manca 1 partita.');
      expect(
        info(goal: const DailyGoal(GoalKind.puzzles, 5), progress: 3).today,
        'Oggi: da fare. Mancano 2 puzzle.',
      );
      expect(
        info(goal: const DailyGoal(GoalKind.minutes, 10), progress: 4).today,
        'Oggi: da fare. Mancano 6 minuti.',
      );
    });

    test('fatto', () {
      expect(
        info(progress: 1, streak: 1).today,
        'Oggi: fatto. La serie è al sicuro fino a domani.',
      );
    });

    test('giorno di riposo', () {
      expect(
        info(restDayToday: true, streak: 4).today,
        'Oggi è il tuo giorno di riposo: la serie non si interrompe.',
      );
      // Raggiungere l'obiettivo anche nel giorno di riposo conta normalmente.
      expect(
        info(restDayToday: true, progress: 1, streak: 5).today,
        'Oggi: fatto. La serie è al sicuro fino a domani.',
      );
    });
  });

  group('prossimo traguardo', () {
    test('3, 7 e 30 giorni', () {
      expect(
        info().milestone,
        'Prossimo traguardo: 3 giorni di fila (ne mancano 3).',
      );
      expect(
        info(streak: 2).milestone,
        'Prossimo traguardo: 3 giorni di fila (ne manca 1).',
      );
      expect(
        info(streak: 3).milestone,
        'Prossimo traguardo: 7 giorni di fila (ne mancano 4).',
      );
      expect(
        info(streak: 29).milestone,
        'Prossimo traguardo: 30 giorni di fila (ne manca 1).',
      );
    });

    test('oltre il mese non ce ne sono altri', () {
      expect(info(streak: 30).milestone, isNull);
    });
  });

  group('se si salta un giorno', () {
    test('senza serie si invita a iniziare', () {
      expect(
        info().ifSkipped,
        'Raggiungi l\'obiettivo oggi per iniziare una serie.',
      );
    });

    test('una protezione copre il giorno saltato', () {
      expect(
        info(streak: 5, freezes: 1).ifSkipped,
        'Se salti un giorno, una protezione lo copre (ne hai 1). '
        'Ne guadagni una ogni 7 giorni, al massimo 2.',
      );
      expect(info(streak: 5, freezes: 2).ifSkipped, contains('(ne hai 2)'));
    });

    test('senza protezioni la serie riparte, il record resta', () {
      expect(
        info(streak: 5, best: 9).ifSkipped,
        'Se salti un giorno, la serie riparte da zero; il record di 9 '
        'giorni resta. Ogni 7 giorni di serie guadagni una protezione.',
      );
    });
  });

  test('riepilogo breve per la scheda Tu', () {
    expect(info().summary, 'Oggi: da fare');
    expect(info(progress: 1, streak: 1).summary, 'Oggi: fatto');
    expect(info(restDayToday: true).summary, 'Oggi: riposo');
  });
}
