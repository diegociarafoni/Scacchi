import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/chess_game.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late Directory dir;
  late ProgressController progress;
  late GameArchive archive;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('home-apri');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
    archive = GameArchive(File('${dir.path}/games.json'));
    final game = ChessGame();
    for (final m in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
      game.play(Move.parse(m)!);
    }
    final t = DateTime(2026, 10, 10, 9);
    await archive.save(
      SavedGame.fromGame(
        game,
        id: 'matto',
        white: 'Anna',
        black: 'Bruno',
        mode: 'locale',
        createdAt: t,
        updatedAt: t,
      ),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> openArchive(WidgetTester tester, {bool computer = true}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          settings: SettingsController.defaults()
            ..value = AppSettings(sound: false),
          progress: () async => progress,
          archive: () async => archive,
          reminderScheduler: () => null,
          computerAvailable: computer,
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        ),
      ),
    );
    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Archivio'), 200);
    await tester.ensureVisible(find.text('Archivio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archivio'));
    await settle(tester);
    await tester.tap(find.text('Anna – Bruno'));
    await settle(tester);
  }

  testWidgets('una partita dell\'archivio si apre nella revisione', (
    tester,
  ) async {
    await openArchive(tester);
    expect(find.text('Revisione della partita'), findsOneWidget);
  });

  testWidgets('senza motore la revisione lo dice', (tester) async {
    await openArchive(tester, computer: false);
    expect(find.text('Revisione della partita'), findsNothing);
    expect(
      find.text(
        'La revisione richiede il motore, disponibile su Android e iOS.',
      ),
      findsOneWidget,
    );
  });
}
