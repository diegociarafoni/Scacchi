import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/channel_registry.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/multiplayer_controller.dart';
import 'package:scacchi/multiplayer/nostr_transport.dart';
import 'package:scacchi/multiplayer/remote_watch.dart';
import 'package:scacchi/multiplayer/saved_game.dart';
import 'package:scacchi/multiplayer/transport.dart';

import 'fake_relay.dart';

Future<void> settle([int ms = 120]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

/// Canale a distanza sul relay finto, con attese brevi.
ChannelFactory remoteOn(FakeRelay relay, List<NostrTransport> opened) =>
    (invite, {required isHost}) async {
      if (!invite.remote) return null;
      final t = await NostrTransport.open(
        gameId: invite.gameId,
        secret: invite.secret,
        side: isHost ? invite.hostSide : invite.hostSide.opposite,
        relays: [Uri.parse('wss://relay.prova')],
        connector: relay.connect,
        minBackoff: const Duration(milliseconds: 20),
        maxBackoff: const Duration(milliseconds: 80),
      );
      opened.add(t);
      return t;
    };

class _Watch implements RemoteWatch {
  final calls = <String>[];

  @override
  Future<void> enable() async => calls.add('on');

  @override
  Future<void> disable() async => calls.add('off');
}

Future<HostChannel> noWifi() async => throw const NoLocalNetwork();

void main() {
  late Directory dir;
  late FakeRelay relay;
  final opened = <NostrTransport>[];

  setUp(() {
    dir = Directory.systemTemp.createTempSync('rokko_remote');
    relay = FakeRelay();
    extraChannelFactories
      ..clear()
      ..add(remoteOn(relay, opened));
  });

  tearDown(() async {
    extraChannelFactories.clear();
    for (final t in opened) {
      await t.close();
    }
    opened.clear();
    dir.deleteSync(recursive: true);
  });

  SavedGameStore store() => SavedGameStore(File('${dir.path}/m.json'));

  test('RMP-32 senza Wi-Fi si può creare una partita a distanza', () async {
    final host = await MultiplayerController.host(
      side: Side.white,
      openHost: noWifi,
      remote: true,
    );
    final invite = GameInvite.parse(host.inviteLink)!;
    expect(invite.remote, isTrue);
    expect(invite.lanAddress, isNull);
    expect(host.status, MultiplayerStatus.waitingPeer);
    await host.close();
  });

  test('RMP-32 senza Wi-Fi e senza distanza la creazione fallisce', () async {
    await expectLater(
      MultiplayerController.host(side: Side.white, openHost: noWifi),
      throwsA(isA<NoLocalNetwork>()),
    );
  });

  test(
    'RMP-32 con la Wi-Fi l\'invito porta anche l\'indirizzo locale',
    () async {
      final (a, _) = LoopbackTransport.pair();
      final host = await MultiplayerController.host(
        side: Side.black,
        openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
        remote: true,
      );
      final invite = GameInvite.parse(host.inviteLink)!;
      expect(invite.lanAddress, '10.0.0.2:4000');
      expect(invite.remote, isTrue);
      await host.close();
    },
  );

  test('RMP-32 due telefoni lontani giocano solo tramite il relay', () async {
    final host = await MultiplayerController.host(
      side: Side.white,
      openHost: noWifi,
      remote: true,
    );
    final guest = await MultiplayerController.join(
      GameInvite.parse(host.inviteLink)!,
      openGuest: (_, _) => throw StateError('niente rete locale'),
    );
    await settle();
    expect(host.status, MultiplayerStatus.myTurn);
    expect(await host.play(Move.parse('e2e4')!), isTrue);
    await settle();
    expect(guest.status, MultiplayerStatus.myTurn);
    expect(await guest.play(Move.parse('e7e5')!), isTrue);
    await settle();
    expect(host.session.sync.moves, ['e2e4', 'e7e5']);
    expect(guest.session.sync.moves, ['e2e4', 'e7e5']);
    await host.close();
    await guest.close();
  });

  test('RMP-32 senza distanza e senza indirizzo non ci si può unire', () async {
    final host = await MultiplayerController.host(
      side: Side.white,
      openHost: noWifi,
      remote: true,
    );
    final local = GameInvite(
      gameId: newGameId(),
      secret: newSecret(),
      hostKey: GameInvite.parse(host.inviteLink)!.hostKey,
      hostSide: Side.white,
    );
    await expectLater(
      MultiplayerController.join(local),
      throwsA(isA<NoLocalNetwork>()),
    );
    await host.close();
  });

  test(
    'RMP-32 l\'invito a distanza si salva subito, anche senza avversario',
    () async {
      final s = store();
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: noWifi,
        remote: true,
        store: s,
      );
      await settle();
      final saved = await s.load();
      expect(saved, isNotNull);
      expect(saved!.isHost, isTrue);
      expect(saved.invite.remote, isTrue);
      await host.close();
    },
  );

  test('RMP-32 in rete locale l\'invito in attesa non si salva', () async {
    final s = store();
    final (a, _) = LoopbackTransport.pair();
    final host = await MultiplayerController.host(
      side: Side.white,
      openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
      store: s,
    );
    await settle();
    expect(await s.load(), isNull);
    await host.close();
  });

  test(
    'RMP-32 chi ospita riprende senza Wi-Fi e l\'amico arriva dopo ore',
    () async {
      final s = store();
      final first = await MultiplayerController.host(
        side: Side.white,
        openHost: noWifi,
        remote: true,
        store: s,
      );
      final link = first.inviteLink;
      await settle();
      await first.close();
      // L'app viene richiusa e riaperta: la partita è sul disco.
      final resumed = await MultiplayerController.resume(
        (await s.load())!,
        openHost: (_) => throw const NoLocalNetwork(),
        store: s,
      );
      expect(resumed.inviteLink, link);
      final guest = await MultiplayerController.join(GameInvite.parse(link)!);
      await settle();
      expect(resumed.session.sync.peerKey, isNotNull);
      expect(await resumed.play(Move.parse('d2d4')!), isTrue);
      await settle();
      expect(guest.session.sync.moves, ['d2d4']);
      await resumed.close();
      await guest.close();
    },
  );

  test(
    'RMP-33 l\'invitato riprende e trova la mossa lasciata sul relay',
    () async {
      final s = store();
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: noWifi,
        remote: true,
      );
      final guest = await MultiplayerController.join(
        GameInvite.parse(host.inviteLink)!,
        store: s,
      );
      await settle();
      await host.play(Move.parse('e2e4')!);
      await settle();
      await guest.play(Move.parse('e7e5')!);
      await settle();
      await guest.close();
      // L'ospite muove mentre l'invitato è fuori.
      await host.play(Move.parse('g1f3')!);
      await settle();
      final back = await MultiplayerController.resume(
        (await s.load())!,
        store: s,
      );
      await settle();
      expect(back.session.sync.moves, ['e2e4', 'e7e5', 'g1f3']);
      expect(back.status, MultiplayerStatus.myTurn);
      await host.close();
      await back.close();
    },
  );

  test(
    'RMP-41 una partita a distanza accende il controllo in background',
    () async {
      final watch = _Watch();
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: noWifi,
        remote: true,
      );
      host.useWatch(watch);
      expect(watch.calls, ['on']);
      // Un cambiamento non lo riaccende.
      final guest = await MultiplayerController.join(
        GameInvite.parse(host.inviteLink)!,
      );
      await settle();
      await host.play(Move.parse('e2e4')!);
      expect(watch.calls, ['on']);
      await host.close();
      await guest.close();
    },
  );

  test(
    'RMP-41 a partita finita il controllo in background si spegne',
    () async {
      final watch = _Watch();
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: noWifi,
        remote: true,
      );
      host.useWatch(watch);
      final guest = await MultiplayerController.join(
        GameInvite.parse(host.inviteLink)!,
      );
      await settle();
      for (final (c, uci) in [
        (host, 'f2f3'),
        (guest, 'e7e5'),
        (host, 'g2g4'),
        (guest, 'd8h4'),
      ]) {
        expect(await c.play(Move.parse(uci)!), isTrue);
        await settle(60);
      }
      expect(host.status, MultiplayerStatus.finished);
      expect(watch.calls, ['on', 'off']);
      await host.close();
      await guest.close();
    },
  );

  test('RMP-41 una partita in rete locale non accende nulla', () async {
    final watch = _Watch();
    final (a, _) = LoopbackTransport.pair();
    final host = await MultiplayerController.host(
      side: Side.white,
      openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
    );
    host.useWatch(watch);
    expect(watch.calls, isEmpty);
    await host.close();
  });

  test(
    'RMP-32 un errore della rete locale non ferma la partita a distanza',
    () async {
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: () async => throw const SocketException('porta occupata'),
        remote: true,
      );
      expect(GameInvite.parse(host.inviteLink)!.lanAddress, isNull);
      await host.close();
      await expectLater(
        MultiplayerController.host(
          side: Side.white,
          openHost: () async => throw const SocketException('porta occupata'),
        ),
        throwsA(isA<SocketException>()),
      );
    },
  );
}
