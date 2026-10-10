import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/archive_page.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/game/chess_game.dart';

ChessGame play(List<String> uci) {
  final game = ChessGame();
  for (final m in uci) {
    game.play(Move.parse(m)!);
  }
  return game;
}

/// Lascia completare l'I/O reale su file, che i test di widget non simulano.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  late Directory dir;
  late GameArchive archive;
  final shared = <String>[];
  final opened = <String>[];

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('archive_page');
    archive = GameArchive(File('${dir.path}/games.json'));
    shared.clear();
    opened.clear();
    final t = DateTime(2026, 10, 10, 9);
    await archive.save(
      SavedGame.fromGame(
        play(['f2f3', 'e7e5', 'g2g4', 'd8h4']),
        id: 'matto',
        white: 'Anna',
        black: 'Bruno',
        mode: 'locale',
        createdAt: t,
        updatedAt: t,
      ),
    );
    await archive.save(
      SavedGame.fromGame(
        play(['e2e4']),
        id: 'corso',
        white: 'Carla',
        black: 'Dario',
        mode: 'locale',
        createdAt: t,
        updatedAt: t.add(const Duration(hours: 1)),
      ),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ArchivePage(
          archive: archive,
          share: (text) async => shared.add(text),
          onOpen: (g) => opened.add(g.id),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('RF-101 storico con giocatori e risultato', (tester) async {
    await show(tester);
    expect(find.text('Carla – Dario'), findsOneWidget);
    expect(find.text('Anna – Bruno'), findsOneWidget);
    expect(find.textContaining('0-1'), findsOneWidget);
    expect(find.textContaining('In corso'), findsOneWidget);
  });

  testWidgets('RF-101 ricerca per nome', (tester) async {
    await show(tester);
    await tester.enterText(find.byType(TextField), 'anna');
    await tester.pumpAndSettle();
    expect(find.text('Anna – Bruno'), findsOneWidget);
    expect(find.text('Carla – Dario'), findsNothing);
  });

  testWidgets('apre una partita', (tester) async {
    await show(tester);
    await tester.tap(find.text('Anna – Bruno'));
    expect(opened, ['matto']);
  });

  testWidgets('RF-102 condivide il PGN di una partita', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Azioni per Anna – Bruno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Condividi PGN'));
    await tester.pumpAndSettle();
    expect(shared.single, contains('1. f3 e5 2. g4 Qh4# 0-1'));
  });

  testWidgets('RF-102 esporta tutto l\'archivio', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Esporta tutto in PGN'));
    await settle(tester);
    expect('[Event'.allMatches(shared.single), hasLength(2));
  });

  testWidgets('RF-102 importa un PGN incollato', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Importa PGN'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pgnInput')),
      '[White "Elena"]\n[Black "Franco"]\n\n1. d4 d5 *',
    );
    await tester.tap(find.text('Importa'));
    await settle(tester);
    expect(find.text('Elena – Franco'), findsOneWidget);
    expect(find.text('1 partita importata'), findsOneWidget);
  });

  testWidgets('elimina una partita dopo conferma', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Azioni per Anna – Bruno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
    await settle(tester);
    expect(find.text('Anna – Bruno'), findsNothing);
  });

  testWidgets('copia il PGN negli appunti', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await show(tester);
    await tester.tap(find.byTooltip('Azioni per Anna – Bruno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copia PGN'));
    await tester.pumpAndSettle();
    expect(copied, contains('Qh4#'));
  });
}
