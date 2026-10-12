import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/main.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/game_actions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RF-120 una nuova partita Chess960 mescola la prima traversa', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();

    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chess960'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chess960 n. '), findsOneWidget);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-27 una partita a handicap parte senza la donna del Bianco', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();

    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Handicap'));
    await tester.pumpAndSettle();
    final queen = find.byKey(const ValueKey('handicap-piece-queen'));
    await tester.ensureVisible(queen);
    await tester.pumpAndSettle();
    await tester.tap(queen);
    await tester.pumpAndSettle();
    final none = find.text('Senza tempo');
    await tester.ensureVisible(none);
    await tester.pumpAndSettle();
    await tester.tap(none);
    await tester.pumpAndSettle();
    expect(find.text('Partita a handicap'), findsOneWidget);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-123 il computer risponde a Re della collina', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          settings: SettingsController.defaults(),
          computerAvailable: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Computer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nero'));
    await tester.tap(find.text('Nero'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Re della collina'));
    await tester.tap(find.text('Re della collina'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Senza tempo'));
    await tester.tap(find.text('Senza tempo'));
    await tester.pump();

    // La ricerca gira in un isolate vero: si aspetta fuori dal tempo finto.
    final reply = find.text('Muove il Nero.');
    for (var i = 0; i < 100 && reply.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(reply, findsOneWidget);
    expect(find.textContaining('1. '), findsOneWidget);
  });
}
