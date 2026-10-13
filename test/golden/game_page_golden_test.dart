@Tags(['golden'])
library;

import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game_actions.dart';
import '../support/board.dart';
import '../support/devices.dart';

Future<void> _pumpApp(
  WidgetTester tester,
  Device device, {
  Brightness brightness = Brightness.light,
}) async {
  device.apply(tester);
  tester.platformDispatcher
    ..localesTestValue = [const Locale('it')]
    ..platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await _precacheImages(tester);
  // Senza audio: nei test non c'è il plugin nativo.
  SharedPreferences.setMockInitialValues({'sound': false});
  await tester.pumpWidget(const ScacchiApp());
  await tester.pumpAndSettle();
  await openBoard(tester);
  await _precacheImages(tester);
}

// I pezzi si disegnano solo dopo che chessground li ha decodificati nella sua
// cache, operazione asincrona fuori dal tempo simulato dei test.
Future<void> _precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    await ChessgroundImages.instance.loadAll(
      const ChessboardSettings().pieceAssets,
    );
    // Le immagini normali, come i pezzi catturati, vanno decodificate a parte.
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
}

Future<void> _play(WidgetTester tester, List<String> uci) async {
  await playByTaps(tester, uci);
  await _precacheImages(tester);
  await tester.pumpAndSettle();
}

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

void main() {
  for (final device in Device.values) {
    testWidgets('posizione iniziale su ${device.name}', skip: _skip != null, (
      tester,
    ) async {
      await _pumpApp(tester, device);
      await expectLater(
        find.byType(ScacchiApp),
        matchesGoldenFile('goldens/iniziale-${device.name}.png'),
      );
    });
  }

  testWidgets(
    'scacco matto in tema scuro su telefono medio',
    skip: _skip != null,
    (tester) async {
      await _pumpApp(tester, Device.phoneMedium, brightness: Brightness.dark);
      await _play(tester, [
        'e2e4',
        'e7e5',
        'f1c4',
        'b8c6',
        'd1h5',
        'g8f6',
        'h5f7',
      ]);
      await expectLater(
        find.byType(ScacchiApp),
        matchesGoldenFile('goldens/scacco-matto-scuro-telefono-medio.png'),
      );
    },
  );

  // In coda: le scacchiere dei golden precedenti dipendono dall'ordine delle prove.
  for (final (device, brightness) in [
    (Device.phoneSmall, Brightness.light),
    (Device.phoneMedium, Brightness.dark),
    (Device.phoneLarge, Brightness.light),
  ]) {
    testWidgets(
      'nuova partita, il menu ${brightness.name} su ${device.name}',
      skip: _skip != null,
      (tester) async {
        await _pumpApp(tester, device, brightness: brightness);
        await tester.tap(find.text('Nuova'));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ScacchiApp),
          matchesGoldenFile(
            'goldens/nuova-partita-menu-${brightness.name}-${device.name}.png',
          ),
        );
      },
    );
  }

  testWidgets('nuova partita, ognuno sul suo telefono', skip: _skip != null, (
    tester,
  ) async {
    await _pumpApp(tester, Device.phoneMedium, brightness: Brightness.dark);
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sfida un amico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ognuno sul suo telefono'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ScacchiApp),
      matchesGoldenFile('goldens/nuova-partita-amico-scuro-telefono-medio.png'),
    );
  });
}
