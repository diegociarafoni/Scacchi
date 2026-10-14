import 'dart:io';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/archive/saved_game.dart';
import 'package:rokko/stats/portrait_page.dart';

import '../localized_app.dart';

void main() {
  final now = DateTime(2026, 10, 11, 12);
  late Directory dir;
  late GameArchive archive;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ritratto');
    archive = GameArchive(File('${dir.path}/games.json'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  SavedGame game(String result, {String? opening}) => SavedGame(
    id: 'g$result$opening',
    createdAt: now.subtract(const Duration(days: 1)),
    updatedAt: now,
    white: 'Tu',
    black: 'Computer',
    mode: SavedGame.computer,
    result: result,
    pgn: '[Result "$result"]\n\n1. f3 e5 2. g4 Qh4# 0-1',
    playerSide: Side.black,
    opening: opening,
    opponentElo: 1200,
  );

  Future<void> open(
    WidgetTester tester, {
    List<SavedGame> games = const [],
    ShareImage? share,
  }) async {
    await tester.runAsync(() async {
      for (final g in games) {
        await archive.save(g);
      }
    });
    await tester.pumpWidget(
      localizedApp(
        home: PortraitPage(
          archive: archive,
          now: () => now,
          share: share ?? (_, _) async {},
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets('senza partite spiega come riempire il riepilogo', (
    tester,
  ) async {
    await open(tester);
    expect(find.textContaining('Nessuna partita'), findsOneWidget);
  });

  testWidgets('mostra risultati, matto preferito e avversario battuto', (
    tester,
  ) async {
    await open(
      tester,
      games: [
        game('0-1', opening: 'Gambetto di re'),
        game('1-0'),
      ],
    );
    expect(find.text('2 partite'), findsOneWidget);
    expect(find.text('1 vinte · 0 patte · 1 perse'), findsOneWidget);
    expect(find.text('con la donna, 1 volta'), findsOneWidget);
    expect(find.text('Elo 1200'), findsOneWidget);
    expect(find.text('Gambetto di re (1)'), findsOneWidget);
    expect(find.text('sabato'), findsOneWidget);
  });

  testWidgets('la condivisione produce un\'immagine PNG', (tester) async {
    Uint8List? png;
    String? name;
    await open(
      tester,
      games: [game('0-1')],
      share: (bytes, fileName) async {
        png = bytes;
        name = fileName;
      },
    );
    await tester.tap(find.text('Condividi come immagine'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(png, isNotNull);
    // Firma dei file PNG.
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4e, 0x47]);
    expect(name, 'rokko-settimana-2026-10-11.png');
  });
}
