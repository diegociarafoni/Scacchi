import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/openings/opening_game.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';

Future<void> _openSheet(
  WidgetTester tester, {
  bool kid = false,
  bool engine = false,
  Future<void> Function(BuildContext, OpeningGameRequest)? openingGame,
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
        computerAvailable: engine,
        store: MemoryStore(),
        now: () => DateTime(2026, 10, 12, 12),
        createComputer: () =>
            ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        tournamentPage: engine
            ? () async => const Scaffold(body: Text('Pagina dei tornei'))
            : null,
        physicalPage: () => const Scaffold(body: Text('Pagina fisica')),
        openingGame: openingGame,
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
  await tester.tap(find.text('Ognuno sul suo telefono'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('il foglio parte dal menu con l\'avvio immediato in testa', (
    tester,
  ) async {
    await _openSheet(tester, engine: true);
    expect(find.text('Inizia partita'), findsOneWidget);
    expect(find.text('Sfida un amico'), findsOneWidget);
    expect(find.text('Scegli il bot'), findsOneWidget);
    expect(find.text("Gioca con l'istruttore"), findsOneWidget);
    expect(find.text('Tornei'), findsOneWidget);
    // Nessun selettore a segmenti né interruttore a distanza.
    expect(find.byType(SegmentedButton<Object>), findsNothing);
    expect(find.text('Computer'), findsNothing);
    await tester.tap(find.text('Altre modalità'));
    await tester.pumpAndSettle();
    expect(find.text('Partita personalizzata'), findsOneWidget);
    expect(find.text('Due giocatori sullo stesso telefono'), findsOneWidget);
    expect(find.text('Scacchiera fisica'), findsOneWidget);
  });

  testWidgets('«Inizia partita» parte subito contro il computer del livello', (
    tester,
  ) async {
    await _openSheet(tester, engine: true);
    await tester.tap(find.byKey(const ValueKey('quick-start')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Inizia partita'), findsNothing);
    expect(find.textContaining('Computer, livello'), findsOneWidget);
  });

  testWidgets('«Gioca con l\'istruttore» chiede colore e livello e avvia', (
    tester,
  ) async {
    OpeningGameRequest? started;
    await _openSheet(
      tester,
      engine: true,
      openingGame: (context, request) async => started = request,
    );
    await tester.tap(find.text("Gioca con l'istruttore"));
    await tester.pumpAndSettle();
    expect(find.text('Gioca contro il computer'), findsOneWidget);
    await tester.tap(find.text('Gioca'));
    await tester.pumpAndSettle();
    expect(started?.instructor, isTrue);
    expect(find.text('Inizia partita'), findsNothing);
  });

  testWidgets('«Tornei» e «Scacchiera fisica» aprono la loro pagina', (
    tester,
  ) async {
    await _openSheet(tester, engine: true);
    await tester.tap(find.text('Tornei'));
    await tester.pumpAndSettle();
    expect(find.text('Pagina dei tornei'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Altre modalità'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scacchiera fisica'));
    await tester.pumpAndSettle();
    expect(find.text('Pagina fisica'), findsOneWidget);
  });

  testWidgets('senza motore restano l\'amico e la partita in due', (
    tester,
  ) async {
    await _openSheet(tester);
    expect(find.text('Sfida un amico'), findsOneWidget);
    expect(find.text('Scegli il bot'), findsNothing);
    expect(find.text('Tornei'), findsNothing);
    expect(find.text('In due sullo stesso telefono'), findsOneWidget);
  });

  testWidgets('«Sfida un amico» chiede dove si gioca', (tester) async {
    await _openSheet(tester);
    await tester.tap(find.text('Sfida un amico'));
    await tester.pumpAndSettle();
    expect(find.text('Sullo stesso telefono'), findsOneWidget);
    expect(find.text('Ognuno sul suo telefono'), findsOneWidget);
  });

  testWidgets(
    'con «Ognuno sul suo» si sceglie come raggiungersi, senza interruttore',
    (tester) async {
      await _openSheet(tester);
      await _chooseApart(tester);
      expect(find.text('Il tuo colore'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.text('Bluetooth'), findsOneWidget);
      expect(find.text('A distanza'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Cadenza'), findsOneWidget);
      expect(find.text('Crea la partita'), findsOneWidget);
      expect(find.text('Unisciti con il QR'), findsOneWidget);
      expect(find.text('Unisciti con il link'), findsOneWidget);
      expect(find.text('Nome del Bianco'), findsNothing);
      expect(find.text('Variante'), findsNothing);
    },
  );

  testWidgets('la cadenza resta a distanza e si aggiunge il tempo per mossa', (
    tester,
  ) async {
    await _openSheet(tester);
    await _chooseApart(tester);
    final chip = find.widgetWithText(ChoiceChip, '3+0');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    // Scegliere la cadenza non chiude il foglio: la partita parte dai comandi.
    expect(find.text('Crea la partita'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
    await tester.tap(find.text('A distanza'));
    await tester.pumpAndSettle();
    expect(chip, findsOneWidget);
    expect(find.text('Tempo per mossa'), findsOneWidget);
    await tester.tap(find.text('Wi-Fi'));
    await tester.pumpAndSettle();
    expect(find.text('Cadenza'), findsOneWidget);
  });

  testWidgets('«Sullo stesso telefono» mostra nomi e variante', (tester) async {
    await _openSheet(tester);
    await tester.tap(find.text('Sfida un amico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sullo stesso telefono'));
    await tester.pumpAndSettle();
    expect(find.text('Nome del Bianco'), findsOneWidget);
    expect(find.text('Crea la partita'), findsNothing);
  });

  testWidgets('la freccia riporta al menu', (tester) async {
    await _openSheet(tester);
    await _chooseApart(tester);
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(find.text('Sullo stesso telefono'), findsOneWidget);
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(find.text('Inizia partita'), findsOneWidget);
  });

  testWidgets('uscendo da Tornei la partita in corso riparte', (tester) async {
    await _openSheet(tester, engine: true);
    await tester.tap(find.byKey(const ValueKey('quick-start')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tornei'));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(find.text('Pagina dei tornei'), findsNothing);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('il profilo bambino ha la scelta semplice, senza menu', (
    tester,
  ) async {
    await _openSheet(tester, kid: true);
    expect(find.text('Sfida un amico'), findsNothing);
    expect(find.text('Inizia partita'), findsNothing);
  });
}
