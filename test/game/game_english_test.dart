import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/storage/key_value_store.dart';

import '../localized_app.dart';
import 'game_qr_test.dart' show tapMove;

void main() {
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: GamePage(
          settings: SettingsController.defaults(),
          store: MemoryStore(),
          now: () => DateTime(2026, 10, 13, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la partita in inglese: stato, mosse e menu', (tester) async {
    await open(tester);
    expect(find.text('White to move.'), findsOneWidget);
    expect(
      find.text('Tap a piece, then the square you want to move it to.'),
      findsOneWidget,
    );
    await tapMove(tester, 'e2e4');
    expect(find.text('Black to move.'), findsOneWidget);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Type a move'), findsOneWidget);
  });

  testWidgets('il foglio Nuova partita in inglese', (tester) async {
    await open(tester);
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Challenge a friend'), findsOneWidget);
    expect(find.text('Start game'), findsOneWidget);
  });
}
