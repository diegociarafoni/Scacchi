import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/channel_registry.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/lan_discovery.dart';
import 'package:scacchi/multiplayer/lan_transport.dart';
import 'package:scacchi/multiplayer/local_address.dart';
import 'package:scacchi/multiplayer/multiplayer_controller.dart';
import 'package:scacchi/multiplayer/transport.dart';

import '../support/wait.dart';

/// Ospite e invitato collegati in memoria.
Future<(MultiplayerController, MultiplayerController)> pair({
  Side hostSide = Side.white,
}) async {
  final (a, b) = LoopbackTransport.pair();
  final host = await MultiplayerController.host(
    side: hostSide,
    openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
  );
  final invite = GameInvite.parse(host.inviteLink)!;
  final guest = await MultiplayerController.join(
    invite,
    openGuest: (h, p) {
      expect((h, p), ('10.0.0.2', 4000));
      return b;
    },
  );
  await settleLoopback();
  return (host, guest);
}

/// Ricerca finta: registra gli annunci e risponde con l'indirizzo dato.
class FakeDiscovery implements LanDiscovery {
  final adverts = <(String, int)>[];
  int stopped = 0;
  (String, int)? answer;
  final searched = <String>[];

  @override
  Future<void Function()> advertise(String name, int port) async {
    adverts.add((name, port));
    return () => stopped++;
  }

  @override
  Future<(String, int)?> find(String name, {Duration? timeout}) async {
    searched.add(name);
    return answer;
  }
}

/// Canale il cui invio resta sospeso finché non lo si sblocca.
class _GatedTransport implements MessageTransport {
  _GatedTransport(this.inner);

  final LoopbackTransport inner;
  final gate = Completer<void>();

  @override
  String get name => inner.name;
  @override
  Stream<Uint8List> get incoming => inner.incoming;
  @override
  Future<void> send(Uint8List data) async {
    await gate.future;
    return inner.send(data);
  }

  @override
  Future<void> close() => inner.close();
}

void main() {
  test(
    'la mossa aggiorna lo stato prima che l\'invio in rete finisca',
    () async {
      final (a, b) = LoopbackTransport.pair();
      final gated = _GatedTransport(a);
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: () async => (transport: gated, lanAddress: '10.0.0.2:4000'),
      );
      final guest = await MultiplayerController.join(
        GameInvite.parse(host.inviteLink)!,
        openGuest: (h, p) => b,
      );
      await guest.session.announce();
      await settleLoopback();
      var notified = 0;
      host.addListener(() => notified++);
      final playing = host.play(Move.parse('e2e4')!);
      await pumpEventQueue();
      expect(notified, greaterThan(0));
      expect(host.lastMove, Move.parse('e2e4'));
      expect(host.status, MultiplayerStatus.peerTurn);
      gated.gate.complete();
      expect(await playing, isTrue);
      await host.close();
      await guest.close();
    },
  );

  group('indirizzo in rete locale', () {
    (String, InternetAddress) ip(String name, String s) =>
        (name, InternetAddress(s));

    test('RMP-08 sceglie un indirizzo privato IPv4', () {
      expect(
        pickLanAddress([
          ip('lo', '127.0.0.1'),
          ip('eth9', '8.8.8.8'),
          ip('wlan0', '192.168.1.7'),
        ]),
        '192.168.1.7',
      );
      expect(pickLanAddress([ip('ap0', '10.1.2.3')]), '10.1.2.3');
      expect(pickLanAddress([ip('docker0', '172.20.0.5')]), '172.20.0.5');
    });

    test('RMP-08 preferisce la Wi-Fi ai dati mobili e alle VPN', () {
      expect(
        pickLanAddress([
          ip('rmnet_data0', '10.12.34.56'),
          ip('tun0', '10.8.0.2'),
          ip('wlan0', '192.168.1.20'),
        ]),
        '192.168.1.20',
      );
      expect(
        pickLanAddress([ip('docker0', '172.17.0.1'), ip('en0', '10.0.0.4')]),
        '10.0.0.4',
      );
    });

    test('RMP-08 senza rete locale non c\'è indirizzo', () {
      expect(
        pickLanAddress([ip('lo', '127.0.0.1'), ip('eth0', '172.32.0.1')]),
        isNull,
      );
      // Solo dati mobili: l'altro telefono non lo raggiunge.
      expect(pickLanAddress([ip('rmnet0', '10.12.34.56')]), isNull);
      expect(pickLanAddress(const []), isNull);
    });
  });

  test('RMP-08 l\'ospite attende, poi si gioca a turno', () async {
    final (a, b) = LoopbackTransport.pair();
    final host = await MultiplayerController.host(
      side: Side.white,
      openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
    );
    expect(host.status, MultiplayerStatus.waitingPeer);
    expect(host.mySide, Side.white);
    final invite = GameInvite.parse(host.inviteLink)!;
    expect(invite.lanAddress, '10.0.0.2:4000');
    final guest = await MultiplayerController.join(
      invite,
      openGuest: (_, _) => b,
    );
    await settleLoopback();
    expect(guest.mySide, Side.black);
    expect(host.status, MultiplayerStatus.myTurn);
    expect(guest.status, MultiplayerStatus.peerTurn);
    await host.play(Move.parse('e2e4')!);
    await settleLoopback();
    expect(guest.status, MultiplayerStatus.myTurn);
    expect(guest.lastMove, Move.parse('e2e4'));
    expect(guest.lastSan, 'e4');
    await host.close();
    await guest.close();
  });

  test('RMP-08 l\'ospite può scegliere il Nero', () async {
    final (host, guest) = await pair(hostSide: Side.black);
    expect(host.mySide, Side.black);
    expect(guest.mySide, Side.white);
    expect(guest.status, MultiplayerStatus.myTurn);
    await host.close();
    await guest.close();
  });

  test('RMP-08 fuori turno la mossa viene ignorata', () async {
    final (host, guest) = await pair();
    expect(await guest.play(Move.parse('e7e5')!), isFalse);
    expect(guest.position, Chess.initial);
    await host.close();
    await guest.close();
  });

  test('RMP-08 matto: la partita finisce per entrambi', () async {
    final (host, guest) = await pair();
    for (final (side, uci) in [
      (host, 'f2f3'),
      (guest, 'e7e5'),
      (host, 'g2g4'),
      (guest, 'd8h4'),
    ]) {
      expect(await side.play(Move.parse(uci)!), isTrue);
      await settleLoopback();
    }
    expect(host.status, MultiplayerStatus.finished);
    expect(guest.status, MultiplayerStatus.finished);
    expect(host.outcome, Outcome.blackWins);
    await host.close();
    await guest.close();
  });

  test('RMP-08 l\'invitato riprova finché l\'ospite non risponde', () async {
    final (a, b) = LoopbackTransport.pair();
    final host = await MultiplayerController.host(
      side: Side.white,
      openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
    );
    final down = _Unavailable(b);
    final guest = await MultiplayerController.join(
      GameInvite.parse(host.inviteLink)!,
      openGuest: (_, _) => down,
    );
    await settleLoopback();
    expect(guest.status, MultiplayerStatus.connecting);
    // Il canale riprova da solo e avvisa quando si collega.
    await down.comeUp();
    await until(
      () => guest.status == MultiplayerStatus.peerTurn,
      what: 'canale ricollegato',
    );
    expect(guest.status, MultiplayerStatus.peerTurn);
    expect(host.status, MultiplayerStatus.myTurn);
    await host.close();
    await guest.close();
  });

  test('RMP-08 un invito senza indirizzo locale non si può usare', () async {
    final (a, _) = LoopbackTransport.pair();
    final host = await MultiplayerController.host(
      side: Side.white,
      openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
    );
    final invite = GameInvite.parse(host.inviteLink)!;
    final noLan = GameInvite(
      gameId: invite.gameId,
      secret: invite.secret,
      hostKey: invite.hostKey,
      hostSide: invite.hostSide,
    );
    await expectLater(
      MultiplayerController.join(noLan, openGuest: (_, _) => a),
      throwsA(isA<NoLocalNetwork>()),
    );
    await host.close();
  });

  test('RMP-08 l\'ospite senza Wi-Fi riceve un errore chiaro', () async {
    final (a, _) = LoopbackTransport.pair();
    await expectLater(
      MultiplayerController.host(
        side: Side.white,
        openHost: () async => (transport: a, lanAddress: null),
      ),
      throwsA(isA<NoLocalNetwork>()),
    );
  });

  group('ricerca in rete locale', () {
    test(
      'RMP-10 l\'ospite annuncia la partita e smette alla chiusura',
      () async {
        final (a, _) = LoopbackTransport.pair();
        final discovery = FakeDiscovery();
        final host = await MultiplayerController.host(
          side: Side.white,
          openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
          discovery: discovery,
        );
        await settleLoopback();
        final id = GameInvite.parse(host.inviteLink)!.gameId;
        expect(discovery.adverts, [(lanServiceName(id), 4000)]);
        await host.close();
        expect(discovery.stopped, 1);
      },
    );

    test('RMP-10 un annuncio che fallisce non ferma la partita', () async {
      final (a, _) = LoopbackTransport.pair();
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
        discovery: _BrokenDiscovery(),
      );
      await settleLoopback();
      expect(host.status, MultiplayerStatus.waitingPeer);
      await host.close();
    });

    test('RMP-10 l\'invitato cerca la partita per nome', () async {
      final (a, b) = LoopbackTransport.pair();
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
      );
      final invite = GameInvite.parse(host.inviteLink)!;
      final discovery = FakeDiscovery()..answer = ('10.0.0.9', 4100);
      final lan = LanTransport.connect('127.0.0.1', 1);
      final guest = await MultiplayerController.join(
        invite,
        openGuest: (_, _) => lan,
        discovery: discovery,
      );
      expect(await lan.finder!(), ('10.0.0.9', 4100));
      expect(discovery.searched, [lanServiceName(invite.gameId)]);
      await guest.close();
      await host.close();
      await b.close();
    });
  });

  group('canali in più', () {
    tearDown(extraChannelFactories.clear);

    test('RMP-11 i canali registrati si aggiungono a ogni partita', () async {
      final (extraA, extraB) = LoopbackTransport.pair(name: 'extra');
      final seen = <(String, bool)>[];
      extraChannelFactories
        ..add((invite, {required isHost}) async {
          seen.add((invite.gameId, isHost));
          return isHost ? extraA : extraB;
        })
        ..add((invite, {required isHost}) async => null)
        ..add((invite, {required isHost}) async => throw StateError('no'));
      // Il Wi-Fi è giù: la partita viaggia solo sul canale in più.
      final (lanA, lanB) = LoopbackTransport.pair();
      lanA.online = false;
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: () async => (transport: lanA, lanAddress: '10.0.0.2:4000'),
      );
      final guest = await MultiplayerController.join(
        GameInvite.parse(host.inviteLink)!,
        openGuest: (_, _) => lanB,
      );
      await settleLoopback();
      expect(seen.map((e) => e.$2), [true, false]);
      expect(host.session.transport.name, 'loop+extra');
      expect(await host.play(Move.parse('e2e4')!), isTrue);
      await settleLoopback();
      expect(guest.session.sync.moves, ['e2e4']);
      await host.close();
      await guest.close();
    });
  });
}

/// Canale che rifiuta gli invii finché non si collega con [comeUp].
class _Unavailable implements MessageTransport, ConnectionAware {
  _Unavailable(this._inner);
  final MessageTransport _inner;
  final _connected = StreamController<void>.broadcast();
  bool up = false;

  Future<void> comeUp() async {
    up = true;
    _connected.add(null);
  }

  @override
  Stream<void> get connected => _connected.stream;

  @override
  String get name => 'giù';

  @override
  Stream<Uint8List> get incoming => _inner.incoming;

  @override
  Future<void> send(Uint8List data) async {
    if (!up) throw TransportUnavailable(name);
    await _inner.send(data);
  }

  @override
  Future<void> close() => _inner.close();
}

class _BrokenDiscovery implements LanDiscovery {
  @override
  Future<void Function()> advertise(String name, int port) async =>
      throw StateError('niente mDNS');

  @override
  Future<(String, int)?> find(String name, {Duration? timeout}) async =>
      throw StateError('niente mDNS');
}
