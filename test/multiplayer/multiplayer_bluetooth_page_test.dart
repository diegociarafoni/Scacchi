import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/exchange/qr_code_view.dart';
import 'package:scacchi/multiplayer/ble_link.dart';
import 'package:scacchi/multiplayer/channel_registry.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/multiplayer_page.dart';
import 'package:scacchi/multiplayer/transport.dart';

import '../localized_app.dart';

Future<void> _wait(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

void main() {
  setUp(extraChannelFactories.clear);
  tearDown(extraChannelFactories.clear);

  testWidgets('RMP-20 si sceglie Bluetooth e il QR porta l\'invito Bluetooth', (
    tester,
  ) async {
    final checks = <bool>[];
    await tester.pumpWidget(
      localizedApp(
        home: MultiplayerPage(
          openHost: () async => fail('la rete locale non serve'),
          bluetoothCheck: ({required isHost}) async => checks.add(isHost),
        ),
      ),
    );
    expect(find.text('Come collegarvi'), findsOneWidget);
    await tester.tap(find.text('Bluetooth'));
    await tester.pump();
    expect(find.textContaining('vicini'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Crea la partita'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Crea la partita'));
    await tester.pump();
    await tester.tap(find.text('Crea la partita'));
    await _wait(tester);
    await tester.pumpAndSettle();
    final view = tester.widget<QrCodeView>(find.byType(QrCodeView));
    final invite = GameInvite.parse(view.data)!;
    expect(invite.ble, isTrue);
    expect(invite.lanAddress, isNull);
    expect(checks, [true]);
    expect(find.text('In attesa dell\'avversario…'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tenete i telefoni vicini: le mosse viaggiano via Bluetooth.'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Tenete i telefoni vicini: le mosse viaggiano via Bluetooth.'),
      findsOneWidget,
    );
  });

  testWidgets('RMP-20 chi inquadra un invito Bluetooth entra via Bluetooth', (
    tester,
  ) async {
    final (a, b) = LoopbackTransport.pair();
    extraChannelFactories.add(
      (invite, {required isHost}) async => isHost ? a : b,
    );
    final invite = GameInvite(
      gameId: newGameId(),
      secret: newSecret(),
      hostKey: Uint8List(32),
      hostSide: Side.white,
      ble: true,
    );
    ValueChanged<String>? scanned;
    final checks = <bool>[];
    await tester.pumpWidget(
      localizedApp(
        home: MultiplayerPage(
          scanner: (context, {required onCode, required onError}) {
            scanned = onCode;
            return const SizedBox(key: Key('scan'));
          },
          bluetoothCheck: ({required isHost}) async => checks.add(isHost),
          openGuest: (_, _) => fail('la rete locale non serve'),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Unisciti con il QR'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Unisciti con il QR'));
    await tester.pump();
    await tester.tap(find.text('Unisciti con il QR'));
    await tester.pumpAndSettle();
    scanned!(invite.toLink());
    await _wait(tester);
    await tester.pumpAndSettle();
    expect(checks, [false]);
    expect(find.text('Tocca all\'avversario'), findsOneWidget);
  });

  testWidgets('RMP-20 un invito con anche il Wi-Fi non pretende il Bluetooth', (
    tester,
  ) async {
    final (a, b) = LoopbackTransport.pair();
    final invite = GameInvite(
      gameId: newGameId(),
      secret: newSecret(),
      hostKey: Uint8List(32),
      hostSide: Side.white,
      lanAddress: '10.0.0.2:4000',
      ble: true,
    );
    ValueChanged<String>? scanned;
    final checks = <bool>[];
    await tester.pumpWidget(
      localizedApp(
        home: MultiplayerPage(
          scanner: (context, {required onCode, required onError}) {
            scanned = onCode;
            return const SizedBox();
          },
          bluetoothCheck: ({required isHost}) async => checks.add(isHost),
          openGuest: (_, _) => b,
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Unisciti con il QR'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Unisciti con il QR'));
    await tester.pump();
    await tester.tap(find.text('Unisciti con il QR'));
    await tester.pumpAndSettle();
    scanned!(invite.toLink());
    await _wait(tester);
    await tester.pumpAndSettle();
    expect(checks, isEmpty);
    expect(find.text('Tocca all\'avversario'), findsOneWidget);
    await a.close();
  });

  for (final (problem, text) in [
    (BluetoothProblem.off, 'Accendi il Bluetooth'),
    (BluetoothProblem.denied, 'permesso Bluetooth'),
    (BluetoothProblem.unsupported, 'non supporta il Bluetooth'),
  ]) {
    testWidgets('RMP-20 problema $problem: avviso chiaro', (tester) async {
      await tester.pumpWidget(
        localizedApp(
          home: MultiplayerPage(
            bluetoothCheck: ({required isHost}) async =>
                throw BluetoothUnavailable(problem),
          ),
        ),
      );
      await tester.tap(find.text('Bluetooth'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Crea la partita'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Crea la partita'));
      await tester.pump();
      await tester.tap(find.text('Crea la partita'));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining(text), findsOneWidget);
    });
  }

  testWidgets(
    'RMP-20 con il Wi-Fi scelto non compare il suggerimento Bluetooth',
    (tester) async {
      await tester.pumpWidget(localizedApp(home: const MultiplayerPage()));
      expect(find.textContaining('vicini'), findsNothing);
    },
  );
}
