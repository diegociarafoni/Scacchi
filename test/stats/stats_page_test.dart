import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/stats/stats_page.dart';

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

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: StatsPage(archive: archive)));
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
            opening: 'Partita Italiana',
          ),
        );
      }
    });
    await show(tester);
    expect(find.textContaining('Rating stimato'), findsOneWidget);
    expect(find.textContaining('provvisorio'), findsOneWidget);
    expect(find.text('+1 =1 -1'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Partita Italiana'), 200);
    expect(find.text('Partita Italiana'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('71.0%'), 200);
    expect(find.textContaining('71.0%'), findsOneWidget);
  });
}
