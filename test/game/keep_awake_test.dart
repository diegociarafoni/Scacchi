import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';

import '../game_actions.dart';

void main() {
  final calls = <bool>[];

  Future<SettingsController> start(
    WidgetTester tester, {
    bool keepAwake = true,
  }) async {
    calls.clear();
    final settings = SettingsController.defaults();
    await settings.update(settings.value.copyWith(keepAwake: keepAwake));
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          settings: settings,
          computerAvailable: false,
          keepAwake: (on) async => calls.add(on),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return settings;
  }

  testWidgets('RM-06 durante la partita lo schermo resta acceso', (
    tester,
  ) async {
    await start(tester);
    expect(calls, [true]);
  });

  testWidgets('RM-06 uscendo dalla partita lo schermo torna normale', (
    tester,
  ) async {
    await start(tester);
    await tester.pumpWidget(const SizedBox());
    expect(calls, [true, false]);
  });

  testWidgets('RM-06 a partita finita lo schermo torna normale', (
    tester,
  ) async {
    await start(tester);
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbandona').last);
    await tester.pumpAndSettle();
    expect(calls.last, isFalse);
  });

  testWidgets('RM-06 l\'opzione spenta lascia lo schermo com\'è', (
    tester,
  ) async {
    final settings = await start(tester, keepAwake: false);
    expect(calls, isEmpty);
    await settings.update(settings.value.copyWith(keepAwake: true));
    await tester.pump();
    expect(calls, [true]);
    await settings.update(settings.value.copyWith(keepAwake: false));
    await tester.pump();
    expect(calls, [true, false]);
  });
}
