import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/review/game_phase.dart';
import 'package:scacchi/review/game_review.dart';
import 'package:scacchi/stats/stats.dart';
import 'package:scacchi/stats/stats_page.dart';

import '../localized_app.dart';
import '../review/fake_engine.dart';

SavedGame game(
  int day, {
  Map<GamePhase, double>? phases,
  double? accuracy,
  Side? side = Side.white,
  String mode = 'computer',
}) => SavedGame(
  id: 'g$day',
  createdAt: DateTime(2026, 10, day),
  updatedAt: DateTime(2026, 10, day),
  white: 'Io',
  black: 'Bot',
  mode: mode,
  result: '1-0',
  pgn: '',
  playerSide: side,
  accuracy: accuracy,
  phaseAccuracy: phases,
);

void main() {
  group('RF-68 precisione per fase nelle statistiche', () {
    test('la partita salva e rilegge la precisione per fase', () {
      final g = game(
        1,
        accuracy: 80,
        phases: {GamePhase.opening: 90, GamePhase.endgame: 60.5},
      );
      final back = SavedGame.fromJson(g.toJson());
      expect(back.phaseAccuracy, {
        GamePhase.opening: 90.0,
        GamePhase.endgame: 60.5,
      });
      expect(SavedGame.fromJson(game(2).toJson()).phaseAccuracy, isNull);
    });

    test('una fase sconosciuta nel file si ignora', () {
      final json = game(1, phases: {GamePhase.opening: 70}).toJson();
      (json['phaseAccuracy']! as Map)['quarta'] = 50.0;
      expect(SavedGame.fromJson(json).phaseAccuracy, {GamePhase.opening: 70.0});
    });

    test(
      'la revisione di una partita aggiorna precisione e fasi di chi gioca',
      () async {
        final review = (await reviewGame(
          initial: Chess.initial,
          moves: moves(scholar),
          evaluate: fakeEngine(scholar, overrides: scholarOverrides),
        ))!;
        final saved = game(1).withReview(review);
        expect(saved.accuracy, review.accuracy(Side.white));
        expect(
          saved.phaseAccuracy![GamePhase.opening],
          review.accuracyByPhase(Side.white)[GamePhase.opening],
        );
        // Senza colore (due persone) la precisione non è di nessuno.
        expect(game(2, side: null).withReview(review).accuracy, isNull);
      },
    );

    test('media e andamento per fase, dalle sole partite con il dato', () {
      final stats = GameStats.from([
        game(3, phases: {GamePhase.opening: 90, GamePhase.endgame: 50}),
        game(1, phases: {GamePhase.opening: 70}),
        game(2),
        game(4, side: null, mode: 'locale', phases: {GamePhase.opening: 10}),
      ]);
      expect(stats.phaseAverage(GamePhase.opening), 80);
      expect(stats.phaseAverage(GamePhase.endgame), 50);
      expect(stats.phaseAverage(GamePhase.middlegame), isNull);
      expect(
        [for (final p in stats.phaseTrend(GamePhase.opening)) p.$2],
        [70, 90],
      );
    });
  });

  group('RF-68 schermata statistiche', () {
    late Directory dir;
    late GameArchive archive;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('fasi');
      archive = GameArchive(File('${dir.path}/games.json'));
    });
    tearDown(() => dir.deleteSync(recursive: true));

    testWidgets('mostra la media di ogni fase', (tester) async {
      await tester.runAsync(() async {
        await archive.save(
          game(
            1,
            accuracy: 80,
            phases: {
              GamePhase.opening: 90,
              GamePhase.middlegame: 70,
              GamePhase.endgame: 60,
            },
          ),
        );
        await archive.save(
          game(2, accuracy: 70, phases: {GamePhase.opening: 80}),
        );
      });
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(localizedApp(home: StatsPage(archive: archive)));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(find.text('Precisione per fase'), 200);
      expect(find.text('Precisione per fase'), findsOneWidget);
      expect(find.text('Apertura'), findsOneWidget);
      expect(find.text('85.0%'), findsOneWidget);
      expect(find.text('Mediogioco'), findsOneWidget);
      expect(find.text('70.0%'), findsOneWidget);
      expect(find.text('Finale'), findsOneWidget);
    });

    testWidgets('senza dati per fase la sezione non compare', (tester) async {
      await tester.runAsync(() => archive.save(game(1, accuracy: 80)));
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(localizedApp(home: StatsPage(archive: archive)));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('Precisione per fase'), findsNothing);
    });
  });
}
