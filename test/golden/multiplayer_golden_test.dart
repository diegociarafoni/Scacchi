@Tags(['golden'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/multiplayer/game_invite.dart';
import 'package:scacchi/multiplayer/multiplayer_controller.dart';
import 'package:scacchi/multiplayer/multiplayer_page.dart';
import 'package:scacchi/multiplayer/player_identity.dart';
import 'package:scacchi/multiplayer/saved_game.dart';
import 'package:scacchi/multiplayer/transport.dart';
import 'package:scacchi/theme/rokko_theme.dart';

import '../support/devices.dart';

/// Come l'app vera: tema Rokko e font reali (Roboto da `flutter_test_config`).
Widget _app(Widget home, Brightness brightness) => MaterialApp(
  theme: RokkoTheme.light(),
  darkTheme: RokkoTheme.dark(),
  themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('it'),
  home: home,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() async {
    await ChessgroundImages.instance.loadAll(
      const ChessboardSettings().pieceAssets,
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
  await tester.pumpAndSettle();
}

/// La lettura del file avanza solo nella zona reale.
Future<void> _open(WidgetTester tester, Widget app) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(app);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await tester.pump();
  });
  await _settle(tester);
}

SavedGameStore _emptyStore() {
  final dir = Directory.systemTemp.createTempSync('rokko_golden_mp');
  addTearDown(() => dir.deleteSync(recursive: true));
  return SavedGameStore(File('${dir.path}/multiplayer.json'));
}

final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

void main() {
  testWidgets('schermata iniziale su telefono piccolo', skip: _skip != null, (
    tester,
  ) async {
    Device.phoneSmall.apply(tester);
    await tester.pumpWidget(
      _app(MultiplayerPage(store: _emptyStore()), Brightness.light),
    );
    await _settle(tester);
    await expectLater(
      find.byType(MultiplayerPage),
      matchesGoldenFile('goldens/multigiocatore-inizio-telefono-piccolo.png'),
    );
  });

  testWidgets(
    'partita sospesa in scuro su telefono medio',
    skip: _skip != null,
    (tester) async {
      Device.phoneMedium.apply(tester);
      final dir = Directory.systemTemp.createTempSync('rokko_golden_mp');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = SavedGameStore(File('${dir.path}/multiplayer.json'));
      await tester.runAsync(
        () => store.save(
          SavedGame(
            inviteLink: GameInvite(
              gameId: newGameId(),
              secret: newSecret(),
              hostKey: Uint8List(32)..fillRange(0, 32, 7),
              hostSide: Side.white,
              lanAddress: '10.0.0.2:4000',
            ).toLink(),
            isHost: true,
            seed: Uint8List.fromList(List.generate(32, (i) => i)),
            moves: const ['e2e4', 'e7e5'],
            peerKey: Uint8List(32)..fillRange(0, 32, 9),
            sealed: const {},
          ),
        ),
      );
      await _open(tester, _app(MultiplayerPage(store: store), Brightness.dark));
      await expectLater(
        find.byType(MultiplayerPage),
        matchesGoldenFile(
          'goldens/multigiocatore-sospesa-scuro-telefono-medio.png',
        ),
      );
    },
  );

  for (final (brightness, device) in [
    (Brightness.light, Device.phoneMedium),
    (Brightness.dark, Device.phoneSmall),
  ]) {
    testWidgets(
      'invito con QR ${brightness.name} su ${device.name}',
      skip: _skip != null,
      (tester) async {
        device.apply(tester);
        final (a, b) = LoopbackTransport.pair();
        // Invito fisso: con id e segreto casuali il QR cambierebbe a ogni giro.
        final store = _emptyStore();
        final seed = Uint8List.fromList(List.generate(32, (i) => i));
        final identity = (await tester.runAsync(
          () => PlayerIdentity.fromSeed(seed),
        ))!;
        await tester.runAsync(
          () => store.save(
            SavedGame(
              inviteLink: GameInvite(
                gameId: '123e4567-e89b-42d3-a456-426614174000',
                secret: Uint8List(32)..fillRange(0, 32, 5),
                hostKey: identity.publicKey,
                hostSide: Side.white,
                lanAddress: '10.0.0.2:4000',
              ).toLink(),
              isHost: true,
              seed: seed,
              moves: const [],
              sealed: const {},
            ),
          ),
        );
        await _open(
          tester,
          _app(
            MultiplayerPage(
              store: store,
              openResumeHost: (_) async =>
                  (transport: a, lanAddress: '10.0.0.2:4000'),
            ),
            brightness,
          ),
        );
        await tester.tap(find.text('Riprendi la partita'));
        await _settle(tester);
        await expectLater(
          find.byType(MultiplayerGamePage),
          matchesGoldenFile(
            'goldens/multigiocatore-invito-${brightness.name}-${device.name}.png',
          ),
        );
        await tester.runAsync(b.close);
      },
    );
  }

  testWidgets('partita collegata su telefono medio', skip: _skip != null, (
    tester,
  ) async {
    Device.phoneMedium.apply(tester);
    final (a, b) = LoopbackTransport.pair();
    await tester.pumpWidget(
      _app(
        MultiplayerPage(
          store: _emptyStore(),
          openHost: () async => (transport: a, lanAddress: '10.0.0.2:4000'),
        ),
        Brightness.light,
      ),
    );
    await _settle(tester);
    await tester.ensureVisible(find.text('Crea la partita'));
    await tester.pump();
    await tester.tap(find.text('Crea la partita'));
    await _settle(tester);
    final host = tester
        .widget<MultiplayerGamePage>(find.byType(MultiplayerGamePage))
        .controller;
    final invite = GameInvite.parse(host.inviteLink)!;
    final guest = (await tester.runAsync(
      () => MultiplayerController.join(invite, openGuest: (_, _) => b),
    ))!;
    await _settle(tester);
    await expectLater(
      find.byType(MultiplayerGamePage),
      matchesGoldenFile('goldens/multigiocatore-partita-telefono-medio.png'),
    );
    await tester.runAsync(guest.close);
    await tester.runAsync(host.close);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(seconds: 10));
  });
}
