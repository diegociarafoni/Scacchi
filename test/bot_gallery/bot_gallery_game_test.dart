import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';

void main() {
  Widget app() => MaterialApp(
    home: GamePage(
      settings: SettingsController.defaults(),
      computerAvailable: true,
      store: MemoryStore(),
      now: () => TestWidgetsFlutterBinding.instance.clock.now(),
      createComputer: () =>
          ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
    ),
  );

  testWidgets(
    'RG-18 la partita parte dalla galleria con bot e cadenza scelti',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tapGameAction(tester, 'Nuova');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('open-bot-gallery')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-bot-gallery')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bot-nico')));
      await tester.tap(find.byKey(const Key('gallery-options')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('option-time-5+0')));
      await tester.tap(find.byKey(const Key('options-done')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gallery-play')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.textContaining('Nico'), findsWidgets);
      expect(find.textContaining('5:00'), findsWidgets);
    },
  );
}
