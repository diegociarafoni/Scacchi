import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/game/opponent_picker.dart';
import 'package:scacchi/l10n/app_localizations.dart';

void main() {
  Widget picker(
    GameSetup setup, {
    ValueChanged<GameSetup>? onChanged,
    bool kidMode = false,
    int adaptiveLevel = 3,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('it'),
    home: Scaffold(
      body: SingleChildScrollView(
        child: OpponentPicker(
          setup: setup,
          computerAvailable: true,
          adaptiveLevel: adaptiveLevel,
          collection: const BotCollection(),
          kidMode: kidMode,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );

  final adaptive = find.byKey(const ValueKey('adaptive-opponent'));

  testWidgets('la scelta è Due giocatori e Bot: niente «Computer»', (
    tester,
  ) async {
    await tester.pumpWidget(picker(const GameSetup()));
    expect(find.text('Bot'), findsOneWidget);
    expect(find.text('Due giocatori'), findsOneWidget);
    expect(find.text('Computer'), findsNothing);
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('tornando a «Bot» si riparte dall\'adattivo', (tester) async {
    GameSetup? changed;
    await tester.pumpWidget(
      picker(const GameSetup(), onChanged: (s) => changed = s),
    );
    await tester.tap(find.text('Bot'));
    expect(changed?.opponent, Opponent.computer);
    expect(changed?.adaptive, isTrue);
  });

  testWidgets('tra i bot c\'è «Adattivo» col livello stimato', (tester) async {
    await tester.pumpWidget(picker(const GameSetup(opponent: Opponent.bot)));
    expect(adaptive, findsOneWidget);
    expect(find.textContaining('Livello 3'), findsOneWidget);
  });

  testWidgets('toccare «Adattivo» sceglie il motore adattivo', (tester) async {
    GameSetup? changed;
    await tester.pumpWidget(
      picker(
        const GameSetup(opponent: Opponent.bot),
        onChanged: (s) => changed = s,
      ),
    );
    await tester.tap(adaptive);
    expect(changed?.opponent, Opponent.computer);
    expect(changed?.adaptive, isTrue);
  });

  testWidgets('con «Adattivo» scelto la riga è evidenziata', (tester) async {
    await tester.pumpWidget(
      picker(const GameSetup(opponent: Opponent.computer, adaptive: true)),
    );
    expect(tester.widget<ListTile>(adaptive).selected, isTrue);
  });

  testWidgets('scegliere un bot toglie l\'adattivo', (tester) async {
    GameSetup? changed;
    await tester.pumpWidget(
      picker(
        const GameSetup(opponent: Opponent.computer, adaptive: true),
        onChanged: (s) => changed = s,
      ),
    );
    await tester.tap(find.text('Pino'));
    expect(changed?.opponent, Opponent.bot);
    expect(changed?.botId, 'pino');
  });

  testWidgets('senza amici (editor) restano Due giocatori e Bot', (
    tester,
  ) async {
    await tester.pumpWidget(picker(const GameSetup()));
    expect(find.text('Due giocatori'), findsOneWidget);
    expect(find.text('Bot'), findsOneWidget);
    expect(find.text('Sfida un amico'), findsNothing);
  });

  testWidgets('il profilo bambino non vede «Adattivo» né gli amici', (
    tester,
  ) async {
    await tester.pumpWidget(
      picker(const GameSetup(opponent: Opponent.bot), kidMode: true),
    );
    expect(adaptive, findsNothing);
    expect(find.text('Sfida un amico'), findsNothing);
  });
}
