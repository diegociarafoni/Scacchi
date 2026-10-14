import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/game/speech_bubble.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/progress/avatar_art.dart';
import 'package:scacchi/progress/guardian_avatar.dart';
import 'package:scacchi/storage/key_value_store.dart';
import 'package:scacchi/theme/rokko_theme.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';

const _bubble = ValueKey('speechBubble');

Future<void> pump(
  WidgetTester tester, {
  Size size = const Size(390, 900),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: RokkoTheme.light(),
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GamePage(
        settings: trainingSettings(),
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

Future<void> startBot(WidgetTester tester) async {
  await tapGameAction(tester, 'Nuova');
  await tester.pumpAndSettle();
  await openCustomSheet(tester);
  await tester.tap(find.text('Bot'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Pino'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pino'));
  await tester.pumpAndSettle();
  await chooseTime(tester, 'Senza tempo');
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  testWidgets('il suggerimento è il fumetto dell\'allenatore, non una fascia', (
    tester,
  ) async {
    await pump(tester);
    await startBot(tester);
    await tester.tap(find.byKey(const ValueKey('gameAction-hint')));
    await tester.pumpAndSettle();
    expect(find.byKey(_bubble), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(CharacterAvatar), findsOneWidget);
    // Il fumetto sta sopra la scacchiera, nello spazio libero.
    expect(
      tester.getRect(find.byKey(_bubble)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(Chessboard)).top),
    );
  });

  testWidgets('lo sfidante sta sopra la scacchiera e saluta in un fumetto', (
    tester,
  ) async {
    await pump(tester);
    await startBot(tester);
    expect(find.byType(GuardianAvatar), findsOneWidget);
    expect(find.byKey(_bubble), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    // Il bot proposto dipende dal profilo: basta il saluto di uno qualsiasi.
    final greetings = [for (final b in bots) ...b.phrases(BotEvent.start)];
    expect(greetings.any((p) => find.text(p).evaluate().isNotEmpty), isTrue);
  });

  testWidgets('il fumetto sparisce da solo, lo sfidante resta', (tester) async {
    await pump(tester);
    await startBot(tester);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.byKey(_bubble), findsNothing);
    expect(find.byType(GuardianAvatar), findsOneWidget);
  });

  testWidgets('un tocco chiude il fumetto', (tester) async {
    await pump(tester);
    await startBot(tester);
    await tester.tap(find.byKey(_bubble));
    await tester.pumpAndSettle();
    expect(find.byKey(_bubble), findsNothing);
  });

  testWidgets('senza spazio sopra la scacchiera il messaggio resta in fascia', (
    tester,
  ) async {
    await pump(tester, size: const Size(360, 640));
    await startBot(tester);
    expect(find.byKey(_bubble), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('nessun overflow con il testo ingrandito', (tester) async {
    await pump(tester, size: const Size(360, 780));
    await startBot(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('il fumetto accetta un\'icona di stato davanti al testo', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpeechStrip(
            opponent: null,
            speech: const Speech(
              'Problema risolto!',
              icon: Icon(Icons.check_circle, key: ValueKey('state')),
            ),
            onDismiss: () => closed = true,
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('state')), findsOneWidget);
    expect(find.text('Problema risolto!'), findsOneWidget);
    await tester.tap(find.byKey(_bubble));
    expect(closed, isTrue);
  });

  testWidgets('una frase lunga con il testo al 200% non va in overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SpeechStrip(
            opponent: null,
            speech: Speech('Una spiegazione molto lunga. ' * 8),
            onDismiss: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(_bubble)).height,
      lessThanOrEqualTo(speechStripHeight),
    );
  });
}
