import 'dart:convert';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/multiplayer/nostr_event.dart';
import 'package:rokko/multiplayer/nostr_transport.dart';
import 'package:rokko/multiplayer/transport.dart';

import 'fake_relay.dart';

Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  final secret = Uint8List.fromList(List.generate(32, (i) => 255 - i));
  const gameId = '3f1c2b9e-5d1a-4c7e-8b0a-1f2e3d4c5b6a';
  final relayUrl = Uri.parse('wss://relay.prova');
  final open = <NostrTransport>[];

  Future<NostrTransport> player(
    Side side,
    List<FakeRelay> relays, {
    Duration ackTimeout = const Duration(seconds: 2),
  }) async {
    final t = await NostrTransport.open(
      gameId: gameId,
      secret: secret,
      side: side,
      relays: [
        for (var i = 0; i < relays.length; i++)
          Uri.parse('wss://relay$i.prova'),
      ],
      connector: (url) {
        final i = int.parse(url.host.substring(5, url.host.indexOf('.')));
        return relays[i].connect(url);
      },
      ackTimeout: ackTimeout,
      minBackoff: const Duration(milliseconds: 20),
      maxBackoff: const Duration(milliseconds: 80),
    );
    open.add(t);
    return t;
  }

  tearDown(() async {
    for (final t in open) {
      await t.close();
    }
    open.clear();
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 60));

  test('RMP-31 un messaggio inviato da un lato arriva all\'altro', () async {
    final relay = FakeRelay();
    final white = await player(Side.white, [relay]);
    final black = await player(Side.black, [relay]);
    await settle();
    final got = black.incoming.first;
    await white.send(bytes('mossa 1'));
    expect(await got.timeout(const Duration(seconds: 2)), bytes('mossa 1'));
  });

  test(
    'RMP-31 chi arriva dopo trova l\'ultimo messaggio già sul relay',
    () async {
      final relay = FakeRelay();
      final white = await player(Side.white, [relay]);
      await settle();
      await white.send(bytes('mossa 1'));
      final black = await player(Side.black, [relay]);
      final got = await black.incoming.first.timeout(
        const Duration(seconds: 2),
      );
      expect(got, bytes('mossa 1'));
    },
  );

  test('RMP-31 non si riceve ciò che si è inviato', () async {
    final relay = FakeRelay();
    final white = await player(Side.white, [relay]);
    await settle();
    final seen = <Uint8List>[];
    white.incoming.listen(seen.add);
    await white.send(bytes('mia'));
    await settle();
    expect(seen, isEmpty);
  });

  test(
    'RMP-31 sul relay restano solo gli ultimi messaggi di ogni lato',
    () async {
      final relay = FakeRelay();
      final white = await player(Side.white, [relay]);
      await settle();
      for (var i = 0; i < 10; i++) {
        await white.send(bytes('m$i'));
      }
      expect(relay.stored.length, relaySlots);
      final contents = {
        for (final e in relay.stored.values)
          utf8.decode(base64.decode(e.content)),
      };
      expect(contents, containsAll(['m9', 'm8', 'm7', 'm6']));
    },
  );

  test('RMP-31 rimandare lo stesso messaggio non consuma altri slot', () async {
    final relay = FakeRelay();
    final white = await player(Side.white, [relay]);
    await settle();
    await white.send(bytes('a'));
    await white.send(bytes('b'));
    for (var i = 0; i < 10; i++) {
      await white.send(bytes('a'));
    }
    final contents = {
      for (final e in relay.stored.values)
        utf8.decode(base64.decode(e.content)),
    };
    expect(contents, {'a', 'b'});
    expect(
      relay.received
          .where((e) => e.content == base64.encode(bytes('a')))
          .map((e) => e.id)
          .toSet(),
      hasLength(1),
    );
  });

  test('RMP-31 il contenuto sul relay è base64 e non in chiaro', () async {
    final relay = FakeRelay();
    final white = await player(Side.white, [relay]);
    await settle();
    await white.send(bytes('segreto'));
    final e = relay.stored.values.single;
    expect(e.content, base64.encode(bytes('segreto')));
    expect(e.pubkey, (await RelayKeys.derive(gameId, secret)).publicKey);
  });

  test(
    'RMP-31 senza relay raggiungibile l\'invio fallisce e riparte al ritorno',
    () async {
      final relay = FakeRelay()..up = false;
      final white = await player(Side.white, [relay]);
      final black = await player(Side.black, [relay]);
      await settle();
      await expectLater(
        white.send(bytes('in attesa')),
        throwsA(isA<TransportUnavailable>()),
      );
      final connected = white.connected.first;
      final got = black.incoming.first;
      relay.up = true;
      await connected.timeout(const Duration(seconds: 2));
      expect(await got.timeout(const Duration(seconds: 2)), bytes('in attesa'));
    },
  );

  test('RMP-31 se il relay rifiuta l\'evento l\'invio fallisce', () async {
    final relay = FakeRelay()..accepting = false;
    final white = await player(Side.white, [relay]);
    await settle();
    await expectLater(
      white.send(bytes('x')),
      throwsA(isA<TransportUnavailable>()),
    );
  });

  test(
    'RMP-31 senza risposta del relay l\'invio fallisce dopo l\'attesa',
    () async {
      final relay = FakeRelay()..acknowledging = false;
      final white = await player(Side.white, [
        relay,
      ], ackTimeout: const Duration(milliseconds: 100));
      await settle();
      await expectLater(
        white.send(bytes('x')),
        throwsA(isA<TransportUnavailable>()),
      );
    },
  );

  test(
    'RMP-31 basta un relay su due: uno spento non blocca la partita',
    () async {
      final dead = FakeRelay()..up = false;
      final live = FakeRelay();
      final white = await player(Side.white, [dead, live]);
      final black = await player(Side.black, [dead, live]);
      await settle();
      final got = black.incoming.first;
      await white.send(bytes('via live'));
      expect(await got.timeout(const Duration(seconds: 2)), bytes('via live'));
    },
  );

  test(
    'RMP-31 lo stesso messaggio da due relay arriva una sola volta',
    () async {
      final r1 = FakeRelay();
      final r2 = FakeRelay();
      final white = await player(Side.white, [r1, r2]);
      final black = await player(Side.black, [r1, r2]);
      await settle();
      final seen = <Uint8List>[];
      black.incoming.listen(seen.add);
      await white.send(bytes('una'));
      await settle();
      expect(seen, [bytes('una')]);
      expect(r1.stored, hasLength(1));
      expect(r2.stored, hasLength(1));
    },
  );

  test('RMP-31 il relay che cade viene ricontattato da solo', () async {
    final relay = FakeRelay();
    final white = await player(Side.white, [relay]);
    final black = await player(Side.black, [relay]);
    await settle();
    await relay.drop();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(relay.connections, greaterThan(2));
    final got = black.incoming.first;
    await white.send(bytes('dopo la caduta'));
    expect(
      await got.timeout(const Duration(seconds: 2)),
      bytes('dopo la caduta'),
    );
  });

  test(
    'RMP-31 al ritorno di un relay che ha perso tutto si ripubblica',
    () async {
      final relay = FakeRelay();
      final white = await player(Side.white, [relay]);
      await settle();
      await white.send(bytes('ultima'));
      relay.stored.clear();
      await relay.drop();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(relay.stored.values.map((e) => e.content), [
        base64.encode(bytes('ultima')),
      ]);
    },
  );

  test(
    'RMP-31 eventi di altre chiavi, firme false e slot estranei si scartano',
    () async {
      final relay = FakeRelay();
      final black = await player(Side.black, [relay]);
      await settle();
      final seen = <Uint8List>[];
      black.incoming.listen(seen.add);
      final keys = await RelayKeys.derive(gameId, secret);
      final mine = keys.slots(Side.black).first;
      final theirs = keys.slots(Side.white).first;
      final stranger = await RelayKeys.derive(gameId, Uint8List(32));

      final socket = await relay.connect(relayUrl);
      final inject = [
        // Chiave estranea nello slot giusto.
        stranger.sign(slot: theirs, content: base64.encode(bytes('1'))),
        // Slot dell'altro lato (i propri) o inesistente.
        keys.sign(slot: mine, content: base64.encode(bytes('2'))),
        keys.sign(slot: 'ff' * 16, content: base64.encode(bytes('3'))),
        // Contenuto non base64 o troppo lungo.
        keys.sign(slot: theirs, content: '!!!'),
        keys.sign(slot: theirs, content: base64.encode(Uint8List(2000))),
      ];
      for (final e in inject) {
        socket.send(jsonEncode(['EVENT', e.toJson()]));
      }
      await settle();
      expect(seen, isEmpty);
      // Un messaggio buono, dopo, passa.
      final good = keys.sign(slot: theirs, content: base64.encode(bytes('ok')));
      socket.send(jsonEncode(['EVENT', good.toJson()]));
      await settle();
      expect(seen, [bytes('ok')]);
      await socket.close();
    },
  );

  test(
    'RMP-31 un relay che rifiuta la sottoscrizione non conta come collegato',
    () async {
      final refusing = FakeRelay()..refusingSubscriptions = true;
      final live = FakeRelay();
      final white = await player(Side.white, [refusing, live]);
      final black = await player(Side.black, [refusing, live]);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(white.connectedRelays, 1);
      expect(refusing.connections, greaterThan(1));
      final got = black.incoming.first;
      await white.send(bytes('via live'));
      expect(await got.timeout(const Duration(seconds: 2)), bytes('via live'));
    },
  );

  test(
    'RMP-31 il ritardo dei tentativi non riparte se il relay rifiuta',
    () async {
      final relay = FakeRelay()..refusingSubscriptions = true;
      await player(Side.white, [relay]);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      // Con il ritardo che raddoppia fino a 80 ms bastano circa sette
      // tentativi; ripartendo da 20 ms a ogni collegamento sarebbero più di 15.
      expect(relay.connections, lessThan(12));
    },
  );

  test('RMP-31 un collegamento che si rompe subito si riprova', () async {
    final relay = FakeRelay()..breakingSends = true;
    final white = await player(Side.white, [relay]);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(white.connectedRelays, 0);
    expect(relay.connections, greaterThan(1));
    relay.breakingSends = false;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(white.connectedRelays, 1);
  });

  test('RMP-31 solo relay cifrati wss: ws e altro si rifiutano', () async {
    await expectLater(
      NostrTransport.open(
        gameId: gameId,
        secret: secret,
        side: Side.white,
        relays: [Uri.parse('ws://relay.prova')],
        connector: (_) => throw StateError('non deve collegarsi'),
      ),
      throwsArgumentError,
    );
  });

  test('RMP-31 dopo la chiusura l\'invio fallisce', () async {
    final relay = FakeRelay();
    final white = await player(Side.white, [relay]);
    await white.close();
    await expectLater(
      white.send(bytes('x')),
      throwsA(isA<TransportUnavailable>()),
    );
  });

  test('RMP-31 i relay predefiniti sono tutti wss', () {
    expect(defaultRelays, isNotEmpty);
    expect(defaultRelays.every((u) => u.scheme == 'wss'), isTrue);
  });
}
