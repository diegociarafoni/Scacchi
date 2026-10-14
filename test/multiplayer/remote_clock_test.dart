import 'dart:io';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/clock.dart';
import 'package:scacchi/multiplayer/channel_registry.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/game_message.dart';
import 'package:scacchi/multiplayer/multiplayer_controller.dart';
import 'package:scacchi/multiplayer/saved_game.dart';
import 'package:scacchi/multiplayer/transport.dart';

import '../support/wait.dart';

/// A-26: orologio nelle partite a distanza, in due modi che sceglie chi crea
/// la partita: lampo con orologio dal vivo e lenta con tempo per mossa.

const blitz = TimeControl(minutes: 3, increment: 2);

final _hostKey = Uint8List.fromList(List.filled(32, 1));

/// Orologio di parete che avanza solo quando lo si dice.
class _Now {
  DateTime value = DateTime.utc(2026, 10, 14, 9);
  DateTime call() => value;
  void advance(Duration d) => value = value.add(d);
}

GameInvite _invite({TimeControl? control, int? moveDays, bool remote = true}) =>
    GameInvite(
      gameId: newGameId(),
      secret: newSecret(),
      hostKey: _hostKey,
      hostSide: Side.white,
      timeControl: control,
      moveDays: moveDays,
      remote: remote,
    );

Future<(MultiplayerController, MultiplayerController)> _pair(
  _Now hostNow, {
  int? moveDays,
  TimeControl? control,
  _Now? guestNow,
  SavedGameStore? store,
}) async {
  final (a, b) = LoopbackTransport.pair();
  final host = await MultiplayerController.host(
    side: Side.white,
    remote: true,
    timeControl: control,
    moveDays: moveDays,
    now: hostNow.call,
    store: store,
    openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
  );
  final guest = await MultiplayerController.join(
    GameInvite.parse(host.inviteLink)!,
    now: (guestNow ?? hostNow).call,
    openGuest: (_, _) => b,
  );
  await settleLoopback();
  return (host, guest);
}

Future<void> _play(MultiplayerController c, String uci) async {
  expect(await c.play(Move.parse(uci)!), isTrue);
  await settleLoopback();
}

void main() {
  setUp(extraChannelFactories.clear);

  group('invito', () {
    test('il lampo a distanza porta la cadenza e si rilegge', () {
      final back = GameInvite.parse(_invite(control: blitz).toLink())!;
      expect(back.remote, isTrue);
      expect(back.timeControl, blitz);
      expect(back.moveDays, isNull);
    });

    test('la partita lenta porta i giorni per mossa e si rilegge', () {
      for (final days in [1, 3, 7]) {
        final back = GameInvite.parse(_invite(moveDays: days).toLink())!;
        expect(back.moveDays, days);
        expect(back.timeControl, isNull);
      }
    });

    test('giorni per mossa fuori scelta rendono nullo l\'invito', () {
      final base = _invite().toLink();
      for (final dm in ['0', '2', '8', '30', '-1', 'x', '']) {
        expect(GameInvite.parse('$base&dm=$dm'), isNull, reason: dm);
      }
    });

    test('i giorni per mossa valgono solo a distanza e senza cadenza', () {
      expect(
        GameInvite.parse('${_invite(remote: false).toLink()}&dm=3'),
        isNull,
      );
      expect(
        GameInvite.parse('${_invite(control: blitz).toLink()}&dm=3'),
        isNull,
      );
    });

    test('senza scelta la partita a distanza resta senza orologio', () {
      final back = GameInvite.parse(_invite().toLink())!;
      expect(back.timeControl, isNull);
      expect(back.moveDays, isNull);
    });
  });

  group('messaggio di reclamo', () {
    test('si rilegge e scarta i numeri non credibili', () {
      const m = ClaimMessage(plies: 4);
      expect(GameMessage.fromJson(m.toJson()), m);
      expect(GameMessage.fromJson({'t': 'claim', 'n': 0}), isNull);
      expect(GameMessage.fromJson({'t': 'claim', 'n': 99999}), isNull);
    });
  });

  group('lampo a distanza', () {
    test('la cadenza resta nell\'invito e c\'è l\'orologio', () async {
      final now = _Now();
      final (host, guest) = await _pair(now, control: blitz);
      expect(host.timeControl, blitz);
      expect(host.clock, isNotNull);
      expect(guest.clock, isNotNull);
      expect(host.moveDays, isNull);
      await host.close();
      await guest.close();
    });
  });

  group('partita lenta', () {
    test('il tempo parte con la prima mossa e dura i giorni scelti', () async {
      final now = _Now();
      final (host, guest) = await _pair(now, moveDays: 3);
      expect(host.clock, isNull);
      expect(host.moveDays, 3);
      expect(host.moveDeadline, isNull);
      await _play(host, 'e2e4');
      final deadline = now.value.add(const Duration(days: 3));
      expect(host.moveDeadline, deadline);
      expect(guest.moveDeadline, deadline);
      await host.close();
      await guest.close();
    });

    test('si reclama solo dopo la scadenza e solo l\'avversario', () async {
      final now = _Now();
      final (host, guest) = await _pair(now, moveDays: 1);
      await _play(host, 'e2e4');
      expect(host.canClaimTimeout, isFalse);
      now.advance(const Duration(hours: 23));
      expect(host.canClaimTimeout, isFalse);
      now.advance(const Duration(hours: 2));
      expect(host.canClaimTimeout, isTrue);
      // Chi è di turno non può reclamare: può ancora muovere.
      expect(guest.canClaimTimeout, isFalse);
      await _play(guest, 'e7e5');
      expect(host.canClaimTimeout, isFalse);
      await host.close();
      await guest.close();
    });

    test('il reclamo finisce la partita su entrambi i telefoni', () async {
      final now = _Now();
      final (host, guest) = await _pair(now, moveDays: 1);
      await _play(host, 'e2e4');
      now.advance(const Duration(days: 1, hours: 1));
      expect(await host.claimTimeout(), isTrue);
      await settleLoopback();
      for (final c in [host, guest]) {
        expect(c.status, MultiplayerStatus.finished);
        expect(c.endedOnTime, isTrue);
        expect(c.outcome?.winner, Side.white);
      }
      await host.close();
      await guest.close();
    });

    test('un reclamo prima del tempo non si può fare', () async {
      final now = _Now();
      final (host, guest) = await _pair(now, moveDays: 3);
      await _play(host, 'e2e4');
      now.advance(const Duration(days: 1));
      expect(await host.claimTimeout(), isFalse);
      expect(host.status, MultiplayerStatus.peerTurn);
      await host.close();
      await guest.close();
    });

    test('chi riceve un reclamo troppo presto lo ignora', () async {
      final hostNow = _Now();
      final guestNow = _Now();
      final (host, guest) = await _pair(
        hostNow,
        moveDays: 1,
        guestNow: guestNow,
      );
      await _play(host, 'e2e4');
      // L'orologio dell'ospite è molto in avanti: il reclamo parte, ma
      // l'invitato, per il quale è passato un giorno solo a metà, non lo
      // accetta.
      hostNow.advance(const Duration(days: 2));
      guestNow.advance(const Duration(hours: 12));
      expect(await host.claimTimeout(), isTrue);
      await settleLoopback();
      expect(guest.status, MultiplayerStatus.myTurn);
      await host.close();
      await guest.close();
    });

    test(
      'un ritardo di poco tra i due telefoni non impedisce il reclamo',
      () async {
        final hostNow = _Now();
        final guestNow = _Now();
        final (host, guest) = await _pair(
          hostNow,
          moveDays: 1,
          guestNow: guestNow,
        );
        await _play(host, 'e2e4');
        // La mossa è arrivata all'invitato con un'ora di ritardo.
        guestNow.advance(const Duration(hours: 1));
        hostNow.advance(const Duration(days: 1, minutes: 1));
        guestNow.advance(const Duration(days: 1));
        expect(await host.claimTimeout(), isTrue);
        await settleLoopback();
        expect(guest.status, MultiplayerStatus.finished);
        await host.close();
        await guest.close();
      },
    );

    test('la scadenza si salva e si ritrova alla ripresa', () async {
      final dir = Directory.systemTemp.createTempSync('rokko_slow');
      addTearDown(() => removeDir(dir));
      final store = SavedGameStore(File('${dir.path}/m.json'));
      final now = _Now();
      final (host, guest) = await _pair(now, moveDays: 7, store: store);
      await _play(host, 'e2e4');
      await untilSaved(store, 1);
      final saved = (await store.load())!;
      expect(saved.invite.moveDays, 7);
      expect(saved.turnStartedAt, now.value.millisecondsSinceEpoch);
      await host.close();
      await guest.close();
    });
  });
}
