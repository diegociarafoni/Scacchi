import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/computer_player.dart';
import 'package:scacchi/editor/position_editor_page.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/settings/settings.dart';

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
      MaterialApp(home: GamePage(settings: SettingsController.defaults())),
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
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('Computer, livello'), findsNothing);
    expect(find.text('Scacco al Nero. Muove il Nero.'), findsOneWidget);
    expect(
      tester.widget<Chessboard>(find.byType(Chessboard)).orientation,
      Side.white,
    );
  });
}
