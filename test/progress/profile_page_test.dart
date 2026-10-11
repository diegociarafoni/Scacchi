import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/daily_goal.dart';
import 'package:scacchi/progress/profile_page.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_feedback.dart';
import 'package:scacchi/progress/progress_store.dart';

void main() {
  late Directory dir;
  late ProgressController controller;
  var now = DateTime(2026, 10, 5, 12);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('profile');
    now = DateTime(2026, 10, 5, 12);
    controller = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => now,
    );
    await controller.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: ProfilePage(controller: controller)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RG-01 mostra livello e XP', (tester) async {
    await tester.runAsync(
      () => controller.record(const GamePlayed(result: GameResult.win)),
    );
    await show(tester);
    expect(find.text('Livello 1'), findsOneWidget);
    expect(find.text('${controller.state.xp} / 100 XP'), findsOneWidget);
  });

  testWidgets('RG-02 mostra serie e obiettivo del giorno', (tester) async {
    await tester.runAsync(
      () => controller.record(const GamePlayed(result: GameResult.loss)),
    );
    await show(tester);
    expect(find.text('1 giorno di fila'), findsOneWidget);
    expect(find.text('Obiettivo raggiunto: 1 / 1 partite'), findsOneWidget);
  });

  testWidgets('RG-02 cambia obiettivo e giorno di riposo', (tester) async {
    await show(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('goal')), 200);
    await tester.ensureVisible(find.byKey(const Key('goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 puzzle').last);
    await tester.pumpAndSettle();
    expect(controller.settings.goal, const DailyGoal(GoalKind.puzzles, 5));

    await tester.scrollUntilVisible(find.byKey(const Key('restDay')), 200);
    await tester.ensureVisible(find.byKey(const Key('restDay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('restDay')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lunedì').last);
    await tester.pumpAndSettle();
    expect(controller.settings.restDay, DateTime.monday);
  });

  testWidgets('RG-05 traguardi ottenuti e da ottenere', (tester) async {
    await tester.runAsync(
      () => controller.record(const GamePlayed(result: GameResult.loss)),
    );
    await show(tester);
    await tester.scrollUntilVisible(find.text('Prima partita'), 200);
    await tester.ensureVisible(find.text('Prima partita'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Prima partita, ottenuto')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Prima vittoria, da ottenere')),
      findsOneWidget,
    );
  });

  testWidgets('RG-07 mostra le sfide di oggi e della settimana', (
    tester,
  ) async {
    await show(tester);
    await tester.scrollUntilVisible(find.text('Sfide di oggi'), 200);
    for (final (c, _) in controller.challenges) {
      expect(find.text(c.title), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Sfida della settimana'), 200);
    expect(find.text(controller.weeklyChallenge.$1.title), findsOneWidget);
  });

  testWidgets('RG-08 mostra i record personali', (tester) async {
    await tester.runAsync(
      () => controller.record(
        const GamePlayed(
          result: GameResult.win,
          opponentElo: 1400,
          moveCount: 22,
          checkmate: true,
        ),
      ),
    );
    await show(tester);
    await tester.scrollUntilVisible(find.text('Record personali'), 200);
    await tester.scrollUntilVisible(find.text('Bot più forte battuto'), 200);
    expect(find.text('1400 Elo'), findsOneWidget);
    expect(find.text('22 mosse'), findsOneWidget);
  });

  testWidgets('RG-10 record dei minigiochi con il loro nome', (tester) async {
    await tester.runAsync(
      () => controller.record(
        const MinigameFinished(game: 'coordinate', score: 17),
      ),
    );
    await show(tester);
    await tester.scrollUntilVisible(find.text('Coordinate a tempo'), 200);
    expect(find.text('17'), findsOneWidget);
  });

  testWidgets('RG-12 con la gamification spenta il profilo è nascosto', (
    tester,
  ) async {
    await show(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('enabled')), 200);
    await tester.ensureVisible(find.byKey(const Key('enabled')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enabled')));
    await tester.pumpAndSettle();
    expect(controller.settings.enabled, isFalse);
    expect(find.textContaining('Livello'), findsNothing);
    expect(find.textContaining('di fila'), findsNothing);
  });

  testWidgets('RG-05 notifica in-app dei nuovi traguardi', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final update = await tester.runAsync(
      () => controller.record(const GamePlayed(result: GameResult.win)),
    );
    showProgressFeedback(context, update!);
    await tester.pump();
    expect(find.textContaining('Prima vittoria'), findsOneWidget);
    expect(find.textContaining('+${update.xpGained} XP'), findsOneWidget);
  });

  test('RG-07 RG-08 il messaggio cita sfide e record', () async {
    await controller.record(
      const GamePlayed(result: GameResult.win, opponentElo: 900),
    );
    final update = await controller.record(
      const GamePlayed(result: GameResult.win, opponentElo: 1000),
    );
    final message = progressMessage(update)!;
    for (final c in update.challengesCompleted) {
      expect(message, contains('Sfida completata: ${c.title}'));
    }
    expect(message, contains('Nuovo record: bot più forte battuto'));
  });

  test('le impostazioni sopravvivono al riavvio', () async {
    await controller.updateSettings(
      controller.settings.copyWith(goal: const DailyGoal(GoalKind.minutes, 10)),
    );
    final again = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => now,
    );
    await again.load();
    expect(again.settings.goal, const DailyGoal(GoalKind.minutes, 10));
  });
}
