import 'dart:io';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/lan_transport.dart';
import 'package:scacchi/multiplayer/multiplayer_session.dart';
import 'package:scacchi/multiplayer/player_identity.dart';
import 'package:scacchi/multiplayer/transport.dart';

Uint8List bytes(List<int> v) => Uint8List.fromList(v);

Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 150));

void main() {
  test(
    'RMP-07 ospite e invitato si scambiano messaggi in rete locale',
    () async {
      final host = await LanTransport.host(
        address: InternetAddress.loopbackIPv4,
      );
      final guest = LanTransport.connect('127.0.0.1', host.port);
      final atHost = <Uint8List>[];
      final atGuest = <Uint8List>[];
      host.incoming.listen(atHost.add);
      guest.incoming.listen(atGuest.add);
      await guest.send(bytes([1, 2, 3]));
      await settle();
      await host.send(bytes([4]));
      await settle();
      expect(atHost, [
        bytes([1, 2, 3]),
      ]);
      expect(atGuest, [
        bytes([4]),
      ]);
      await guest.close();
      await host.close();
    },
  );

  test('RMP-07 l\'ospite senza nessuno collegato non può inviare', () async {
    final host = await LanTransport.host(address: InternetAddress.loopbackIPv4);
    await expectLater(
      host.send(bytes([1])),
      throwsA(isA<TransportUnavailable>()),
    );
    await host.close();
  });

  test(
    'RMP-07 l\'invitato senza ospite raggiungibile non può inviare',
    () async {
      final spare = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = spare.port;
      await spare.close();
      final guest = LanTransport.connect('127.0.0.1', port);
      await expectLater(
        guest.send(bytes([1])),
        throwsA(isA<TransportUnavailable>()),
      );
      await guest.close();
    },
  );

  test('RMP-07 un messaggio spezzato in più pacchetti arriva intero', () async {
    final host = await LanTransport.host(address: InternetAddress.loopbackIPv4);
    final got = <Uint8List>[];
    host.incoming.listen(got.add);
    final raw = await Socket.connect(InternetAddress.loopbackIPv4, host.port);
    // Lunghezza 3 su 4 byte big-endian, poi i dati, a pezzi.
    raw.add([0, 0]);
    await raw.flush();
    await settle();
    raw.add([0, 3, 9]);
    await raw.flush();
    await settle();
    raw.add([8, 7, 0, 0, 0, 1, 5]);
    await raw.flush();
    await settle();
    expect(got, [
      bytes([9, 8, 7]),
      bytes([5]),
    ]);
    await raw.close();
    await host.close();
  });

  test('RMP-07 un pacchetto troppo grande chiude il collegamento', () async {
    final host = await LanTransport.host(address: InternetAddress.loopbackIPv4);
    final got = <Uint8List>[];
    host.incoming.listen(got.add);
    final raw = await Socket.connect(InternetAddress.loopbackIPv4, host.port);
    final closed = raw.drain<void>();
    raw.add([0, 1, 0, 0]); // 65 536 byte annunciati
    await raw.flush();
    await closed.timeout(const Duration(seconds: 2));
    expect(got, isEmpty);
    expect(host.connections, 0);
    raw.destroy();
    await host.close();
  });

  test('RMP-07 l\'ospite accetta un numero limitato di collegamenti', () async {
    final host = await LanTransport.host(
      address: InternetAddress.loopbackIPv4,
      maxConnections: 2,
    );
    final sockets = [
      for (var i = 0; i < 3; i++)
        await Socket.connect(InternetAddress.loopbackIPv4, host.port),
    ];
    await settle();
    expect(host.connections, 2);
    for (final s in sockets) {
      s.destroy();
    }
    await host.close();
  });

  test('RMP-07 oltre il limite cede il collegamento più vecchio', () async {
    final host = await LanTransport.host(
      address: InternetAddress.loopbackIPv4,
      maxConnections: 1,
    );
    final stale = await Socket.connect(InternetAddress.loopbackIPv4, host.port);
    final staleClosed = stale.drain<void>();
    await settle();
    final fresh = await Socket.connect(InternetAddress.loopbackIPv4, host.port);
    await staleClosed.timeout(const Duration(seconds: 2));
    expect(host.connections, 1);
    stale.destroy();
    fresh.destroy();
    await host.close();
  });

  test('RMP-06 RMP-07 l\'invitato si ricollega da solo e lo segnala', () async {
    final host = await LanTransport.host(address: InternetAddress.loopbackIPv4);
    final port = host.port;
    final guest = LanTransport.connect('127.0.0.1', port);
    var connected = 0;
    guest.connected.listen((_) => connected++);
    await guest.send(bytes([1]));
    // Il collegamento aperto da un invio non va segnalato: la mossa è già
    // in viaggio.
    expect(connected, 0);
    await host.close();
    await settle();
    await expectLater(
      guest.send(bytes([2])),
      throwsA(isA<TransportUnavailable>()),
    );
    final again = await LanTransport.host(
      address: InternetAddress.loopbackIPv4,
      port: port,
    );
    final got = guest.incoming.first;
    // Nessun invio dall'invitato: si ricollega da solo.
    while (again.connections == 0) {
      await settle();
    }
    expect(connected, 1);
    await again.send(bytes([3]));
    expect(await got, bytes([3]));
    await guest.close();
    await again.close();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('RMP-07 chiudere durante il ricollegamento non lascia code', () async {
    final host = await LanTransport.host(address: InternetAddress.loopbackIPv4);
    final guest = LanTransport.connect('127.0.0.1', host.port);
    final sending = guest.send(bytes([1]));
    await guest.close();
    await expectLater(sending, throwsA(isA<TransportUnavailable>()));
    await settle();
    expect(host.connections, 0);
    await host.close();
  });

  test('RMP-06 RMP-07 partita su Wi-Fi tra ospite e invitato', () async {
    final hostId = await PlayerIdentity.generate();
    final guestId = await PlayerIdentity.generate();
    final lanHost = await LanTransport.host(
      address: InternetAddress.loopbackIPv4,
    );
    final invite = GameInvite(
      gameId: newGameId(),
      secret: newSecret(),
      hostKey: hostId.publicKey,
      hostSide: Side.white,
      lanAddress: '127.0.0.1:${lanHost.port}',
    );
    final host = MultiplayerSession.host(
      invite,
      hostId,
      MultiTransport([lanHost]),
    );
    final guest = MultiplayerSession.join(
      invite,
      guestId,
      MultiTransport([LanTransport.connect('127.0.0.1', lanHost.port)]),
    );
    expect(await guest.announce(), isTrue);
    await settle();
    expect(host.sync.peerKey, guestId.publicKey);
    await host.play('e2e4');
    await settle();
    await guest.play('e7e5');
    await settle();
    expect(host.sync.moves, ['e2e4', 'e7e5']);
    await host.close();
    await guest.close();
  });

  test(
    'RMP-06 RMP-07 caduto il collegamento, la mossa arriva al rientro',
    () async {
      final hostId = await PlayerIdentity.generate();
      final guestId = await PlayerIdentity.generate();
      final lanHost = await LanTransport.host(
        address: InternetAddress.loopbackIPv4,
        maxConnections: 1,
      );
      final invite = GameInvite(
        gameId: newGameId(),
        secret: newSecret(),
        hostKey: hostId.publicKey,
        hostSide: Side.white,
        lanAddress: '127.0.0.1:${lanHost.port}',
      );
      final host = MultiplayerSession.host(
        invite,
        hostId,
        MultiTransport([lanHost]),
      );
      final guest = MultiplayerSession.join(
        invite,
        guestId,
        MultiTransport([LanTransport.connect('127.0.0.1', lanHost.port)]),
      );
      expect(await guest.announce(), isTrue);
      await settle();
      // Un intruso occupa l'unico posto: l'invitato viene scollegato e la
      // mossa del Bianco parte verso chi non la capisce.
      final intruder = await Socket.connect(
        InternetAddress.loopbackIPv4,
        lanHost.port,
      );
      await settle();
      await host.play('e2e4');
      intruder.destroy();
      // L'invitato rientra da solo e riceve la mossa rimasta indietro.
      for (var i = 0; i < 60 && guest.sync.moves.isEmpty; i++) {
        await settle();
      }
      expect(guest.sync.moves, ['e2e4']);
      await guest.play('e7e5');
      await settle();
      expect(host.sync.moves, ['e2e4', 'e7e5']);
      await host.close();
      await guest.close();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
