import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/multiplayer_session.dart';
import 'package:scacchi/multiplayer/player_identity.dart';
import 'package:scacchi/multiplayer/transport.dart';

void main() {
  late PlayerIdentity hostId;
  late PlayerIdentity guestId;

  setUpAll(() async {
    hostId = await PlayerIdentity.generate();
    guestId = await PlayerIdentity.generate();
  });

  GameInvite invite() => GameInvite(
    gameId: newGameId(),
    secret: newSecret(),
    hostKey: hostId.publicKey,
    hostSide: Side.white,
  );

  test(
    'RMP-01 RMP-02 partita completa tra ospite e invitato su un canale',
    () async {
      final inv = invite();
      final (a, z) = LoopbackTransport.pair();
      final host = MultiplayerSession.host(inv, hostId, MultiTransport([a]));
      final guest = MultiplayerSession.join(inv, guestId, MultiTransport([z]));
      await guest.announce();
      await pumpEventQueue();
      expect(host.sync.peerKey, guestId.publicKey);

      await host.play('e2e4');
      await pumpEventQueue();
      await guest.play('e7e5');
      await pumpEventQueue();
      expect(host.sync.moves, ['e2e4', 'e7e5']);
      expect(guest.sync.moves, host.sync.moves);
      await host.close();
      await guest.close();
    },
  );

  test(
    'RMP-06 la partita passa dal canale locale al relay e torna locale',
    () async {
      final inv = invite();
      final (wifiA, wifiZ) = LoopbackTransport.pair(name: 'wifi');
      final (relayA, relayZ) = LoopbackTransport.pair(name: 'relay');
      final host = MultiplayerSession.host(
        inv,
        hostId,
        MultiTransport([wifiA, relayA]),
      );
      final guest = MultiplayerSession.join(
        inv,
        guestId,
        MultiTransport([wifiZ, relayZ]),
      );
      await guest.announce();
      await pumpEventQueue();

      await host.play('e2e4');
      await pumpEventQueue();
      // I giocatori si separano: niente Wi-Fi, resta il relay.
      wifiA.online = false;
      wifiZ.online = false;
      await guest.play('e7e5');
      await pumpEventQueue();
      await host.play('g1f3');
      await pumpEventQueue();
      // Di nuovo vicini: il relay cade, la Wi-Fi torna.
      relayA.online = false;
      relayZ.online = false;
      wifiA.online = true;
      wifiZ.online = true;
      await guest.play('b8c6');
      await pumpEventQueue();
      expect(host.sync.moves, ['e2e4', 'e7e5', 'g1f3', 'b8c6']);
      expect(guest.sync.moves, host.sync.moves);
      await host.close();
      await guest.close();
    },
  );

  test('RMP-06 chi è rimasto indietro recupera le mosse da solo', () async {
    final inv = invite();
    final (a, z) = LoopbackTransport.pair();
    final host = MultiplayerSession.host(inv, hostId, MultiTransport([a]));
    final guest = MultiplayerSession.join(inv, guestId, MultiTransport([z]));
    await guest.announce();
    await pumpEventQueue();
    await host.play('e2e4');
    await pumpEventQueue();
    await guest.play('e7e5');
    await pumpEventQueue();
    await guest.close();

    // L'invitato riparte da un salvataggio senza mosse.
    final (a2, z2) = LoopbackTransport.pair();
    host.transport.add(a2);
    final back = MultiplayerSession.join(inv, guestId, MultiTransport([z2]));
    await host.play('g1f3');
    await pumpEventQueue();
    expect(back.sync.moves, ['e2e4', 'e7e5', 'g1f3']);
    await host.close();
    await back.close();
  });

  test('RMP-06 al ritorno di un canale si ripete l\'ultima mossa', () async {
    final inv = invite();
    final (a, z) = LoopbackTransport.pair();
    final host = MultiplayerSession.host(inv, hostId, MultiTransport([a]));
    final guest = MultiplayerSession.join(inv, guestId, MultiTransport([z]));
    await guest.announce();
    await pumpEventQueue();
    a.online = false;
    await expectLater(host.play('e2e4'), completes);
    expect(host.pendingDelivery, isTrue);
    a.online = true;
    await host.resendLast();
    await pumpEventQueue();
    expect(host.pendingDelivery, isFalse);
    expect(guest.sync.moves, ['e2e4']);
    await host.close();
    await guest.close();
  });

  test('RMP-03 i messaggi di un intruso non toccano la partita', () async {
    final inv = invite();
    final (a, z) = LoopbackTransport.pair();
    final host = MultiplayerSession.host(inv, hostId, MultiTransport([a]));
    final guest = MultiplayerSession.join(inv, guestId, MultiTransport([z]));
    await guest.announce();
    await pumpEventQueue();
    await z.send(Uint8List.fromList(List.filled(80, 7)));
    await pumpEventQueue();
    expect(host.sync.moves, isEmpty);
    await host.close();
    await guest.close();
  });
}
