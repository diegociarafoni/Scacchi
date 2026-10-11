import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/engine/style.dart';
import 'package:scacchi/game/opponent_picker.dart';
import 'package:scacchi/l10n/app_localizations.dart';

void main() {
  final it = lookupAppLocalizations(const Locale('it'));

  Widget picker(
    GameSetup setup, {
    BotCollection collection = const BotCollection(),
    ValueChanged<GameSetup>? onChanged,
    bool computerAvailable = true,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('it'),
    home: Scaffold(
      body: SingleChildScrollView(
        child: OpponentPicker(
          setup: setup,
          computerAvailable: computerAvailable,
          adaptiveLevel: 1,
          collection: collection,
          kidMode: true,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );

  testWidgets('RP-06 solo «Due giocatori» e «Bot», niente computer', (
    tester,
  ) async {
    await tester.pumpWidget(picker(const GameSetup()));
    expect(find.text('Due giocatori'), findsOneWidget);
    expect(find.text('Bot'), findsOneWidget);
    expect(find.text('Computer'), findsNothing);
  });

  testWidgets('RP-06 solo i bot amichevoli, senza Elo, stile né apertura', (
    tester,
  ) async {
    await tester.pumpWidget(picker(const GameSetup(opponent: Opponent.bot)));
    for (final bot in friendlyBots) {
      expect(find.text(bot.name), findsOneWidget, reason: bot.id);
      expect(find.text(bot.avatar), findsOneWidget, reason: bot.id);
    }
    for (final bot in bots.skip(friendlyBots.length)) {
      expect(find.text(bot.name), findsNothing, reason: bot.id);
    }
    expect(find.textContaining('Elo'), findsNothing);
    for (final bot in bots) {
      expect(find.textContaining(bot.openingName), findsNothing);
      expect(find.textContaining(styleLabel(bot.style)), findsNothing);
    }
    expect(find.text(it.kidBotPinoDescription), findsOneWidget);
    expect(find.text(it.kidBotChiaraDescription), findsOneWidget);
    expect(find.text(it.kidBotRoccoDescription), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
  });

  testWidgets('RP-06 senza motore un testo semplice, senza Stockfish', (
    tester,
  ) async {
    await tester.pumpWidget(
      picker(const GameSetup(), computerAvailable: false),
    );
    expect(find.textContaining('Stockfish'), findsNothing);
    expect(find.text(it.kidBotUnavailable), findsOneWidget);
  });

  testWidgets('RP-06 il bot battuto ha la spunta ma non la data', (
    tester,
  ) async {
    await tester.pumpWidget(
      picker(
        const GameSetup(opponent: Opponent.bot),
        collection: const BotCollection().beat(
          'pino',
          DateTime.utc(2026, 10, 11),
        ),
      ),
    );
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.textContaining('2026'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('RP-06 una configurazione del computer mostra i bot', (
    tester,
  ) async {
    GameSetup? changed;
    await tester.pumpWidget(
      picker(
        const GameSetup(opponent: Opponent.computer, level: 7),
        onChanged: (s) => changed = s,
      ),
    );
    expect(find.text('Pino'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(find.textContaining('Livello'), findsNothing);
    await tester.tap(find.text('Nero'));
    await tester.pump();
    expect(changed?.opponent, Opponent.bot);
    expect(changed?.botId, 'pino');
    expect(changed?.sideChoice, SideChoice.black);
  });
}
