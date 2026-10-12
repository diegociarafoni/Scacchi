import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/transport.dart';

Uint8List b(int v) => Uint8List.fromList([v]);

void main() {
  test('RMP-05 i due capi di un canale finto si parlano', () async {
    final (a, z) = LoopbackTransport.pair();
    final got = z.incoming.first;
    await a.send(b(1));
    expect(await got, b(1));
    await a.close();
    await z.close();
  });

  test('RMP-05 un canale spento rifiuta l\'invio', () async {
    final (a, z) = LoopbackTransport.pair();
    a.online = false;
    expect(() => a.send(b(1)), throwsA(isA<TransportUnavailable>()));
    await a.close();
    await z.close();
  });

  test('RMP-05 si invia su tutti i canali e basta che uno funzioni', () async {
    final (wifi, wifiPeer) = LoopbackTransport.pair(name: 'wifi');
    final (relay, relayPeer) = LoopbackTransport.pair(name: 'relay');
    final multi = MultiTransport([wifi, relay]);
    wifi.online = false;
    final got = relayPeer.incoming.first;
    await multi.send(b(5));
    expect(await got, b(5));
    await multi.close();
    await wifiPeer.close();
    await relayPeer.close();
  });

  test('RMP-05 senza alcun canale disponibile l\'invio fallisce', () async {
    final (wifi, wifiPeer) = LoopbackTransport.pair();
    final multi = MultiTransport([wifi]);
    wifi.online = false;
    expect(() => multi.send(b(1)), throwsA(isA<TransportUnavailable>()));
    await multi.close();
    await wifiPeer.close();
  });

  test(
    'RMP-05 si ricevono i messaggi di tutti i canali in un solo flusso',
    () async {
      final (wifi, wifiPeer) = LoopbackTransport.pair();
      final (relay, relayPeer) = LoopbackTransport.pair();
      final multi = MultiTransport([wifi, relay]);
      final got = <Uint8List>[];
      final sub = multi.incoming.listen(got.add);
      await wifiPeer.send(b(1));
      await relayPeer.send(b(2));
      await pumpEventQueue();
      expect(got, [b(1), b(2)]);
      await sub.cancel();
      await multi.close();
      await wifiPeer.close();
      await relayPeer.close();
    },
  );

  test(
    'RMP-06 un canale aggiunto durante la partita entra subito in gioco',
    () async {
      final (wifi, wifiPeer) = LoopbackTransport.pair();
      final multi = MultiTransport([wifi]);
      final got = <Uint8List>[];
      final sub = multi.incoming.listen(got.add);
      final (ble, blePeer) = LoopbackTransport.pair();
      multi.add(ble);
      wifi.online = false;
      final sent = blePeer.incoming.first;
      await multi.send(b(3));
      expect(await sent, b(3));
      await blePeer.send(b(4));
      await pumpEventQueue();
      expect(got, [b(4)]);
      await sub.cancel();
      await multi.close();
      await wifiPeer.close();
      await blePeer.close();
    },
  );

  test('RMP-05 un canale arrivato dopo la chiusura viene chiuso', () async {
    final multi = MultiTransport([]);
    await multi.close();
    final (late, latePeer) = LoopbackTransport.pair();
    multi.add(late);
    await pumpEventQueue();
    expect(() => latePeer.send(b(1)), throwsA(isA<TransportUnavailable>()));
    await latePeer.close();
  });
}
