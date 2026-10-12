import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/bot_gallery/bot_gallery_page.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/game/opponent_picker.dart';

import '../localized_app.dart';
import '../support/devices.dart';

void main() {
  group('RG-18 entrata dalla scelta dell\'avversario', () {
    testWidgets('la scelta nella galleria arriva alla configurazione', (
      tester,
    ) async {
      Device.phoneMedium.apply(tester);
      var setup = const GameSetup(opponent: Opponent.bot);
      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: OpponentPicker(
                  setup: setup,
                  computerAvailable: true,
                  adaptiveLevel: 1,
                  collection: const BotCollection(),
                  onChanged: (s) => setState(() => setup = s),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-bot-gallery')));
      await tester.pumpAndSettle();
      expect(find.byType(BotGalleryPage), findsOneWidget);
      await tester.tap(find.byKey(const Key('bot-nico')));
      await tester.tap(find.byKey(const Key('side-black')));
      await tester.tap(find.byKey(const Key('gallery-play')));
      await tester.pumpAndSettle();
      expect(setup.botId, 'nico');
      expect(setup.sideChoice, SideChoice.black);
      expect(setup.opponent, Opponent.bot);
    });

    testWidgets('il tasto indietro lascia la scelta com\'era', (tester) async {
      Device.phoneMedium.apply(tester);
      var setup = const GameSetup(opponent: Opponent.bot);
      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OpponentPicker(
                setup: setup,
                computerAvailable: true,
                adaptiveLevel: 1,
                collection: const BotCollection(),
                onChanged: (s) => setup = s,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-bot-gallery')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(setup.botId, 'pino');
    });

    test('Adattivo imposta il computer adattivo e lascia il bot', () {
      const result = BotGalleryResult(
        botId: 'pino',
        sideChoice: SideChoice.white,
        adaptive: true,
      );
      final setup = result.applyTo(const GameSetup(botId: 'rocco'));
      expect(setup.opponent, Opponent.computer);
      expect(setup.adaptive, isTrue);
      expect(setup.botId, 'rocco');
      expect(setup.sideChoice, SideChoice.white);
    });
  });
}
