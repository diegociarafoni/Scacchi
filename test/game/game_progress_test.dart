import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/progress/activity.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_state.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/progress/progress_tracker.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart';

Offset square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(square(tester, uci.substring(2, 4)));
  await tester.pumpAndSettle();
}

const foolsMate = ['f2f3', 'e7e5', 'g2g4', 'd8h4'];

void main() {
  final activities = <Activity>[];
  final saved = <SavedGame>[];

  Future<void> open(WidgetTester tester, {bool computer = false}) async {
    activities.clear();
    saved.clear();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: GamePage(
          settings: SettingsController.defaults(),
          computerAvailable: computer,
          now: () => DateTime(2026, 10, 11, 12),
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
          onActivity: (a) async {
            activities.add(a);
            return const ProgressUpdate(
              state: ProgressState.initial,
              xpGained: 10,
            );
          },
          onSave: (g) async => saved.add(g),
        ),
      ),
    );
  }

  testWidgets('a fine partita tra due persone registra XP e archivio', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    for (final uci in foolsMate) {
      await tapMove(tester, uci);
    }
    expect(activities, hasLength(1));
    final activity = activities.single as GamePlayed;
    expect(activity.result, GameResult.local);
    expect(activity.checkmate, isTrue);
    expect(saved.map((g) => g.id).toSet(), hasLength(1));
    expect(saved.last.mode, SavedGame.local);
    expect(saved.last.result, '0-1');
    expect(saved.last.white, 'Bianco');
    expect(saved.last.pgn, contains('Qh4#'));
    expect(find.textContaining('+10 XP'), findsOneWidget);
  });

  testWidgets('una partita già registrata non si ripete', (tester) async {
    await open(tester);
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    for (final uci in foolsMate) {
      await tapMove(tester, uci);
    }
    await tester.pump(const Duration(seconds: 10));
    expect(activities, hasLength(1));
    expect(saved.where((g) => g.finished), hasLength(1));
  });

  Future<void> startLocal(WidgetTester tester) async {
    await open(tester);
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
  }

  Future<void> resign(WidgetTester tester) async {
    await tester.tap(find.text('Abbandona'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbandona').last);
    await tester.pumpAndSettle();
  }

  testWidgets('abbandonare subito non dà XP ma la partita si archivia', (
    tester,
  ) async {
    await startLocal(tester);
    await tapMove(tester, 'e2e4');
    await resign(tester);
    expect(activities, isEmpty);
    expect(saved.map((g) => g.id).toSet(), hasLength(1));
    expect(saved.last.result, '1-0');
  });

  testWidgets('senza mosse non si archivia nulla', (tester) async {
    await startLocal(tester);
    await resign(tester);
    expect(activities, isEmpty);
    expect(saved, isEmpty);
  });

  testWidgets('dopo l\'annulla l\'archivio si aggiorna e gli XP restano uno', (
    tester,
  ) async {
    await startLocal(tester);
    for (final uci in ['e2e4', 'e7e5', 'g1f3', 'b8c6']) {
      await tapMove(tester, uci);
    }
    await resign(tester);
    expect(saved.last.result, '0-1');
    expect(activities, hasLength(1));
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    for (final uci in ['f1c4', 'g8f6', 'f3g5', 'd7d5', 'e4d5']) {
      await tapMove(tester, uci);
    }
    await resign(tester);
    expect(saved.where((g) => g.finished), hasLength(2));
    expect(saved.map((g) => g.id).toSet(), hasLength(1));
    expect(saved.last.pgn, contains('Bc4'));
    expect(activities, hasLength(1));
  });

  testWidgets('una posizione dell\'editor si archivia ma non dà XP', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byTooltip('Editor di posizione'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Incolla FEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Incolla FEN'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      '4k3/8/8/8/8/8/4Q3/4K3 b - - 0 1',
    );
    await tester.tap(find.text('Carica'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gioca da qui'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gioca da qui'));
    await tester.pumpAndSettle();
    for (final uci in ['e8d8', 'e1d1', 'd8e8', 'd1e1']) {
      await tapMove(tester, uci);
    }
    await resign(tester);
    expect(activities, isEmpty);
    expect(saved.map((g) => g.id).toSet(), hasLength(1));
  });

  testWidgets('contro il computer la partita ha giocatore ed Elo', (
    tester,
  ) async {
    await open(tester, computer: true);
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tapMove(tester, 'd1h5');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tapMove(tester, 'h5f7');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Il motore finto non difende: se la partita non è finita, si abbandona.
    if (activities.isEmpty) {
      await tester.tap(find.text('Abbandona'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbandona').last);
      await tester.pumpAndSettle();
    }
    expect(activities, hasLength(1));
    final activity = activities.single as GamePlayed;
    expect(activity.playerSide, Side.white);
    expect(activity.opponentElo, isNotNull);
    expect(saved.last.mode, SavedGame.computer);
    expect(saved.last.white, 'Tu');
    expect(saved.last.black, 'Computer');
    expect(saved.last.opponentElo, activity.opponentElo);
  });

  testWidgets('le impostazioni mostrano i progressi quando sono disponibili', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('game_settings');
    addTearDown(() => dir.deleteSync(recursive: true));
    late ProgressController progress;
    await tester.runAsync(() async {
      progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
      await progress.load();
    });
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: GamePage(
          settings: SettingsController.defaults(),
          progress: () async => progress,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('unlockAll')), 300);
    expect(find.byKey(const Key('unlockAll')), findsOneWidget);
  });
}
