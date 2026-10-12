import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/home/home_shell.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/settings/settings.dart';

import '../game_actions.dart';
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
  await tester.pumpAndSettle();
}

void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('home_game');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('finire una partita nella scheda Gioca assegna XP', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: HomeShell(
          settings: SettingsController.defaults(),
          progress: () async => progress,
          archive: () async => GameArchive(File('${dir.path}/games.json')),
          reminderScheduler: () => null,
        ),
      ),
    );
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    expect(progress.state.xp, 0);
    for (final uci in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
      await tapMove(tester, uci);
    }
    expect(progress.state.xp, greaterThan(0));
  });
}
