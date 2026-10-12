import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/adaptive.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import 'computer_fakes.dart';
import 'game_actions.dart';

void main() {
  Widget app(MemoryStore store, {List<String>? script}) => MaterialApp(
    home: GamePage(
      settings: SettingsController.defaults(),
      computerAvailable: true,
      store: store,
      now: () => TestWidgetsFlutterBinding.instance.clock.now(),
      createComputer: () => ComputerPlayer(
        connect: () async => FirstLegalMoveEngine(script: script),
      ),
    ),
  );

  bool said(Bot bot, BotEvent event) => bot
      .phrases(event)
      .any((p) => find.textContaining(p).evaluate().isNotEmpty);

  Future<void> tapMove(WidgetTester tester, String uci) async {
    final rect = tester.getRect(find.byType(Chessboard));
    final size = rect.width / 8;
    Offset at(String sq) =>
        rect.topLeft +
        Offset(
          (sq.codeUnitAt(0) - 97 + 0.5) * size,
          (7 - (int.parse(sq[1]) - 1) + 0.5) * size,
        );
    await tester.tapAt(at(uci.substring(0, 2)));
    await tester.pump();
    await tester.tapAt(at(uci.substring(2, 4)));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> openBotSheet(WidgetTester tester) async {
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bot'));
    await tester.pumpAndSettle();
  }

  Future<void> pickBot(WidgetTester tester, String name) async {
    await tester.ensureVisible(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  testWidgets('RG-04 solo il primo bot è sbloccato all\'inizio', (
    tester,
  ) async {
    await tester.pumpWidget(app(MemoryStore()));
    await tester.pumpAndSettle();
    await openBotSheet(tester);
    for (final bot in bots) {
      expect(find.text(bot.name), findsOneWidget, reason: bot.id);
    }
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(bots.length - 1));
  });

  testWidgets('RG-04 un bot bloccato non si può scegliere', (tester) async {
    await tester.pumpWidget(app(MemoryStore()));
    await tester.pumpAndSettle();
    await openBotSheet(tester);
    await pickBot(tester, bots[1].name);
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining(bots[0].name), findsWidgets);
    expect(find.textContaining(bots[1].name), findsNothing);
  });

  testWidgets('RG-04 battere un bot sblocca il successivo', (tester) async {
    final store = MemoryStore();
    await const BotCollection()
        .beat(bots[0].id, DateTime.utc(2026, 10, 11))
        .save(store);
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await openBotSheet(tester);
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(bots.length - 2));
    expect(find.textContaining('Battuto'), findsOneWidget);
    await pickBot(tester, bots[1].name);
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining(bots[1].name), findsWidgets);
  });

  testWidgets('RF-23 la partita mostra nome, avatar ed Elo e il saluto', (
    tester,
  ) async {
    await tester.pumpWidget(app(MemoryStore()));
    await tester.pumpAndSettle();
    await openBotSheet(tester);
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final bot = bots.first;
    expect(find.textContaining('${bot.avatar} ${bot.name}'), findsWidgets);
    expect(find.textContaining('${bot.elo}'), findsWidgets);
    expect(said(bot, BotEvent.start), isTrue);
  });

  testWidgets('RF-23 il bot apre con la sua apertura preferita', (
    tester,
  ) async {
    await tester.pumpWidget(app(MemoryStore()));
    await tester.pumpAndSettle();
    await openBotSheet(tester);
    await tester.ensureVisible(find.text('Nero'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nero'));
    await tester.pumpAndSettle();
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.textContaining('1. e4'), findsOneWidget);
  });

  testWidgets('RG-04 battere il bot lo aggiunge alla collezione', (
    tester,
  ) async {
    final store = MemoryStore();
    await tester.pumpWidget(app(store, script: ['f7f6', 'g7g5']));
    await tester.pumpAndSettle();
    await openBotSheet(tester);
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapMove(tester, 'd2d4');
    await tapMove(tester, 'e2e4');
    await tapMove(tester, 'd1h5');
    final collection = await BotCollection.load(store);
    expect(collection.isBeaten(bots[0]), isTrue);
    expect(collection.isUnlocked(bots[1]), isTrue);
    expect(said(bots[0], BotEvent.loss), isTrue);
  });

  testWidgets('RG-04 perdere non aggiunge il bot alla collezione', (
    tester,
  ) async {
    final store = MemoryStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await openBotSheet(tester);
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapMove(tester, 'a2a3');
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Abbandona'));
    await tester.pumpAndSettle();
    expect((await BotCollection.load(store)).beaten, isEmpty);
    expect(said(bots[0], BotEvent.win), isTrue);
  });

  testWidgets(
    'RG-04 annullare dopo la vittoria toglie il bot dalla collezione',
    (tester) async {
      final store = MemoryStore();
      await tester.pumpWidget(app(store, script: ['f7f6', 'g7g5']));
      await tester.pumpAndSettle();
      await openBotSheet(tester);
      await chooseTime(tester, 'Senza tempo');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tapMove(tester, 'd2d4');
      await tapMove(tester, 'e2e4');
      await tapMove(tester, 'd1h5');
      expect((await BotCollection.load(store)).isBeaten(bots[0]), isTrue);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect((await BotCollection.load(store)).beaten, isEmpty);
    },
  );

  testWidgets('RF-26 le partite contro i bot non toccano la stima adattiva', (
    tester,
  ) async {
    final store = MemoryStore();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Computer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Adattivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adattivo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Bot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bot'));
    await tester.pumpAndSettle();
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapMove(tester, 'a2a3');
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Abbandona'));
    await tester.pumpAndSettle();
    expect((await AdaptiveOpponent.load(store)).games, 0);
  });
}
