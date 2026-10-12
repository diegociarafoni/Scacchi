import 'dart:io';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/ble_link.dart';
import 'package:scacchi/multiplayer/channel_registry.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/multiplayer_controller.dart';
import 'package:scacchi/multiplayer/saved_game.dart';
import 'package:scacchi/multiplayer/transport.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

/// Registra un canale Bluetooth finto: l'ospite prende [a], l'invitato [b].
List<(String, bool)> registerFakeBle(MessageTransport a, MessageTransport b) {
  final seen = <(String, bool)>[];
  extraChannelFactories.add((invite, {required isHost}) async {
    if (!invite.ble) return null;
    seen.add((invite.gameId, isHost));
    return isHost ? a : b;
  });
  return seen;
}

Never noLan() => fail('la rete locale non serve');

void main() {
  tearDown(extraChannelFactories.clear);

  test(
    'RMP-20 l\'ospite crea un invito Bluetooth senza indirizzo di rete',
    () async {
      final (a, b) = LoopbackTransport.pair(name: 'bluetooth');
      final seen = registerFakeBle(a, b);
      final host = await MultiplayerController.host(
        side: Side.white,
        bluetooth: true,
        openHost: () async => noLan(),
      );
      await settle();
      final invite = GameInvite.parse(host.inviteLink)!;
      expect(invite.ble, isTrue);
      expect(invite.lanAddress, isNull);
      expect(seen, [(invite.gameId, true)]);
      expect(host.status, MultiplayerStatus.waitingPeer);
      expect(host.session.transport.name, 'bluetooth');
      await host.close();
    },
  );

  test(
    'RMP-20 si gioca una partita intera via Bluetooth, senza Wi-Fi',
    () async {
      final (a, b) = LoopbackTransport.pair(name: 'bluetooth');
      registerFakeBle(a, b);
      final host = await MultiplayerController.host(
        side: Side.white,
        bluetooth: true,
      );
      final guest = await MultiplayerController.join(
        GameInvite.parse(host.inviteLink)!,
        openGuest: (_, _) => noLan(),
      );
      await settle();
      expect(host.status, MultiplayerStatus.myTurn);
      expect(guest.status, MultiplayerStatus.peerTurn);
      for (final (c, uci) in [
        (host, 'f2f3'),
        (guest, 'e7e5'),
        (host, 'g2g4'),
        (guest, 'd8h4'),
      ]) {
        expect(await c.play(Move.parse(uci)!), isTrue);
        await settle();
      }
      expect(host.outcome, Outcome.blackWins);
      expect(guest.status, MultiplayerStatus.finished);
      await host.close();
      await guest.close();
    },
  );

  test('RMP-20 un invito Wi-Fi non apre il Bluetooth', () async {
    final (a, _) = LoopbackTransport.pair();
    final host = await MultiplayerController.host(
      side: Side.white,
      openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
    );
    final invite = GameInvite.parse(host.inviteLink)!;
    expect(invite.ble, isFalse);
    // Il canale registrato davvero rinuncia senza toccare il Bluetooth.
    expect(await openBleChannel(invite, isHost: true), isNull);
    expect(await openBleChannel(invite, isHost: false), isNull);
    await host.close();
  });

  test('RMP-20 un invito senza Wi-Fi né Bluetooth non si può usare', () async {
    final i = GameInvite(
      gameId: newGameId(),
      secret: newSecret(),
      hostKey: Uint8List(32),
      hostSide: Side.white,
    );
    await expectLater(
      MultiplayerController.join(i),
      throwsA(isA<NoLocalNetwork>()),
    );
  });

  test(
    'RMP-20 un invito con Wi-Fi e Bluetooth usa tutti e due i canali',
    () async {
      final (wa, wb) = LoopbackTransport.pair(name: 'wifi');
      final (ba, bb) = LoopbackTransport.pair(name: 'bluetooth');
      final seen = registerFakeBle(ba, bb);
      final invite = GameInvite(
        gameId: newGameId(),
        secret: newSecret(),
        hostKey: Uint8List(32),
        hostSide: Side.white,
        lanAddress: '10.0.0.2:4000',
        ble: true,
      );
      var wifi = 0;
      final guest = await MultiplayerController.join(
        invite,
        openGuest: (_, _) {
          wifi++;
          return wb;
        },
      );
      await settle();
      expect(wifi, 1);
      expect(seen, [(invite.gameId, false)]);
      expect(guest.session.transport.name, 'wifi+bluetooth');
      await guest.close();
      await wa.close();
    },
  );

  test('RMP-20 dopo un riavvio la partita Bluetooth riprende', () async {
    final dir = Directory.systemTemp.createTempSync('rokko_ble_resume');
    addTearDown(() => dir.deleteSync(recursive: true));
    final hostStore = SavedGameStore(File('${dir.path}/host.json'));
    final guestStore = SavedGameStore(File('${dir.path}/guest.json'));
    var (a, b) = LoopbackTransport.pair(name: 'bluetooth');
    registerFakeBle(a, b);
    final host = await MultiplayerController.host(
      side: Side.white,
      bluetooth: true,
      store: hostStore,
    );
    final guest = await MultiplayerController.join(
      GameInvite.parse(host.inviteLink)!,
      store: guestStore,
    );
    await settle();
    await host.play(Move.parse('e2e4')!);
    await settle();
    final gameId = GameInvite.parse(host.inviteLink)!.gameId;
    await host.close();
    await guest.close();

    extraChannelFactories.clear();
    (a, b) = LoopbackTransport.pair(name: 'bluetooth');
    final seen = registerFakeBle(a, b);
    final host2 = await MultiplayerController.resume(
      (await hostStore.load())!,
      openHost: (_) async => noLan(),
      store: hostStore,
    );
    final guest2 = await MultiplayerController.resume(
      (await guestStore.load())!,
      openGuest: (_, _) => noLan(),
      store: guestStore,
    );
    await settle();
    expect(seen, [(gameId, true), (gameId, false)]);
    expect(guest2.status, MultiplayerStatus.myTurn);
    expect(await guest2.play(Move.parse('c7c5')!), isTrue);
    await settle();
    expect(host2.session.sync.moves, ['e2e4', 'c7c5']);
    expect(GameInvite.parse(host2.inviteLink)!.ble, isTrue);
    await host2.close();
    await guest2.close();
  });

  test('RMP-20 il controllo del Bluetooth segnala il motivo', () {
    expect(
      const BluetoothUnavailable(BluetoothProblem.off).toString(),
      contains('off'),
    );
  });
}
