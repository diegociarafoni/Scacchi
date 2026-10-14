import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/minigames/capture_all_page.dart';
import 'package:rokko/path/curriculum.dart';
import 'package:rokko/path/stage_page.dart';
import 'package:rokko/settings/settings.dart';

import '../localized_app.dart';

final _night = AppSettings(boardTheme: BoardTheme.night, tableMode: true);

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final settings = SettingsController.defaults();
  await settings.update(_night);
  await tester.pumpWidget(
    SettingsScope(
      controller: settings,
      child: localizedApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectPlayerTheme(WidgetTester tester) {
  final settings = tester.widget<Chessboard>(find.byType(Chessboard)).settings;
  expect(settings.colorScheme, _night.exerciseBoard.colorScheme);
  expect(settings.pieceAssets, _night.exerciseBoard.pieceAssets);
  expect(
    settings.pieceOrientationBehavior,
    PieceOrientationBehavior.facingUser,
  );
}

void main() {
  testWidgets('le tappe del percorso usano il tema del giocatore', (
    tester,
  ) async {
    await _pump(tester, StagePage(stage: stageById('pieces.king')!));
    _expectPlayerTheme(tester);
  });

  testWidgets('cattura tutto usa il tema del giocatore', (tester) async {
    await _pump(tester, CaptureAllPage(random: Random(5), onFinished: (_) {}));
    _expectPlayerTheme(tester);
  });
}
