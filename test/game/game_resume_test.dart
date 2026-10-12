import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Move, Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';

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

String fen(WidgetTester tester) =>
    tester.widget<Chessboard>(find.byType(Chessboard)).controller.game.fen;

void main() {
  final saved = <SavedGame>[];

  Future<void> open(
    WidgetTester tester, {
    SavedGame? resume,
    bool computer = false,
  }) async {
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
          settings: SettingsController.defaults()
            ..value = AppSettings(sound: false),
          computerAvailable: computer,
          now: () => DateTime(2026, 10, 12, 9),
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
          onSave: (g) async => saved.add(g),
          resume: resume,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  SavedGame unfinished({String mode = SavedGame.local, Side? side, int? elo}) {
    final game = ChessGame();
    for (final m in ['e2e4', 'e7e5', 'g1f3']) {
      game.play(Move.parse(m)!);
    }
    final t = DateTime(2026, 10, 11, 18);
    return SavedGame.fromGame(
      game,
      id: 'in-corso',
      white: side == Side.white ? 'Tu' : 'Bianco',
      black: side == Side.white ? 'Computer' : 'Nero',
      mode: mode,
      createdAt: t,
      updatedAt: t,
      playerSide: side,
      opponentElo: elo,
    );
  }

  testWidgets('ogni mossa salva la partita in corso con lo stesso id', (
    tester,
  ) async {
    await open(tester);
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await openCustomSheet(tester, two: true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    await tapMove(tester, 'e2e4');
    await tapMove(tester, 'e7e5');
    expect(saved, hasLength(2));
    expect(saved.last.result, '*');
    expect(saved.last.finished, isFalse);
    expect(saved.last.pgn, contains('1. e4 e5'));
    expect(saved.map((g) => g.id).toSet(), hasLength(1));
  });

  testWidgets('una partita senza mosse non si salva', (tester) async {
    await open(tester);
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await openCustomSheet(tester, two: true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
  });

  testWidgets('riprendere una partita tra due persone la rimette in campo', (
    tester,
  ) async {
    final game = unfinished();
    await open(tester, resume: game);
    final start = ChessGame();
    for (final m in ['e2e4', 'e7e5', 'g1f3']) {
      start.play(Move.parse(m)!);
    }
    expect(fen(tester), start.position.fen);
    await tapMove(tester, 'b8c6');
    expect(saved.last.id, 'in-corso');
    expect(saved.last.createdAt, game.createdAt);
    expect(saved.last.pgn, contains('1. e4 e5 2. Nf3 Nc6'));
  });

  testWidgets('riprendere una partita contro il computer lo fa rispondere', (
    tester,
  ) async {
    await open(
      tester,
      computer: true,
      resume: unfinished(mode: SavedGame.computer, side: Side.white, elo: 900),
    );
    // Tocca al Nero, cioè al computer: risponde da solo.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(saved.last.id, 'in-corso');
    expect(saved.last.pgn, contains(RegExp(r'2\. Nf3 \S+')));
  });
}
