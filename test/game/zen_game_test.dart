import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';
import 'game_qr_test.dart' show tapMove;

void main() {
  late SettingsController settings;

  Future<void> open(
    WidgetTester tester, {
    bool zen = false,
    String locale = 'it',
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    settings = SettingsController.defaults();
    if (zen) await settings.update(settings.value.copyWith(zenMode: true));
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GamePage(
          settings: settings,
          computerAvailable: true,
          store: MemoryStore(),
          now: () => DateTime(2026, 10, 12, 12),
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startBotGame(WidgetTester tester) async {
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bot'));
    await tester.pumpAndSettle();
    await chooseTime(tester, 'Senza tempo');
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  Future<void> startTimedGame(WidgetTester tester) async {
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await chooseTime(tester, '1+1');
    await tester.pumpAndSettle();
  }

  testWidgets('RP-07 senza zen restano stato e materiale', (tester) async {
    await open(tester);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    await tapMove(tester, 'e2e4');
    await tapMove(tester, 'd7d5');
    await tapMove(tester, 'e4d5');
    expect(find.byKey(const ValueKey('advantage-white')), findsOneWidget);
  });

  testWidgets(
    'RP-07 in zen restano scacchiera e mosse, non stato né materiale',
    (tester) async {
      await open(tester, zen: true);
      expect(find.text('Muove il Bianco.'), findsNothing);
      await tapMove(tester, 'e2e4');
      await tapMove(tester, 'd7d5');
      await tapMove(tester, 'e4d5');
      expect(find.byKey(const ValueKey('advantage-white')), findsNothing);
      expect(find.byKey(const ValueKey('player-white')), findsNothing);
      expect(find.textContaining('Muove'), findsNothing);
      expect(
        find.textContaining('exd5'),
        findsWidgets,
        reason: 'le mosse restano',
      );
    },
  );

  testWidgets('RP-07 in zen l\'esito della partita si vede comunque', (
    tester,
  ) async {
    await open(tester, zen: true);
    for (final m in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
      await tapMove(tester, m);
    }
    expect(find.textContaining('Scacco matto'), findsWidgets);
  });

  testWidgets('RP-07 in zen niente Elo né livello del bot, niente allenatore', (
    tester,
  ) async {
    await open(tester);
    await startBotGame(tester);
    final bot = bots.first;
    expect(find.textContaining('${bot.elo} Elo'), findsOneWidget);
    Future<int> coachSwitches() async {
      // Senza allenatore non c'è «Altro»: nessun interruttore.
      if (find.byKey(const ValueKey('gameAction-more')).evaluate().isEmpty) {
        return 0;
      }
      await tester.tap(find.byKey(const ValueKey('gameAction-more')));
      await tester.pumpAndSettle();
      final n = find.byType(SwitchListTile).evaluate().length;
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      return n;
    }

    expect(await coachSwitches(), 1);

    await tester.tap(find.byKey(const Key('zenToggle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Elo'), findsNothing);
    expect(await coachSwitches(), 0);
    expect(find.byIcon(Icons.warning_amber), findsNothing);
  });

  testWidgets('RP-07 in zen i commenti del bot non compaiono', (tester) async {
    await open(tester, zen: true);
    await startBotGame(tester);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('RP-07 in zen l\'orologio resta se la partita ne ha uno', (
    tester,
  ) async {
    await open(tester, zen: true);
    await startTimedGame(tester);
    expect(find.text('1:00'), findsWidgets);
    expect(find.text('Muove il Bianco.'), findsNothing);
  });

  testWidgets('RP-07 si attiva e si disattiva al volo in partita', (
    tester,
  ) async {
    await open(tester);
    expect(find.byTooltip('Modalità zen'), findsOneWidget);
    await tester.tap(find.byKey(const Key('zenToggle')));
    await tester.pumpAndSettle();
    expect(settings.value.zenMode, isTrue);
    expect(find.text('Muove il Bianco.'), findsNothing);
    await tester.tap(find.byKey(const Key('zenToggle')));
    await tester.pumpAndSettle();
    expect(settings.value.zenMode, isFalse);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('RP-07 il pulsante ha un\'etichetta nella lingua e lo stato', (
    tester,
  ) async {
    await open(tester, locale: 'en');
    expect(find.byTooltip('Zen mode'), findsOneWidget);
    IconButton button() =>
        tester.widget<IconButton>(find.byKey(const Key('zenToggle')));
    expect(button().isSelected, isFalse);
    await tester.tap(find.byKey(const Key('zenToggle')));
    await tester.pumpAndSettle();
    expect(button().isSelected, isTrue);
  });

  testWidgets('RP-07 la scacchiera non cambia misura quando lo stato compare', (
    tester,
  ) async {
    await open(tester, zen: true);
    await tapMove(tester, 'e2e4');
    final before = tester.getSize(find.byType(Chessboard));
    await tester.tap(find.textContaining('e4').first);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Chessboard)), before);
  });

  testWidgets('RP-07 la barra del titolo regge uno schermo stretto', (
    tester,
  ) async {
    await open(tester, zen: true);
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
