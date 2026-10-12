import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/path/curriculum.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart';
import '../localized_app.dart';

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
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  late Directory dir;
  late ProgressController progress;
  late PathController path;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('guardian');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
    path = PathController(File('${dir.path}/path.json'));
    await path.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> openGuardian(WidgetTester tester, {bool computer = true}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: SettingsController.defaults(),
          progress: () async => progress,
          path: () async => path,
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          reminderScheduler: () => null,
          computerAvailable: computer,
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        ),
      ),
    );
    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Percorso'));
    await tester.pumpAndSettle();
    final guardian = find.bySemanticsLabel(RegExp('^Il guardiano, da fare'));
    await tester.scrollUntilVisible(guardian, 200);
    await tester.ensureVisible(guardian.first);
    await tester.pumpAndSettle();
    await tester.tap(guardian.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  Future<void> unlockFirstGuardian(WidgetTester tester) async {
    var p = path.progress;
    final mates = curriculum.indexWhere((c) => c.id == 'mates');
    for (final c in curriculum.take(mates + 1)) {
      for (final s in c.stages.where((s) => !s.isGuardian)) {
        p = p.complete(s.id, 3);
      }
    }
    await tester.runAsync(() => path.replace(p));
  }

  testWidgets('il guardiano apre una partita già impostata', (tester) async {
    await unlockFirstGuardian(tester);
    await openGuardian(tester);
    expect(find.text('Il guardiano'), findsOneWidget);
    expect(find.textContaining('Computer, livello'), findsOneWidget);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('perdere con il guardiano non dà stelle', (tester) async {
    await unlockFirstGuardian(tester);
    await openGuardian(tester);
    final before = path.progress.stars.length;
    await tester.tap(find.text('Abbandona'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbandona').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(path.progress.stars.length, before);
  });

  testWidgets('vincere con il guardiano dà le stelle alla tappa', (
    tester,
  ) async {
    await unlockFirstGuardian(tester);
    await openGuardian(tester);
    final before = path.progress.stars.length;
    // Il motore finto gioca la prima mossa legale: il matto del barbiere basta.
    for (final uci in ['e2e4', 'f1c4', 'd1h5', 'h5f7']) {
      await tapMove(tester, uci);
    }
    expect(find.textContaining('Scacco matto'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(path.progress.stars.length, before + 1);
  });

  testWidgets('senza motore il guardiano mostra l\'avviso', (tester) async {
    await unlockFirstGuardian(tester);
    await openGuardian(tester, computer: false);
    expect(
      find.text(
        'Il guardiano si sfida dove gioca il computer: Android e iOS, o Windows e Linux con Stockfish installato.',
      ),
      findsOneWidget,
    );
  });
}
