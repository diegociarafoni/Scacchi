@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/bot_gallery/bot_gallery_page.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/progress/avatar.dart';
import 'package:scacchi/progress/guardian_avatar.dart';
import 'package:scacchi/story/story.dart';
import 'package:scacchi/theme/rokko_theme.dart';

import '../support/devices.dart';

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

final _progress = BotCollection({
  for (final id in ['lia', 'pino', 'nico', 'chiara']) id: DateTime(2026, 10, 5),
});

Future<void> _pump(
  WidgetTester tester,
  Device device,
  Widget home, {
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  Locale locale = const Locale('it'),
}) async {
  device.apply(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark
          ? RokkoTheme.dark()
          : RokkoTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _golden(WidgetTester tester, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/$name.png'),
);

BotGalleryPage _gallery({
  String? initial = 'chiara',
  bool kid = false,
  BotCollection? collection,
}) => BotGalleryPage(
  collection: collection ?? _progress,
  story: const StoryState(beaten: {'prologue', 'village'}),
  initialBotId: initial,
  adaptiveLevel: 4,
  kidMode: kid,
);

void main() {
  for (final device in Device.phones) {
    testWidgets('galleria dei bot su ${device.name}', skip: _skip != null, (
      tester,
    ) async {
      await _pump(tester, device, _gallery());
      await _golden(tester, 'galleria-bot-${device.name}');
    });
  }

  testWidgets(
    'galleria dei bot in fondo: Adattivo e custodi',
    skip: _skip != null,
    (tester) async {
      await _pump(tester, Device.phoneMedium, _gallery());
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -2000),
      );
      await tester.pumpAndSettle();
      await _golden(tester, 'galleria-bot-in-fondo-telefono-medio');
    },
  );

  testWidgets('galleria dei bot in tema chiaro', skip: _skip != null, (
    tester,
  ) async {
    await _pump(
      tester,
      Device.phoneMedium,
      _gallery(),
      brightness: Brightness.light,
    );
    await _golden(tester, 'galleria-bot-chiaro-telefono-medio');
  });

  testWidgets('galleria dei bot con un bot bloccato', skip: _skip != null, (
    tester,
  ) async {
    await _pump(
      tester,
      Device.phoneMedium,
      _gallery(initial: 'stella', collection: const BotCollection()),
    );
    await _golden(tester, 'galleria-bot-bloccato-telefono-medio');
  });

  testWidgets('galleria dei bot col testo al 130%', skip: _skip != null, (
    tester,
  ) async {
    await _pump(tester, Device.phoneSmall, _gallery(), textScale: 1.3);
    await _golden(tester, 'galleria-bot-testo-130-telefono-piccolo');
  });

  testWidgets('galleria dei bot in inglese', skip: _skip != null, (
    tester,
  ) async {
    await _pump(
      tester,
      Device.phoneMedium,
      _gallery(),
      locale: const Locale('en'),
    );
    await _golden(tester, 'galleria-bot-inglese-telefono-medio');
  });

  testWidgets('galleria dei bot, profilo bambino', skip: _skip != null, (
    tester,
  ) async {
    await _pump(
      tester,
      Device.phoneMedium,
      _gallery(kid: true, initial: 'pino'),
      brightness: Brightness.light,
    );
    await _golden(tester, 'galleria-bot-bambino-telefono-medio');
  });

  testWidgets(
    'tutti i personaggi con le sei espressioni',
    skip: _skip != null,
    (tester) async {
      final everyone = [...bots, ...storyOnlyBots];
      await _pump(
        tester,
        Device.tablet,
        Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final bot in everyone)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final e in AvatarExpression.values)
                        Padding(
                          padding: const EdgeInsets.all(3),
                          child: GuardianAvatar(bot: bot, expression: e),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
      await _golden(tester, 'personaggi-espressioni');
    },
  );
}
