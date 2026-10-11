import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/physical/physical_game_page.dart';

void main() {
  late Directory dir;
  late GameArchive archive;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('fisica');
    archive = GameArchive(File('${dir.path}/games.json'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PhysicalGamePage(archive: () async => archive)),
    );
    await tester.tap(find.text('Senza tempo'));
    await tester.tap(find.text('Inizia la partita'));
    await tester.pump();
  }

  Future<void> type(WidgetTester tester, String move) async {
    await tester.enterText(find.byKey(const Key('physical-input')), move);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  testWidgets('le mosse scritte compaiono nel registro', (tester) async {
    await open(tester);
    await type(tester, 'e4');
    await type(tester, 'Cc6');
    expect(
      tester.widget<Text>(find.byKey(const Key('physical-moves'))).data,
      '1. e4 Nc6',
    );
  });

  testWidgets('una mossa non valida mostra un avviso e non cambia nulla', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'e5');
    expect(find.textContaining('Mossa non valida'), findsOneWidget);
    expect(find.text('Nessuna mossa'), findsOneWidget);
  });

  testWidgets('toccare un suggerimento gioca la mossa', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('physical-input')), 'Nf');
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'Nf3'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('physical-moves'))).data,
      '1. Nf3',
    );
  });

  testWidgets('con l\'orologio parte quello del bianco', (tester) async {
    final fixed = DateTime(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: PhysicalGamePage(archive: () async => archive, now: () => fixed),
      ),
    );
    await tester.tap(find.text('3+2'));
    await tester.tap(find.text('Inizia la partita'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('physical-clock-white'))).data,
      '3:00',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a partita finita viene salvata nell\'archivio', (tester) async {
    await open(tester);
    await type(tester, 'e4');
    await tester.tap(find.text('Abbandona'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nero').last);
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.byKey(const Key('physical-result')), findsOneWidget);
    expect(find.textContaining('salvata'), findsOneWidget);
    final games = (await tester.runAsync(archive.list))!;
    expect(games, hasLength(1));
    expect(games.single.mode, SavedGame.physical);
    expect(games.single.result, '1-0');
  });
}
