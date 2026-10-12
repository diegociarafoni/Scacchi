import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Move, Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/openings/repertoire.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../computer_fakes.dart';
import '../localized_app.dart';

void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('apertura');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> openRepertoire(
    WidgetTester tester, {
    bool computer = true,
  }) async {
    final trainer = await RepertoireTrainer.load(MemoryStore());
    await trainer.addLine(Side.black, 'Siciliana', [
      Move.parse('e2e4')!,
      Move.parse('c7c5')!,
    ]);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: SettingsController.defaults(),
          progress: () async => progress,
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          repertoire: () async => trainer,
          reminderScheduler: () => null,
          computerAvailable: computer,
          createComputer: () => ComputerPlayer(
            connect: () async => FirstLegalMoveEngine(script: ['e2e4']),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aperture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repertorio con il Nero'));
    await tester.pumpAndSettle();
  }

  testWidgets('RF-94 dal repertorio si apre la partita lungo la linea', (
    tester,
  ) async {
    await openRepertoire(tester);
    await tester.tap(find.byTooltip('Gioca la linea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gioca'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Siciliana'), findsOneWidget);
    expect(find.byType(Chessboard), findsOneWidget);
    // Il computer, con il Bianco, ha già giocato 1. e4 come la linea.
    expect(find.text('1. e4'), findsOneWidget);
    expect(find.textContaining('uscito dalla linea'), findsNothing);
  });

  testWidgets('RF-94 senza motore il repertorio non offre la partita', (
    tester,
  ) async {
    await openRepertoire(tester, computer: false);
    expect(find.byTooltip('Gioca la linea'), findsNothing);
  });
}
