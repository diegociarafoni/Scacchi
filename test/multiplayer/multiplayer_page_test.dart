import 'dart:io' show Directory, File, SocketException;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/exchange/qr_code_view.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/multiplayer_controller.dart';
import 'package:scacchi/multiplayer/multiplayer_page.dart';
import 'package:scacchi/multiplayer/multiplayer_widgets.dart';
import 'package:scacchi/multiplayer/saved_game.dart';
import 'package:scacchi/multiplayer/transport.dart';

import '../localized_app.dart';

/// Lettore finto: espone la callback che il lettore vero chiamerebbe.
class _FakeScanner {
  ValueChanged<String>? onCode;

  Widget build(
    BuildContext context, {
    required ValueChanged<String> onCode,
    required ValueChanged<Object> onError,
  }) {
    this.onCode = onCode;
    return const SizedBox(key: Key('fakeScanner'), width: 200, height: 200);
  }
}

Future<void> _wait(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

/// Attende (in tempo reale) che [finder] compaia: i salvataggi, le chiavi e i
/// canali hanno tempi che su un runner carico superano un'attesa fissa.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('RMP-08 chi crea la partita mostra il QR, poi la scacchiera', (
    tester,
  ) async {
    final (a, b) = LoopbackTransport.pair();
    await tester.pumpWidget(
      localizedApp(
        home: MultiplayerPage(
          remoteByDefault: false,
          openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
        ),
      ),
    );
    await tester.tap(find.text('Nero'));
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
    await tester.pumpAndSettle();
    expect(find.byType(QrCodeView), findsOneWidget);
    expect(find.text('In attesa dell\'avversario…'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Codice QR dell\'invito alla partita'),
      findsOneWidget,
    );

    // L'altro telefono inquadra l'invito.
    final view = tester.widget<QrCodeView>(find.byType(QrCodeView));
    final invite = GameInvite.parse(view.data)!;
    expect(invite.hostSide, Side.black);
    final guest = (await tester.runAsync(
      () => MultiplayerController.join(invite, openGuest: (_, _) => b),
    ))!;
    await _wait(tester);
    expect(find.byType(QrCodeView), findsNothing);
    expect(find.byType(Chessboard), findsOneWidget);
    expect(find.text('Tocca all\'avversario'), findsOneWidget);

    await tester.runAsync(() => guest.play(Move.parse('e2e4')!));
    await _wait(tester);
    expect(find.text('Tocca a te'), findsOneWidget);
    await tester.runAsync(guest.close);
  });

  testWidgets('RMP-08 senza Wi-Fi compare un avviso', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: MultiplayerPage(
          remoteByDefault: false,
          openHost: () async => throw const NoLocalNetwork(),
        ),
      ),
    );
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
    expect(find.textContaining('Collegati a una Wi-Fi'), findsOneWidget);
  });

  testWidgets('RMP-08 un errore all\'avvio compare come avviso', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        home: MultiplayerPage(
          remoteByDefault: false,
          openHost: () async => throw const SocketException('porta occupata'),
        ),
      ),
    );
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
    expect(
      find.textContaining('Non è stato possibile avviare'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('RMP-08 chi si unisce inquadra l\'invito; un QR estraneo no', (
    tester,
  ) async {
    final (a, b) = LoopbackTransport.pair();
    final host = (await tester.runAsync(
      () => MultiplayerController.host(
        side: Side.white,
        openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
      ),
    ))!;
    final scanner = _FakeScanner();
    await tester.pumpWidget(
      localizedApp(
        home: MultiplayerPage(
          remoteByDefault: false,
          scanner: scanner.build,
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
    expect(find.byKey(const Key('fakeScanner')), findsOneWidget);
    scanner.onCode!('https://example.com');
    await tester.pump();
    expect(
      find.text('Questo QR non è un invito a una partita.'),
      findsOneWidget,
    );
    scanner.onCode!(host.inviteLink);
    await _wait(tester);
    await _wait(tester);
    await tester.pumpAndSettle();
    expect(find.byType(Chessboard), findsOneWidget);
    expect(find.text('Tocca all\'avversario'), findsOneWidget);

    // Uscire chiede conferma.
    final back = MaterialLocalizations.of(
      tester.element(find.byType(Chessboard)),
    ).backButtonTooltip;
    await tester.tap(find.byTooltip(back));
    await tester.pumpAndSettle();
    expect(find.text('Lasciare la partita?'), findsOneWidget);
    await tester.tap(find.text('Lascia'));
    await tester.pumpAndSettle();
    expect(find.text('Crea la partita'), findsOneWidget);
    await tester.runAsync(host.close);
  });

  group('partita da riprendere', () {
    late Directory dir;
    late SavedGameStore store;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('rokko_resume_page');
      store = SavedGameStore(File('${dir.path}/multiplayer.json'));
    });
    tearDown(() => dir.deleteSync(recursive: true));

    Future<void> saveOne(WidgetTester tester) async {
      final (a, b) = LoopbackTransport.pair();
      await tester.runAsync(() async {
        final host = await MultiplayerController.host(
          side: Side.white,
          openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
          store: store,
        );
        final guest = await MultiplayerController.join(
          GameInvite.parse(host.inviteLink)!,
          openGuest: (_, _) => b,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await host.play(Move.parse('e2e4')!);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // Il salvataggio è in coda: si aspetta che la mossa sia sul disco.
        for (var i = 0; i < 100; i++) {
          if (((await store.load())?.moves ?? []).isNotEmpty) break;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        await host.close();
        await guest.close();
      });
    }

    // La lettura del file avanza solo nella zona reale.
    Future<void> openPage(
      WidgetTester tester,
      MultiplayerPage page, {
      bool saved = true,
    }) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(localizedApp(home: page));
        // Con una partita salvata si attende che il riquadro compaia.
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (!saved || find.byType(Card).evaluate().isNotEmpty) break;
        }
      });
      await tester.pump();
    }

    testWidgets('RMP-09 senza partite salvate non c\'è il riquadro', (
      tester,
    ) async {
      await openPage(
        tester,
        MultiplayerPage(remoteByDefault: false, store: store),
        saved: false,
      );
      expect(find.text('Riprendi la partita'), findsNothing);
    });

    testWidgets('RMP-09 la partita salvata si riprende dalla scacchiera', (
      tester,
    ) async {
      await saveOne(tester);
      final (a, _) = LoopbackTransport.pair();
      await openPage(
        tester,
        MultiplayerPage(
          remoteByDefault: false,
          store: store,
          openResumeHost: (_) async =>
              (transport: a, lanAddress: '10.0.0.2:4000'),
        ),
      );
      expect(find.text('Riprendi la partita'), findsOneWidget);
      await tester.tap(find.text('Riprendi la partita'));
      await _waitFor(tester, find.byType(Chessboard));
      await tester.pumpAndSettle();
      expect(find.byType(Chessboard), findsOneWidget);
      expect(find.text('Tocca all\'avversario'), findsOneWidget);
    });

    testWidgets('RMP-09 si può eliminare la partita salvata', (tester) async {
      await saveOne(tester);
      await openPage(
        tester,
        MultiplayerPage(remoteByDefault: false, store: store),
      );
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina').last);
      await _wait(tester);
      await tester.pumpAndSettle();
      expect(find.text('Riprendi la partita'), findsNothing);
      expect(await tester.runAsync(store.load), isNull);
    });

    testWidgets(
      'RMP-09 una partita nuova chiede prima di sostituire quella salvata',
      (tester) async {
        await saveOne(tester);
        var opened = 0;
        final (a, _) = LoopbackTransport.pair();
        await openPage(
          tester,
          MultiplayerPage(
            remoteByDefault: false,
            store: store,
            openHost: () async {
              opened++;
              return (transport: a, lanAddress: '10.0.0.2:4000');
            },
          ),
        );
        await tester.scrollUntilVisible(
          find.text('Crea la partita'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Crea la partita'));
        await tester.pump();
        await tester.tap(find.text('Crea la partita'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Resta'));
        await tester.pumpAndSettle();
        expect(opened, 0);
        expect(await tester.runAsync(store.load), isNotNull);

        await tester.scrollUntilVisible(
          find.text('Crea la partita'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Crea la partita'));
        await tester.pump();
        await tester.tap(find.text('Crea la partita'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Elimina').last);
        await _wait(tester);
        await tester.pumpAndSettle();
        expect(opened, 1);
      },
    );
  });

  testWidgets('RMP-08 la schermata mostra lo stato del collegamento', (
    tester,
  ) async {
    final (a, b) = LoopbackTransport.pair();
    await tester.pumpWidget(
      localizedApp(
        home: MultiplayerPage(
          openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Crea la partita'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Crea la partita'));
    await tester.pump();
    await tester.tap(find.text('Crea la partita'));
    await _wait(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionIndicator), findsOneWidget);
    expect(find.text('In collegamento'), findsWidgets);
    expect(find.byType(InviteCard), findsOneWidget);

    final view = tester.widget<QrCodeView>(find.byType(QrCodeView));
    final guest = (await tester.runAsync(
      () => MultiplayerController.join(
        GameInvite.parse(view.data)!,
        openGuest: (_, _) => b,
      ),
    ))!;
    await _wait(tester);
    expect(find.text('Collegato'), findsWidgets);
    await tester.runAsync(guest.close);
    await tester.runAsync(
      tester
          .widget<MultiplayerGamePage>(find.byType(MultiplayerGamePage))
          .controller
          .close,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('RMP-08 comandi da almeno 48 dp e testo al 130% senza overflow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640) * 2
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: localizedApp(home: const MultiplayerPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final (button, label) in [
      (find.byType(SegmentedButton<Side>), find.text('Bianco')),
      (find.byType(FilledButton), find.text('Crea la partita')),
      (find.byType(OutlinedButton), find.text('Unisciti con il link')),
    ]) {
      await tester.scrollUntilVisible(label, 100);
      final target = find.ancestor(of: label, matching: button).first;
      expect(
        tester.getSize(target).height,
        greaterThanOrEqualTo(48),
        reason: button.toString(),
      );
    }
  });
}
