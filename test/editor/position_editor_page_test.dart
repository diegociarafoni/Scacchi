import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/editor/position_editor_page.dart';
import 'package:scacchi/engine/adaptive.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../computer_fakes.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Offset square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(StaticChessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

String fen(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('editor-fen'))).data!;

Future<Position?> openEditor(WidgetTester tester, {String? initialFen}) async {
  phone(tester);
  Position? result;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<Position>(
              MaterialPageRoute(
                builder: (_) => PositionEditorPage(initialFen: initialFen),
              ),
            );
          },
          child: const Text('apri'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('apri'));
  await tester.pumpAndSettle();
  return result;
}

Future<void> scrollTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> pasteFen(WidgetTester tester, String text) async {
  await scrollTap(tester, find.text('Incolla FEN'));
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.text('Carica'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('RF-53 la stringa FEN ha un titolo e una spiegazione', (
    tester,
  ) async {
    await openEditor(tester);
    final help = find.byKey(const Key('editor-fen-help'));
    await tester.ensureVisible(help);
    await tester.pumpAndSettle();
    expect(find.text('Posizione (FEN)'), findsOneWidget);
    expect(find.byTooltip('Che cos\'è il FEN?'), findsOneWidget);
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(find.textContaining('Incolla FEN'), findsWidgets);
    expect(find.textContaining('altre app'), findsOneWidget);
    await tester.tap(find.text('Ho capito'));
    await tester.pumpAndSettle();
    expect(find.textContaining('altre app'), findsNothing);
  });

  testWidgets('RF-53 parte dalla posizione iniziale', (tester) async {
    await openEditor(tester);
    expect(
      fen(tester),
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    );
  });

  testWidgets('RF-53 la gomma toglie un pezzo e un pezzo scelto si posa', (
    tester,
  ) async {
    await openEditor(tester);
    await tester.tap(find.byKey(const Key('editor-eraser')));
    await tester.pump();
    await tester.tapAt(square(tester, 'e2'));
    await tester.pump();
    expect(fen(tester), startsWith('rnbqkbnr/pppppppp/8/8/8/8/PPPP1PPP/'));
    await tester.tap(find.byKey(const Key('editor-piece-wQ')));
    await tester.pump();
    await tester.tapAt(square(tester, 'e4'));
    await tester.pump();
    expect(fen(tester), contains('/4Q3/'));
  });

  testWidgets('RF-53 la scacchiera vuota non si gioca e lo spiega', (
    tester,
  ) async {
    await openEditor(tester);
    await scrollTap(tester, find.text('Svuota'));
    expect(find.text('La scacchiera è vuota.'), findsOneWidget);
    final play = find.widgetWithText(FilledButton, 'Gioca da qui');
    expect(tester.widget<FilledButton>(play).onPressed, isNull);
  });

  testWidgets('RF-53 tratto e arrocco cambiano il FEN', (tester) async {
    await openEditor(tester);
    await scrollTap(tester, find.text('Nero'));
    expect(fen(tester), contains(' b KQkq '));
    await scrollTap(tester, find.text('O-O-O nero'));
    expect(fen(tester), contains(' b KQk '));
  });

  testWidgets('RF-53 FEN incollato e non valido', (tester) async {
    await openEditor(tester);
    await pasteFen(tester, 'testo a caso');
    expect(find.text('FEN non valido.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await pasteFen(tester, '4k3/8/8/8/8/8/8/4K3 w - - 0 1');
    expect(fen(tester), '4k3/8/8/8/8/8/8/4K3 w - - 0 1');
  });

  testWidgets('RF-53 Gioca da qui restituisce la posizione', (tester) async {
    phone(tester);
    Position? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<Position>(
                MaterialPageRoute(
                  builder: (_) => const PositionEditorPage(
                    initialFen: '4k3/8/8/8/8/8/4Q3/4K3 b - - 0 1',
                  ),
                ),
              );
            },
            child: const Text('apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    await scrollTap(tester, find.text('Gioca da qui'));
    expect(result!.fen, '4k3/8/8/8/8/8/4Q3/4K3 b - - 0 1');
  });

  testWidgets('RF-53 dalla partita si gioca la posizione creata', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: GamePage(
          settings: SettingsController.defaults(),
          computerAvailable: false,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Editor di posizione'));
    await tester.pumpAndSettle();
    await pasteFen(tester, '4k3/8/8/8/8/8/4Q3/4K3 b - - 0 1');
    await scrollTap(tester, find.text('Gioca da qui'));
    expect(find.text('Scacco al Nero. Muove il Nero.'), findsOneWidget);
  });

  testWidgets('la posizione creata si gioca in due anche dopo il computer', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: GamePage(
          settings: SettingsController.defaults(),
          computerAvailable: true,
          createComputer: () =>
              ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        ),
      ),
    );
    await startComputerGame(tester, side: 'Nero');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('Computer, livello'), findsOneWidget);
    await tester.tap(find.byTooltip('Editor di posizione'));
    await tester.pumpAndSettle();
    await pasteFen(tester, '4k3/8/8/8/8/8/4Q3/4K3 b - - 0 1');
    await scrollTap(tester, find.text('Gioca da qui'));
    await scrollTap(tester, find.widgetWithText(FilledButton, 'Gioca'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('Computer, livello'), findsNothing);
    expect(find.text('Scacco al Nero. Muove il Nero.'), findsOneWidget);
    expect(
      tester.widget<Chessboard>(find.byType(Chessboard)).orientation,
      Side.white,
    );
  });

  group('RF-24 posizione personalizzata contro il motore', () {
    const checkFen = '4k3/8/8/8/8/8/4Q3/4K3 b - - 0 1';

    Future<void> editPosition(
      WidgetTester tester, {
      MemoryStore? store,
      String fen = checkFen,
    }) async {
      phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('it'),
          home: GamePage(
            settings: SettingsController.defaults(),
            computerAvailable: true,
            store: store ?? MemoryStore(),
            now: () => TestWidgetsFlutterBinding.instance.clock.now(),
            createComputer: () =>
                ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editor di posizione'));
      await tester.pumpAndSettle();
      await pasteFen(tester, fen);
      await scrollTap(tester, find.text('Gioca da qui'));
    }

    testWidgets('dopo l\'editor si sceglie come giocare la posizione', (
      tester,
    ) async {
      await editPosition(tester);
      expect(find.text('Gioca questa posizione'), findsOneWidget);
      expect(find.text('Computer'), findsOneWidget);
      expect(find.text('Bot'), findsOneWidget);
    });

    testWidgets('contro il computer col Nero muove prima il giocatore', (
      tester,
    ) async {
      await editPosition(tester);
      await scrollTap(tester, find.text('Computer'));
      await scrollTap(tester, find.text('Nero'));
      await scrollTap(tester, find.widgetWithText(FilledButton, 'Gioca'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.textContaining('Computer, livello 3'), findsOneWidget);
      expect(find.text('Scacco al Nero. Muove il Nero.'), findsOneWidget);
      expect(
        tester.widget<Chessboard>(find.byType(Chessboard)).orientation,
        Side.black,
      );
    });

    testWidgets('contro il computer col Bianco muove prima il computer', (
      tester,
    ) async {
      await editPosition(tester);
      await scrollTap(tester, find.text('Computer'));
      await scrollTap(tester, find.text('Bianco'));
      await scrollTap(tester, find.widgetWithText(FilledButton, 'Gioca'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.textContaining('Computer, livello 3'), findsOneWidget);
      expect(find.text('Muove il Bianco.'), findsOneWidget);
    });

    testWidgets('si può giocare la posizione anche contro un bot', (
      tester,
    ) async {
      await editPosition(tester);
      await scrollTap(tester, find.text('Bot'));
      await scrollTap(tester, find.text('Nero'));
      await scrollTap(tester, find.widgetWithText(FilledButton, 'Gioca'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.textContaining('Pino'), findsWidgets);
      expect(find.text('Scacco al Nero. Muove il Nero.'), findsOneWidget);
    });

    testWidgets('chiudere la scelta lascia la partita com\'era', (
      tester,
    ) async {
      await editPosition(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Gioca questa posizione'), findsNothing);
      expect(find.text('Muove il Bianco.'), findsOneWidget);
    });

    testWidgets('una posizione creata non conta per la collezione dei bot', (
      tester,
    ) async {
      final store = MemoryStore();
      await editPosition(
        tester,
        store: store,
        fen: 'r5k1/5ppp/8/8/8/8/5PPP/6K1 b - - 0 1',
      );
      await scrollTap(tester, find.text('Bot'));
      await scrollTap(tester, find.text('Nero'));
      await scrollTap(tester, find.widgetWithText(FilledButton, 'Gioca'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final rect = tester.getRect(find.byType(Chessboard));
      final size = rect.width / 8;
      Offset at(String sq) =>
          rect.topLeft +
          Offset(
            (7 - (sq.codeUnitAt(0) - 97) + 0.5) * size,
            (int.parse(sq[1]) - 1 + 0.5) * size,
          );
      await tester.tapAt(at('a8'));
      await tester.pump();
      await tester.tapAt(at('a1'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Scacco matto. Vince il Nero.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        bots.first
            .phrases(BotEvent.loss)
            .any((p) => find.textContaining(p).evaluate().isNotEmpty),
        isTrue,
      );
      final collection = await BotCollection.load(store);
      expect(collection.isBeaten(bots.first), isFalse);
      expect((await AdaptiveOpponent.load(store)).games, 0);
    });

    testWidgets('chiudere la scelta non ferma l\'orologio della partita', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('it'),
          home: GamePage(
            settings: SettingsController.defaults(),
            computerAvailable: true,
            store: MemoryStore(),
            now: () => TestWidgetsFlutterBinding.instance.clock.now(),
            createComputer: () =>
                ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await startComputerGame(tester, side: 'Bianco', time: '3+2');
      await tester.pump(const Duration(seconds: 1));
      final rect = tester.getRect(find.byType(Chessboard));
      final size = rect.width / 8;
      Offset at(String sq) =>
          rect.topLeft +
          Offset(
            (sq.codeUnitAt(0) - 97 + 0.5) * size,
            (7 - (int.parse(sq[1]) - 1) + 0.5) * size,
          );
      await tester.tapAt(at('e2'));
      await tester.pump();
      await tester.tapAt(at('e4'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Editor di posizione'));
      await tester.pumpAndSettle();
      await pasteFen(tester, checkFen);
      await scrollTap(tester, find.text('Gioca da qui'));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      String white() =>
          tester.widget<Text>(find.byKey(const ValueKey('clock-white'))).data!;
      final before = white();
      await tester.pump(const Duration(seconds: 5));
      expect(white(), isNot(before));
    });
  });
}
