import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import 'computer_fakes.dart';

void main() {
  Future<SettingsController> kidSettings({bool kidMode = true}) async {
    final settings = SettingsController.defaults();
    await settings.update(settings.value.copyWith(kidMode: kidMode));
    return settings;
  }

  Widget app(SettingsController settings) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('it'),
    home: GamePage(
      settings: settings,
      computerAvailable: true,
      store: MemoryStore(),
      now: () => TestWidgetsFlutterBinding.instance.clock.now(),
      createComputer: () =>
          ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
    ),
  );

  bool saidAny(List<String> phrases) =>
      phrases.any((p) => find.textContaining(p).evaluate().isNotEmpty);

  testWidgets('RP-06 nella nuova partita non c\'è il computer', (tester) async {
    await tester.pumpWidget(app(await kidSettings()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    expect(find.text('Bot'), findsOneWidget);
    expect(find.text('Computer'), findsNothing);
    await tester.tap(find.text('Bot'));
    await tester.pumpAndSettle();
    expect(find.text(bots[3].name), findsNothing);
    expect(find.textContaining('Elo'), findsNothing);
  });

  testWidgets('RP-06 il bot saluta in modo amichevole e senza Elo', (
    tester,
  ) async {
    await tester.pumpWidget(app(await kidSettings()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bot'));
    await tester.pumpAndSettle();
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final bot = friendlyBots.first;
    expect(find.textContaining('${bot.avatar} ${bot.name}'), findsWidgets);
    expect(find.textContaining('Elo'), findsNothing);
    expect(saidAny(bot.phrases(BotEvent.start, friendly: true)), isTrue);
    expect(saidAny(bot.phrases(BotEvent.start)), isFalse);
  });

  testWidgets('RP-06 la scelta del computer diventa un bot amichevole', (
    tester,
  ) async {
    final settings = await kidSettings(kidMode: false);
    await tester.pumpWidget(app(settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Computer'));
    await tester.pumpAndSettle();
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await settings.update(settings.value.copyWith(kidMode: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuova'));
    await tester.pumpAndSettle();
    expect(find.text('Pino'), findsOneWidget);
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('🐣 Pino'), findsWidgets);
    expect(find.textContaining('livello'), findsNothing);
  });
}
