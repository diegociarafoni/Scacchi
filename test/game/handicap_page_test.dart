import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/stats/local_rating.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';

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

void main() {
  final saved = <SavedGame>[];

  Future<void> open(WidgetTester tester, {bool computer = false}) async {
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
          onSave: (g) async => saved.add(g),
        ),
      ),
    );
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String key) async {
    if (find.byKey(ValueKey(key)).hitTestable().evaluate().isEmpty) {
      await scrollSheetTo(tester, find.text('Handicap'));
      await tester.tap(find.text('Handicap'));
      await tester.pumpAndSettle();
    }
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> resign(WidgetTester tester) async {
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbandona').last);
    await tester.pumpAndSettle();
  }

  testWidgets('RF-27 due giocatori: il Nero dà la donna', (tester) async {
    await open(tester);
    await pick(tester, 'handicap-piece-queen');
    await pick(tester, 'handicap-giver-opponent');
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle();
    await tapMove(tester, 'e2e4');
    await resign(tester);
    final pgn = saved.last.pgn;
    expect(pgn, contains('[Handicap "Black gives queen"]'));
    expect(
      pgn,
      contains(
        '[FEN "rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"]',
      ),
    );
    expect(pgn, contains('[SetUp "1"]'));
  });

  testWidgets('RF-27 handicap di tempo: chi concede parte con meno minuti', (
    tester,
  ) async {
    await open(tester);
    await pick(tester, 'handicap-time-3');
    await chooseTime(tester, '10+0');
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('clock-white'))).data,
      '3:00',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('clock-black'))).data,
      '10:00',
    );
  });

  testWidgets('RF-27 un tempo non inferiore alla cadenza viene ignorato', (
    tester,
  ) async {
    await open(tester);
    await pick(tester, 'handicap-time-5');
    await chooseTime(tester, '3+0');
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('clock-white'))).data,
      '3:00',
    );
  });

  testWidgets('RF-27 contro il computer non conta per il rating locale', (
    tester,
  ) async {
    await open(tester, computer: true);
    await chooseAdaptiveComputer(tester);
    await pick(tester, 'handicap-piece-rook');
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await resign(tester);
    final game = saved.last;
    expect(game.mode, SavedGame.computer);
    expect(game.playerSide, Side.white);
    expect(game.pgn, contains('[Handicap "White gives rook"]'));
    expect(game.opponentElo, isNull);
    expect(LocalRating.from([game]).history, isEmpty);
  });

  testWidgets('senza handicap la partita col computer conta per il rating', (
    tester,
  ) async {
    await open(tester, computer: true);
    await chooseAdaptiveComputer(tester);
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await resign(tester);
    expect(saved.last.pgn, isNot(contains('Handicap')));
    expect(saved.last.opponentElo, isNotNull);
  });
}
