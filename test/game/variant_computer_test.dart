import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/engine/variant_engine.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/theme/rokko_icons.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';

Future<T> direct<T>(T Function() task) async => task();

void main() {
  var stockfishStarts = 0;

  Widget app() => MaterialApp(
    home: GamePage(
      settings: SettingsController.defaults(),
      computerAvailable: true,
      chess960Id: () => 3,
      now: () => TestWidgetsFlutterBinding.instance.clock.now(),
      createComputer: () => ComputerPlayer(
        connect: () async {
          stockfishStarts++;
          return FirstLegalMoveEngine();
        },
      ),
      createVariantEngine: () =>
          VariantEngine(random: math.Random(1), runner: direct),
    ),
  );

  Future<void> start(WidgetTester tester, String variant) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    stockfishStarts = 0;
    await tester.pumpWidget(app());
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await chooseAdaptiveComputer(tester);
    await scrollSheetTo(tester, find.text('Nero'));
    await tester.tap(find.text('Nero'));
    await tester.pumpAndSettle();
    await scrollSheetTo(tester, find.text(variant));
    await tester.tap(find.text(variant));
    await tester.pumpAndSettle();
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  for (final variant in ['Chess960', 'Re della collina', 'Tre scacchi']) {
    testWidgets('RF-123 contro il computer si gioca a $variant', (
      tester,
    ) async {
      await start(tester, variant);
      // Il computer ha il Bianco e ha già mosso; ora tocca al giocatore.
      expect(find.text('Muove il Nero.'), findsOneWidget);
      expect(find.textContaining('1. '), findsOneWidget);
      expect(stockfishStarts, 0, reason: 'Stockfish non conosce $variant');
    });
  }

  testWidgets('RF-123 nelle varianti niente suggerimenti né allenatore', (
    tester,
  ) async {
    await start(tester, 'Re della collina');
    expect(find.byIcon(RokkoIcons.hint), findsNothing);
    expect(find.byIcon(RokkoIcons.coach), findsNothing);
  });

  testWidgets('RF-123 la patta si chiede al motore delle varianti', (
    tester,
  ) async {
    await start(tester, 'Tre scacchi');
    await tapGameAction(tester, 'Patta');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Il computer rifiuta la patta.'), findsOneWidget);
    expect(stockfishStarts, 0);
  });
}
