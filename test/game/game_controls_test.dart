import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/storage/key_value_store.dart';
import 'package:rokko/theme/rokko_theme.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';
import 'game_qr_test.dart' show tapMove;

Future<void> pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool kid = false,
  bool computer = false,
  double textScale = 1,
  KeyValueStore? store,
  Locale locale = const Locale('it'),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final settings = trainingSettings();
  if (kid) await settings.update(settings.value.copyWith(kidMode: true));
  await tester.pumpWidget(
    MaterialApp(
      theme: RokkoTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: GamePage(
        settings: settings,
        computerAvailable: computer,
        store: store ?? MemoryStore(),
        now: () => DateTime(2026, 10, 12, 12),
        createComputer: () =>
            ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder action(String id) => find.byKey(ValueKey('gameAction-$id'));

void main() {
  testWidgets('Nuova, Patta e Abbandona stanno in vista, da almeno 48 dp', (
    tester,
  ) async {
    for (final size in const [Size(360, 640), Size(340, 640), Size(320, 568)]) {
      await pump(tester, size: size, computer: true);
      await tapGameAction(tester, 'Nuova');
      await tester.pumpAndSettle();
      await chooseAdaptiveComputer(tester);
      await chooseTime(tester, 'Senza tempo');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      for (final id in ['new', 'draw', 'resign', 'undo']) {
        final rect = tester.getRect(action(id));
        expect(rect.width, greaterThanOrEqualTo(48), reason: '$id $size');
        expect(rect.height, greaterThanOrEqualTo(48), reason: '$id $size');
        expect(rect.right, lessThanOrEqualTo(size.width), reason: '$id $size');
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'partita tra due persone: tutti i comandi in vista, niente Altro',
    (tester) async {
      await pump(tester);
      for (final label in ['Nuova', 'Patta', 'Abbandona', 'Annulla', 'Gira']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(action('more'), findsNothing);
    },
  );

  testWidgets('Abbandona dalla barra chiede conferma', (tester) async {
    await pump(tester);
    await tester.tap(action('resign'));
    await tester.pumpAndSettle();
    expect(find.text('Abbandonare la partita?'), findsOneWidget);
  });

  testWidgets(
    'Allenatore è un interruttore e Minaccia compare solo se acceso',
    (tester) async {
      await pump(tester, computer: true);
      await tapGameAction(tester, 'Nuova');
      await tester.pumpAndSettle();
      await chooseAdaptiveComputer(tester);
      await chooseTime(tester, 'Senza tempo');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(action('more'));
      await tester.pumpAndSettle();
      expect(find.byType(SwitchListTile), findsOneWidget);
      await tester.tap(find.widgetWithText(SwitchListTile, 'Allenatore'));
      await tester.pumpAndSettle();
      await tester.tap(action('more'));
      await tester.pumpAndSettle();
      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.text('Minaccia'), findsOneWidget);
    },
  );

  testWidgets('i pulsanti della barra hanno etichetta e ruolo per il lettore', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    final data = tester.getSemantics(action('resign'));
    expect(data.label, contains('Abbandona'));
    // ignore: deprecated_member_use
    expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
    handle.dispose();
  });

  testWidgets('editor e tastiera stanno nel menu ⋮', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    expect(find.text('Editor di posizione'), findsOneWidget);
    expect(find.text('Mossa da tastiera'), findsOneWidget);
  });

  testWidgets('il titolo mostra il marchio Rokko', (tester) async {
    await pump(tester);
    expect(find.byType(RokkoWordmark), findsOneWidget);
  });

  testWidgets('editor e tastiera non sono più nella barra del titolo', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byIcon(Icons.edit_note), findsNothing);
    expect(find.byIcon(Icons.keyboard_outlined), findsNothing);
  });

  testWidgets('con il lettore di schermo la tastiera resta in barra', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pump(tester);
    expect(find.byIcon(Icons.keyboard_outlined), findsOneWidget);
  });

  testWidgets('profilo bambino: tre comandi da 56 dp, il resto nel pannello', (
    tester,
  ) async {
    await pump(tester, kid: true, size: const Size(360, 640));
    final bar = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey &&
          '${(w.key! as ValueKey).value}'.startsWith('gameAction-'),
    );
    expect(bar.evaluate().length, 3);
    for (final e in bar.evaluate()) {
      expect(
        tester.getSize(find.byWidget(e.widget)).height,
        greaterThanOrEqualTo(56),
      );
      expect(
        tester.getSize(find.byWidget(e.widget)).width,
        greaterThanOrEqualTo(56),
      );
    }
    expect(find.text('Mi arrendo'), findsNothing);
    await tester.tap(action('more'));
    await tester.pumpAndSettle();
    expect(find.text('Mi arrendo'), findsOneWidget);
    expect(find.text('Pareggio?'), findsOneWidget);
    expect(find.text('Nuova partita'), findsOneWidget);
    expect(find.text('Editor di posizione'), findsNothing);
  });

  testWidgets('niente spazio morto: la scacchiera sta sopra la barra', (
    tester,
  ) async {
    await pump(tester, size: const Size(390, 900));
    final board = tester.getRect(find.byType(Chessboard));
    final bar = tester.getRect(action('undo'));
    // Sotto la scacchiera restano solo il giocatore e i comandi.
    expect(bar.top - board.bottom, lessThan(60));
  });

  testWidgets('con il testo al 130% non ci sono overflow', (tester) async {
    await pump(tester, size: const Size(360, 640), textScale: 1.3);
    expect(tester.takeException(), isNull);
    await pump(tester, size: const Size(360, 640), textScale: 1.3, kid: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('suggerimenti al primo uso: uno alla volta, poi mai più', (
    tester,
  ) async {
    final store = MemoryStore();
    await pump(tester, store: store);
    expect(find.byKey(const ValueKey('gameTip')), findsNothing);
    await tapMove(tester, 'e2e4');
    expect(find.byKey(const ValueKey('gameTip')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gameTipClose')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gameTip')), findsNothing);
    // Dopo averli chiusi non tornano in una partita nuova.
    await pump(tester, store: store);
    await tapMove(tester, 'e2e4');
    expect(find.byKey(const ValueKey('gameTip')), findsNothing);
  });

  testWidgets('a fine prima partita compare l\'invito a rivedere', (
    tester,
  ) async {
    await pump(tester, computer: true);
    await tapMove(tester, 'f2f3');
    await tapMove(tester, 'e7e5');
    await tapMove(tester, 'g2g4');
    await tapMove(tester, 'd8h4');
    expect(find.byKey(const ValueKey('reviewInvite')), findsOneWidget);
    expect(find.text('Rivedi la partita'), findsWidgets);
  });
}
