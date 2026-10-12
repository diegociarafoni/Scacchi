import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../game_actions.dart';

Future<void> _openSheet(
  WidgetTester tester, {
  bool kid = false,
  Size size = const Size(390, 1600),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final settings = SettingsController.defaults();
  if (kid) await settings.update(settings.value.copyWith(kidMode: true));
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
      home: GamePage(
        settings: settings,
        computerAvailable: false,
        store: MemoryStore(),
        now: () => DateTime(2026, 10, 12, 12),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tapGameAction(tester, kid ? 'Nuova partita' : 'Nuova');
  await tester.pumpAndSettle();
}

Future<void> _chooseApart(WidgetTester tester) async {
  await tester.tap(find.text('Sfida un amico'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ognuno sul suo'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('le scelte sono Bot e «Sfida un amico», anche senza motore', (
    tester,
  ) async {
    await _openSheet(tester);
    expect(find.text('Bot'), findsOneWidget);
    expect(find.text('Sfida un amico'), findsOneWidget);
    expect(find.text('Due giocatori'), findsNothing);
    // Un amico: sullo stesso telefono o ognuno sul suo.
    expect(find.text('Sullo stesso telefono'), findsOneWidget);
    expect(find.text('Ognuno sul suo'), findsOneWidget);
  });

  testWidgets(
    'con «Ognuno sul suo» il foglio mostra colore, collegamento e comandi',
    (tester) async {
      await _openSheet(tester);
      await _chooseApart(tester);
      expect(find.text('Il tuo colore'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.text('Bluetooth'), findsOneWidget);
      expect(find.text('Gioca anche a distanza'), findsOneWidget);
      expect(find.text('Cadenza'), findsOneWidget);
      expect(find.text('Crea la partita'), findsOneWidget);
      expect(find.text('Unisciti con il QR'), findsOneWidget);
      expect(find.text('Unisciti con il link'), findsOneWidget);
      // Nomi, variante e handicap valgono solo per la partita su un telefono.
      expect(find.text('Nome del Bianco'), findsNothing);
      expect(find.text('Variante'), findsNothing);
      expect(find.text('Handicap'), findsNothing);
    },
  );

  testWidgets('a distanza non c\'è orologio, in presenza si sceglie', (
    tester,
  ) async {
    await _openSheet(tester);
    await _chooseApart(tester);
    final chip = find.widgetWithText(ChoiceChip, '3+0');
    expect(tester.widget<ChoiceChip>(chip).onSelected, isNull);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    // Scegliere la cadenza non chiude il foglio: la partita parte dai comandi.
    expect(find.text('Crea la partita'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
  });

  testWidgets('«Sullo stesso telefono» mostra nomi e variante', (tester) async {
    await _openSheet(tester);
    await _chooseApart(tester);
    await tester.tap(find.text('Sullo stesso telefono'));
    await tester.pumpAndSettle();
    expect(find.text('Nome del Bianco'), findsOneWidget);
    expect(find.text('Crea la partita'), findsNothing);
  });

  testWidgets('il profilo bambino non vede «Sfida un amico»', (tester) async {
    await _openSheet(tester, kid: true);
    expect(find.text('Sfida un amico'), findsNothing);
  });

  testWidgets('cambiando avversario e tornando, le scelte restano', (
    tester,
  ) async {
    await _openSheet(tester);
    await _chooseApart(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    final chip = find.widgetWithText(ChoiceChip, '3+0');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sullo stesso telefono'));
    await tester.pumpAndSettle();
    expect(find.text('Crea la partita'), findsNothing);
    await _chooseApart(tester);
    expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
  });
}
