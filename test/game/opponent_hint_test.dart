import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/game/opponent_picker.dart';
import 'package:scacchi/l10n/app_localizations.dart';

void main() {
  Widget picker(GameSetup setup, {String locale = 'it'}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale(locale),
    home: Scaffold(
      body: SingleChildScrollView(
        child: OpponentPicker(
          setup: setup,
          computerAvailable: true,
          adaptiveLevel: 1,
          collection: const BotCollection(),
          onChanged: (_) {},
        ),
      ),
    ),
  );

  testWidgets('sotto la scelta si spiega cosa significa ogni avversario', (
    tester,
  ) async {
    await tester.pumpWidget(picker(const GameSetup()));
    expect(
      find.text('Si gioca in due sullo stesso dispositivo.'),
      findsOneWidget,
    );
    await tester.pumpWidget(
      picker(const GameSetup(opponent: Opponent.computer)),
    );
    expect(
      find.text('Scegli il livello o lascia che si adatti a te.'),
      findsOneWidget,
    );
    await tester.pumpWidget(picker(const GameSetup(opponent: Opponent.bot)));
    expect(
      find.text('Avversari con personalità da sbloccare uno a uno.'),
      findsOneWidget,
    );
  });

  testWidgets('la spiegazione segue la lingua', (tester) async {
    await tester.pumpWidget(
      picker(const GameSetup(opponent: Opponent.bot), locale: 'en'),
    );
    expect(
      find.text('Opponents with a personality, unlocked one by one.'),
      findsOneWidget,
    );
  });

  testWidgets('un bot bloccato dice quale bot battere per sbloccarlo', (
    tester,
  ) async {
    await tester.pumpWidget(picker(const GameSetup(opponent: Opponent.bot)));
    const collection = BotCollection();
    final locked = bots.where((b) => !collection.isUnlocked(b));
    expect(locked, isNotEmpty);
    for (final b in locked) {
      final name = BotCollection.unlockedBy(b).first.name;
      final count = locked
          .where((l) => BotCollection.unlockedBy(l).first.name == name)
          .length;
      expect(
        find.textContaining('Si sblocca battendo $name'),
        findsNWidgets(count),
        reason: b.id,
      );
    }
    expect(find.textContaining('Si sblocca battendo Stella'), findsNothing);
  });

  testWidgets('sbloccato il bot successivo, l\'indicazione sparisce', (
    tester,
  ) async {
    final collection = const BotCollection().beat(
      'pino',
      DateTime.utc(2026, 10, 11),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: OpponentPicker(
              setup: const GameSetup(opponent: Opponent.bot),
              computerAvailable: true,
              adaptiveLevel: 1,
              collection: collection,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Si sblocca battendo Pino'), findsNothing);
    expect(find.textContaining('Si sblocca battendo Chiara'), findsWidgets);
  });
}
