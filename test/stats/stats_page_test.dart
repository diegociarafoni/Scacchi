import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/archive/saved_game.dart';
import 'package:rokko/stats/stats_page.dart';

import '../localized_app.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  late Directory dir;
  late GameArchive archive;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('stats');
    archive = GameArchive(File('${dir.path}/games.json'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    Locale locale = const Locale('it'),
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: StatsPage(archive: archive),
        locale: locale,
      ),
    );
    await settle(tester);
  }

  testWidgets('senza partite invita a giocare', (tester) async {
    await show(tester);
    expect(find.textContaining('Gioca qualche partita'), findsOneWidget);
  });

  testWidgets('RF-110 RF-111 rating, bilancio, colori e aperture', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final (i, r) in ['1-0', '0-1', '1/2-1/2'].indexed) {
        await archive.save(
          SavedGame(
            id: '$i',
            createdAt: DateTime(2026, 10, i + 1),
            updatedAt: DateTime(2026, 10, i + 1),
            white: 'Io',
            black: 'Bot',
            mode: 'computer',
            result: r,
            pgn: '',
            playerSide: Side.white,
            timeControl: '5+0',
            opponentElo: 1000,
            accuracy: 70.0 + i,
            opening: 'Italian Game: Evans Gambit',
          ),
        );
      }
    });
    await show(tester);
    expect(find.textContaining('Rating stimato'), findsOneWidget);
    expect(find.textContaining('provvisorio'), findsOneWidget);
    expect(find.text('+1 =1 -1'), findsWidgets);
    // Le partite salvano il nome inglese del libro; si mostra in italiano.
    await tester.scrollUntilVisible(
      find.text('Partita italiana: gambetto Evans'),
      200,
    );
    expect(find.text('Partita italiana: gambetto Evans'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('71.0%'), 200);
    expect(find.textContaining('71.0%'), findsOneWidget);
  });

  testWidgets('la cadenza senza orologio segue la lingua', (tester) async {
    await tester.runAsync(
      () => archive.save(
        SavedGame(
          id: 'n',
          createdAt: DateTime(2026, 10),
          updatedAt: DateTime(2026, 10),
          white: 'Io',
          black: 'Bot',
          mode: 'computer',
          result: '1-0',
          pgn: '',
          playerSide: Side.white,
        ),
      ),
    );
    await show(tester, locale: const Locale('en'));
    await tester.scrollUntilVisible(find.text('No clock'), 200);
    expect(find.text('No clock'), findsOneWidget);
    expect(find.text('Senza tempo'), findsNothing);
  });

  testWidgets('solo partite tra due persone: mostra il conteggio', (
    tester,
  ) async {
    await tester.runAsync(
      () => archive.save(
        SavedGame(
          id: 'l',
          createdAt: DateTime(2026, 10),
          updatedAt: DateTime(2026, 10),
          white: 'A',
          black: 'B',
          mode: SavedGame.local,
          result: '1-0',
          pgn: '',
        ),
      ),
    );
    await show(tester);
    expect(find.text('Partite tra due persone'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('archivio illeggibile: messaggio invece dell\'attesa', (
    tester,
  ) async {
    archive = _UnreadableArchive(File('${dir.path}/games.json'));
    await show(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('non si è potuto leggere'), findsOneWidget);
  });
}

class _UnreadableArchive extends GameArchive {
  _UnreadableArchive(super.file);

  @override
  Future<List<SavedGame>> list() =>
      Future.error(const FileSystemException('lettura non riuscita'));
}
