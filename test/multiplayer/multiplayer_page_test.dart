import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/exchange/qr_code_view.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/multiplayer_controller.dart';
import 'package:scacchi/multiplayer/multiplayer_page.dart';
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

void main() {
  testWidgets('RMP-08 chi crea la partita mostra il QR, poi la scacchiera', (
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
    await tester.tap(find.text('Nero'));
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
          openHost: () async => throw const NoLocalNetwork(),
        ),
      ),
    );
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
          openHost: () async => throw const SocketException('porta occupata'),
        ),
      ),
    );
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
        home: MultiplayerPage(scanner: scanner.build, openGuest: (_, _) => b),
      ),
    );
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
}
