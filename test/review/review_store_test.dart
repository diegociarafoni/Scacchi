import 'dart:convert';
import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart' show LinearProgressIndicator, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/review/engine_evaluator.dart';
import 'package:scacchi/review/game_review.dart';
import 'package:scacchi/review/review_page.dart';
import 'package:scacchi/review/review_store.dart';

import '../localized_app.dart';
import 'fake_engine.dart';

Future<GameReview> scholarReview() async => (await reviewGame(
  initial: Chess.initial,
  moves: moves(scholar),
  evaluate: fakeEngine(scholar, overrides: scholarOverrides),
))!;

void main() {
  late Directory dir;
  late File file;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('revisioni');
    file = File('${dir.path}/reviews.json');
    ReviewCache.clear();
    ReviewCache.store = null;
  });
  tearDown(() {
    ReviewCache.store = null;
    dir.deleteSync(recursive: true);
  });

  group('RF-66 cache persistente della revisione', () {
    test('una revisione sopravvive al riavvio, uguale in ogni campo', () async {
      final review = await scholarReview();
      final key = ReviewStore.key(Chess.initial, moves(scholar));
      await ReviewStore(file).put(key, review);
      final back = await ReviewStore(file).get(key);
      expect(jsonEncode(back!.toJson()), jsonEncode(review.toJson()));
      expect(back.moves.length, review.moves.length);
      expect(back.moves[5].classification, review.moves[5].classification);
      expect(back.accuracy(Side.white), review.accuracy(Side.white));
    });

    test('la chiave cambia con motore, profondità e uso del libro', () {
      final base = ReviewStore.key(Chess.initial, moves(scholar));
      expect(base, contains('stockfish'));
      expect(base, contains('d$reviewDepth'));
      expect(
        ReviewStore.key(Chess.initial, moves(scholar), depth: 20),
        isNot(base),
      );
      expect(
        ReviewStore.key(Chess.initial, moves(scholar), engine: 'x'),
        isNot(base),
      );
      expect(
        ReviewStore.key(Chess.initial, moves(scholar), book: true),
        isNot(base),
      );
      expect(
        ReviewStore.key(Chess.initial, moves(scholar.take(3).toList())),
        isNot(base),
      );
    });

    test('una revisione con un\'altra profondità non si ritrova', () async {
      final store = ReviewStore(file);
      await store.put(
        ReviewStore.key(Chess.initial, moves(scholar), depth: 10),
        await scholarReview(),
      );
      expect(
        await ReviewStore(file)
            .get(ReviewStore.key(Chess.initial, moves(scholar))),
        isNull,
      );
    });

    test('tiene solo le più recenti', () async {
      final review = await scholarReview();
      final store = ReviewStore(file, capacity: 3);
      for (var i = 0; i < 5; i++) {
        await store.put('k$i', review);
      }
      expect(await store.get('k0'), isNull);
      expect(await store.get('k1'), isNull);
      expect(await ReviewStore(file, capacity: 3).get('k4'), isNotNull);
      expect(await store.get('k2'), isNotNull);
    });

    test('una voce non valida si salta e le altre restano', () async {
      final store = ReviewStore(file);
      await store.put('buona', await scholarReview());
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      (json['reviews']! as Map)['rotta'] = {'moves': 3};
      file.writeAsStringSync(jsonEncode(json));
      final again = ReviewStore(file);
      expect(await again.get('rotta'), isNull);
      expect(await again.get('buona'), isNotNull);
    });

    test('rileggere una revisione la salva dall\'eliminazione', () async {
      final review = await scholarReview();
      final store = ReviewStore(file, capacity: 2);
      await store.put('a', review);
      await store.put('b', review);
      await store.get('a');
      await store.put('c', review);
      expect(await store.get('b'), isNull);
      expect(await store.get('a'), isNotNull);
    });

    test('un file illeggibile non blocca: si riparte vuoti', () async {
      file.writeAsStringSync('non è json');
      final store = ReviewStore(file);
      expect(await store.get('k'), isNull);
      await store.put('k', await scholarReview());
      expect(await ReviewStore(file).get('k'), isNotNull);
    });

    testWidgets('la revisione si apre dal disco senza interrogare il motore', (
      tester,
    ) async {
      final key = ReviewStore.key(Chess.initial, moves(scholar));
      final review = (await tester.runAsync(scholarReview))!;
      await tester.runAsync(() => ReviewStore(file).put(key, review));
      ReviewCache.store = ReviewStore(file);
      final fens = <String>[];
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localizedApp(
          home: ReviewPage(
            initial: Chess.initial,
            moves: moves(scholar),
            evaluate: (fen) async {
              fens.add(fen);
              return [
                const InfoLine(multipv: 1, pv: [], score: EngineScore.cp(0)),
              ];
            },
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(fens, isEmpty);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('f7'), findsWidgets);
    });

    testWidgets('una revisione appena fatta finisce sul disco', (tester) async {
      ReviewCache.store = ReviewStore(file);
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localizedApp(
          home: ReviewPage(
            initial: Chess.initial,
            moves: moves(scholar),
            evaluate: fakeEngine(scholar, overrides: scholarOverrides),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      final saved = await tester.runAsync(
        () =>
            ReviewStore(file)
                .get(ReviewStore.key(Chess.initial, moves(scholar))),
      );
      expect(saved, isNotNull);
    });
  });
}
