import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/exchange/qr_code_view.dart';
import 'package:scacchi/multiplayer/channel_registry.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/multiplayer_controller.dart';
import 'package:scacchi/multiplayer/multiplayer_page.dart';
import 'package:scacchi/multiplayer/remote_watch.dart';
import 'package:scacchi/multiplayer/saved_game.dart';
import 'package:scacchi/multiplayer/transport.dart';

import '../localized_app.dart';

class _Watch implements RemoteWatch {
  final calls = <String>[];

  @override
  Future<void> enable() async => calls.add('on');

  @override
  Future<void> disable() async => calls.add('off');
}

Future<void> _wait(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

Future<HostChannel> _noWifi() async => throw const NoLocalNetwork();

/// Registra un canale a distanza in memoria: [host] per chi crea, [guest]
/// per chi si unisce.
void _registerRemote({MessageTransport? host, MessageTransport? guest}) {
  extraChannelFactories
    ..clear()
    ..add((invite, {required isHost}) async => isHost ? host : guest);
}

void main() {
  tearDown(extraChannelFactories.clear);

  testWidgets('RMP-32 senza Wi-Fi il QR e il link si creano a distanza', (
    tester,
  ) async {
    final (remote, _) = LoopbackTransport.pair();
    _registerRemote(host: remote);
    final shared = <String>[];
    await tester.pumpWidget(
      localizedApp(
        home: MultiplayerPage(
          openHost: _noWifi,
          shareInvite: (subject, text) async => shared.add(text),
        ),
      ),
    );
    expect(find.text('Gioca anche a distanza'), findsOneWidget);
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
    expect(invite.remote, isTrue);
    expect(invite.lanAddress, isNull);

    await tester.scrollUntilVisible(
      find.text('Condividi il link d\'invito'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Condividi il link d\'invito'));
    await tester.pump();
    expect(shared.single, contains(view.data));
    expect(shared.single, contains('Unisciti con il link'));
  });

  testWidgets('RMP-32 con l\'interruttore spento serve la rete locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(home: const MultiplayerPage(openHost: _noWifi)),
    );
    await tester.ensureVisible(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Crea la partita'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Crea la partita'));
    await tester.pump();
    await tester.tap(find.text('Crea la partita'));
    await _wait(tester);
    expect(find.byType(QrCodeView), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets(
    'RMP-32 il link incollato in un messaggio fa entrare in partita',
    (tester) async {
      final (hostSide, guestSide) = LoopbackTransport.pair();
      _registerRemote(host: hostSide, guest: guestSide);
      final host = (await tester.runAsync(
        () => MultiplayerController.host(
          side: Side.white,
          openHost: _noWifi,
          remote: true,
        ),
      ))!;
      final message = 'Giochiamo! Ecco il link: ${host.inviteLink} a dopo';
      await tester.pumpWidget(
        localizedApp(
          home: MultiplayerPage(
            openGuest: (_, _) => throw StateError('niente rete locale'),
            readClipboard: () async => message,
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Unisciti con il link'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Unisciti con il link'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Incolla'));
      await tester.pump();
      await tester.tap(find.text('Unisciti'));
      await _wait(tester);
      await tester.pumpAndSettle();
      expect(find.byType(Chessboard), findsOneWidget);
      await tester.runAsync(host.close);
    },
  );

  testWidgets('RMP-32 un testo che non è un invito si rifiuta', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: MultiplayerPage(readClipboard: () async => 'ciao a tutti'),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Unisciti con il link'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Unisciti con il link'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Incolla'));
    await tester.pump();
    await tester.tap(find.text('Unisciti'));
    await tester.pump();
    expect(
      find.text('Questo link non è un invito a una partita.'),
      findsOneWidget,
    );
    expect(find.byType(Chessboard), findsNothing);
  });

  testWidgets('RMP-32 uscire in attesa a distanza avvisa che resta salvata', (
    tester,
  ) async {
    final (remote, _) = LoopbackTransport.pair();
    _registerRemote(host: remote);
    await tester.pumpWidget(
      localizedApp(home: const MultiplayerPage(openHost: _noWifi)),
    );
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
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('il link vale ancora'), findsOneWidget);
  });

  testWidgets('RMP-41 eliminare la partita a distanza spegne il controllo', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('rokko_remote_page');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = SavedGameStore(File('${dir.path}/m.json'));
    final (remote, _) = LoopbackTransport.pair();
    _registerRemote(host: remote);
    await tester.runAsync(() async {
      final host = await MultiplayerController.host(
        side: Side.white,
        openHost: _noWifi,
        remote: true,
        store: store,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await host.close();
    });
    final watch = _Watch();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        localizedApp(
          home: MultiplayerPage(store: store, remoteWatch: watch),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina').last);
    await _wait(tester);
    expect(watch.calls, ['off']);
    expect(find.text('Riprendi la partita'), findsNothing);
  });
}
