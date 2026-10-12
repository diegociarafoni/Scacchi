import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/adaptive.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import 'computer_fakes.dart';
import 'game_actions.dart';

void main() {
  Widget app(MemoryStore store) => MaterialApp(
    home: GamePage(
      settings: SettingsController.defaults(),
      computerAvailable: true,
      store: store,
      now: () => TestWidgetsFlutterBinding.instance.clock.now(),
      createComputer: () =>
          ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
    ),
  );

  Future<void> openComputerSheet(WidgetTester tester) async {
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Computer'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseAdaptive(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Adattivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adattivo'));
    await tester.pumpAndSettle();
  }

  testWidgets('RF-26 il pannello mostra il livello scelto dall\'adattivo', (
    tester,
  ) async {
    final store = MemoryStore();
    await const AdaptiveOpponent(rating: 2000, games: 12).save(store);
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await openComputerSheet(tester);
    await chooseAdaptive(tester);
    expect(find.textContaining('Livello 6'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('RF-26 la partita adattiva usa il livello stimato', (
    tester,
  ) async {
    final store = MemoryStore();
    await const AdaptiveOpponent(rating: 2000, games: 12).save(store);
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await openComputerSheet(tester);
    await chooseAdaptive(tester);
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('Computer, livello 6'), findsOneWidget);
  });

  Future<void> playE4(WidgetTester tester) async {
    final rect = tester.getRect(find.byType(Chessboard));
    final size = rect.width / 8;
    Offset at(int file, int rank) =>
        rect.topLeft + Offset((file + 0.5) * size, (7 - rank + 0.5) * size);
    await tester.tapAt(at(4, 1));
    await tester.pump();
    await tester.tapAt(at(4, 3));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  Future<void> resign(WidgetTester tester) async {
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Abbandona'));
    await tester.pumpAndSettle();
  }

  Future<void> startAdaptive(WidgetTester tester, MemoryStore store) async {
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await openComputerSheet(tester);
    await chooseAdaptive(tester);
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets('RF-26 l\'esito della partita aggiorna la stima', (tester) async {
    final store = MemoryStore();
    await startAdaptive(tester, store);
    await playE4(tester);
    await resign(tester);
    final saved = await AdaptiveOpponent.load(store);
    expect(saved.games, 1);
    expect(saved.rating, lessThan(1150));
  });

  testWidgets('RF-26 una partita chiusa senza mosse non conta', (tester) async {
    final store = MemoryStore();
    await startAdaptive(tester, store);
    await resign(tester);
    expect((await AdaptiveOpponent.load(store)).games, 0);
  });

  testWidgets('RF-26 annullare l\'abbandono ripristina la stima', (
    tester,
  ) async {
    final store = MemoryStore();
    await startAdaptive(tester, store);
    await playE4(tester);
    await resign(tester);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final saved = await AdaptiveOpponent.load(store);
    expect(saved.games, 0);
    expect(saved.rating, 1150);
    await resign(tester);
    expect((await AdaptiveOpponent.load(store)).games, 1);
  });

  testWidgets('RF-26 senza la modalità adattiva la stima non cambia', (
    tester,
  ) async {
    final store = MemoryStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await startComputerGame(tester, side: 'Bianco');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await playE4(tester);
    await resign(tester);
    expect((await AdaptiveOpponent.load(store)).games, 0);
  });
}
