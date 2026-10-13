import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../localized_app.dart';
import 'game_qr_test.dart' show tapMove;

void main() {
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('de'),
        home: GamePage(
          settings: SettingsController.defaults(),
          store: MemoryStore(),
          now: () => DateTime(2026, 10, 13, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la partita in tedesco: stato, mosse e menu', (tester) async {
    await open(tester);
    expect(find.textContaining('am Zug'), findsOneWidget);
    await tapMove(tester, 'e2e4');
    expect(find.textContaining('Schwarz'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('il foglio Nuova partita in tedesco', (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Neue Partie'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
