import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';

Offset square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(square(tester, uci.substring(2, 4)));
  await tester.pumpAndSettle();
}

Future<SettingsController> kidSettings({bool kid = true}) async {
  final settings = SettingsController.defaults();
  await settings.update(settings.value.copyWith(kidMode: kid));
  return settings;
}

Future<void> pumpGame(
  WidgetTester tester,
  SettingsController settings, {
  bool computer = false,
  Locale locale = const Locale('it'),
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: GamePage(
        settings: settings,
        computerAvailable: computer,
        now: () => TestWidgetsFlutterBinding.instance.clock.now(),
        createComputer: () =>
            ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Raccoglie gli annunci inviati ai lettori di schermo.
List<String> recordAnnouncements(WidgetTester tester) {
  final messages = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
    SystemChannels.accessibility,
    (message) async {
      final map = message as Map<Object?, Object?>;
      if (map['type'] == 'announce') {
        messages.add(
          (map['data']! as Map<Object?, Object?>)['message']! as String,
        );
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return messages;
}

void main() {
  testWidgets('RP-06 riga di stato con frasi brevi tra due persone', (
    tester,
  ) async {
    await pumpGame(tester, await kidSettings());
    expect(find.text('Tocca al Bianco!'), findsOneWidget);
    expect(find.text('Muove il Bianco.'), findsNothing);
    await tapMove(tester, 'e2e4');
    expect(find.text('Tocca al Nero!'), findsOneWidget);
    await tapMove(tester, 'f7f5');
    await tapMove(tester, 'd1h5');
    expect(find.text('Scacco! Il re nero è in pericolo'), findsOneWidget);
  });

  testWidgets('RP-06 scacco matto con vincitore e festa', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpGame(tester, await kidSettings());
    for (final uci in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
      await tapMove(tester, uci);
    }
    expect(find.text('Scacco matto! Ha vinto il Nero! 🎉'), findsOneWidget);
    // Il lettore di schermo non legge l'emoji.
    final label = tester
        .getSemantics(find.textContaining('Scacco matto!'))
        .label;
    expect(label.split('\n'), contains('Scacco matto! Ha vinto il Nero!'));
    expect(label, isNot(contains('🎉')));
    semantics.dispose();
  });

  testWidgets('RP-06 stallo spiegato in parole semplici', (tester) async {
    await pumpGame(tester, await kidSettings());
    // Stallo più rapido noto (Sam Loyd, 10 mosse).
    const moves = [
      'e2e3', 'a7a5', 'd1h5', 'a8a6', 'h5a5', 'h7h5', 'h2h4', 'a6h6', //
      'a5c7', 'f7f6', 'c7d7', 'e8f7', 'd7b7', 'd8d3', 'b7b8', 'd3h7',
      'b8c8', 'f7g6', 'c8e6',
    ];
    for (final uci in moves) {
      await tapMove(tester, uci);
    }
    expect(
      find.text(
        'Stallo: il re non può muoversi ma non è sotto scacco. Pareggio!',
      ),
      findsOneWidget,
    );
  });

  testWidgets('RP-06 comandi con parole semplici', (tester) async {
    await pumpGame(tester, await kidSettings());
    await tester.tap(find.byKey(const ValueKey('gameAction-more')));
    await tester.pumpAndSettle();
    expect(find.text('Nuova partita'), findsOneWidget);
    expect(find.text('Mi arrendo'), findsOneWidget);
    expect(find.text('Pareggio?'), findsOneWidget);
    expect(find.text('Abbandona'), findsNothing);
    expect(find.text('Patta'), findsNothing);
    expect(find.text('Nuova'), findsNothing);
  });

  testWidgets('RP-06 dialogo di resa semplice', (tester) async {
    await pumpGame(tester, await kidSettings());
    await tapGameAction(tester, 'Mi arrendo');
    await tester.pumpAndSettle();
    expect(find.text('Bianco, vuoi arrenderti?'), findsOneWidget);
    expect(find.text('No, continuo'), findsOneWidget);
    await tester.tap(find.text('Sì, mi arrendo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Il Bianco si arrende. Ha vinto il Nero! 🎉'),
      findsOneWidget,
    );
  });

  testWidgets('RP-06 dialogo di pareggio semplice', (tester) async {
    await pumpGame(tester, await kidSettings());
    await tapGameAction(tester, 'Pareggio?');
    await tester.pumpAndSettle();
    expect(find.text('Nero, vuoi fare pareggio?'), findsOneWidget);
    await tester.tap(find.text('Sì, pareggio'));
    await tester.pumpAndSettle();
    expect(find.text('Pareggio deciso insieme!'), findsOneWidget);
  });

  testWidgets('RP-06 pannello Nuova: solo classica e cadenze lente', (
    tester,
  ) async {
    await pumpGame(tester, await kidSettings());
    await tapGameAction(tester, 'Nuova partita');
    await tester.pumpAndSettle();
    expect(find.text('Chess960'), findsNothing);
    expect(find.text('Variante'), findsNothing);
    expect(find.text('Bullet'), findsNothing);
    expect(find.text('Blitz'), findsNothing);
    expect(find.text('1+0'), findsNothing);
    expect(find.text('Quanto tempo?'), findsOneWidget);
    expect(find.text('Senza tempo'), findsOneWidget);
    await tester.ensureVisible(find.text("Con l'orologio, con calma"));
    await tester.tap(find.text("Con l'orologio, con calma"));
    await tester.pumpAndSettle();
    expect(find.text('15:00'), findsNWidgets(2));
    expect(find.text('Tocca al Bianco!'), findsOneWidget);
  });

  testWidgets('RP-06 menu senza analisi e revisione, niente livelli', (
    tester,
  ) async {
    final settings = await kidSettings(kid: false);
    await pumpGame(tester, settings, computer: true);
    await startComputerGame(tester, side: 'Bianco');
    expect(find.byTooltip('Altre azioni'), findsOneWidget);
    await settings.update(settings.value.copyWith(kidMode: true));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Altre azioni'), findsNothing);
    expect(find.byTooltip('Editor di posizione'), findsNothing);
    expect(find.textContaining('livello'), findsNothing);
    expect(find.text('Tocca a te!'), findsOneWidget);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Tocca a te!'), findsOneWidget);
  });

  testWidgets('RP-06 contro il computer: resa semplice', (tester) async {
    final settings = await kidSettings(kid: false);
    await pumpGame(tester, settings, computer: true);
    await startComputerGame(tester, side: 'Bianco');
    await settings.update(settings.value.copyWith(kidMode: true));
    await tester.pumpAndSettle();
    await tapGameAction(tester, 'Mi arrendo');
    await tester.pumpAndSettle();
    expect(find.text('Vuoi arrenderti?'), findsOneWidget);
    await tester.tap(find.text('Sì, mi arrendo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ti sei arreso. Il computer ha vinto. Riprova!'),
      findsOneWidget,
    );
  });

  testWidgets('senza profilo bambino restano i testi di sempre', (
    tester,
  ) async {
    await pumpGame(tester, await kidSettings(kid: false));
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.text('Nuova'), findsOneWidget);
    expect(find.text('Abbandona'), findsOneWidget);
    expect(find.text('Patta'), findsOneWidget);
  });

  testWidgets('RP-06 annuncia resa e pareggio con le frasi della riga', (
    tester,
  ) async {
    final announced = recordAnnouncements(tester);
    await pumpGame(tester, await kidSettings());
    await tapGameAction(tester, 'Mi arrendo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sì, mi arrendo'));
    await tester.pumpAndSettle();
    expect(announced, contains('Il Bianco si arrende. Ha vinto il Nero!'));

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    await tapGameAction(tester, 'Pareggio?');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sì, pareggio'));
    await tester.pumpAndSettle();
    expect(announced, contains('Pareggio deciso insieme!'));
  });

  testWidgets('anche senza profilo bambino la resa viene annunciata', (
    tester,
  ) async {
    final announced = recordAnnouncements(tester);
    await pumpGame(tester, await kidSettings(kid: false));
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Abbandona'));
    await tester.pumpAndSettle();
    expect(announced, contains('Abbandono. Vince il Nero.'));
  });

  testWidgets('RP-06 una variante in corso tiene il suo titolo', (
    tester,
  ) async {
    final settings = await kidSettings(kid: false);
    await pumpGame(tester, settings);
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await openCustomSheet(tester, two: true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tre scacchi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    await settings.update(settings.value.copyWith(kidMode: true));
    await tester.pumpAndSettle();
    expect(find.text('Scacchi dati: Bianco 0, Nero 0'), findsOneWidget);
  });

  testWidgets('RP-06 pannello e barra interamente localizzati', (tester) async {
    await pumpGame(tester, await kidSettings(), locale: const Locale('en'));
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Flip'), findsOneWidget);
    await tapGameAction(tester, 'New game');
    await tester.pumpAndSettle();
    expect(find.text('New game'), findsOneWidget);
    expect(find.text("White's name"), findsOneWidget);
    expect(find.text("Black's name"), findsOneWidget);
    expect(find.text('Optional'), findsNWidgets(2));
    expect(find.text('No clock'), findsOneWidget);
  });
}
