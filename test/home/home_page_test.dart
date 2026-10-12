import 'dart:io';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/home/home_page.dart';
import 'package:scacchi/path/path_controller.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';
import 'package:scacchi/story/story_controller.dart';

import '../localized_app.dart';

SavedGame saved(
  String id,
  String opponent, {
  String result = '1-0',
  double? accuracy,
  int day = 1,
}) => SavedGame(
  id: id,
  createdAt: DateTime(2026, 1, day),
  updatedAt: DateTime(2026, 1, day),
  white: 'Tu',
  black: opponent,
  mode: SavedGame.computer,
  result: result,
  pgn: '1. e4 *',
  playerSide: Side.white,
  opponentElo: 800,
  accuracy: accuracy,
);

void main() {
  late Directory dir;
  late ProgressController progress;
  final calls = <String>[];

  setUp(() async {
    calls.clear();
    dir = Directory.systemTemp.createTempSync('home_page');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Map<String, HomeAction> features(Iterable<String> ids) => {
    for (final id in ids)
      id: () async {
        calls.add(id);
      },
  };

  const allIds = [
    'bots',
    'friend',
    'tournaments',
    'physical',
    'story',
    'openings',
    'endgames',
    'masters',
    'daily',
    'puzzles',
    'minigames',
    'stats',
    'badges',
    'archive',
    'week',
    'profile',
  ];

  Future<void> show(
    WidgetTester tester, {
    List<SavedGame> games = const [],
    Iterable<String> ids = allIds,
    bool simple = false,
    bool story = true,
    bool engine = true,
    double textScale = 1,
    Size size = const Size(393, 852),
  }) async {
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: HomePage(
            progress: () async => progress,
            path: () async => PathController(File('${dir.path}/path.json')),
            story: () async => StoryController(File('${dir.path}/story.json')),
            games: () async => games,
            collection: () async => const BotCollection(),
            features: features(ids),
            simple: simple,
            onNewGame: () async {
              calls.add('new');
            },
            onSettings: () async {
              calls.add('settings');
            },
            onResume: (g) async {
              calls.add('resume:${g.id}');
            },
            onOpenGame: (g) async {
              calls.add('open:${g.id}');
            },
            onPlayBot: engine
                ? (b) async {
                    calls.add('bot:${b.id}');
                  }
                : null,
            onContinueStory: story
                ? (s) async {
                    calls.add('story');
                  }
                : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('in cima propone la prossima lezione della Storia', (
    tester,
  ) async {
    await show(tester);
    expect(find.byKey(const Key('home-hero-story')), findsOneWidget);
    expect(find.text('Continua la Storia'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-hero-story')));
    await tester.pumpAndSettle();
    expect(calls, ['story']);
  });

  testWidgets('una partita lasciata a metà ha la precedenza', (tester) async {
    await show(tester, games: [saved('a', 'Pino', result: '*')]);
    expect(find.byKey(const Key('home-hero-resume')), findsOneWidget);
    expect(find.text('Contro Pino'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-hero-resume')));
    await tester.pumpAndSettle();
    expect(calls, ['resume:a']);
  });

  testWidgets('senza Storia propone il puzzle del giorno', (tester) async {
    await show(tester, story: false);
    expect(find.byKey(const Key('home-hero-daily')), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-hero-daily')));
    await tester.pumpAndSettle();
    expect(calls, ['daily']);
  });

  testWidgets('ogni funzione è a un tocco dalla Home', (tester) async {
    await show(tester, size: const Size(393, 3000));
    for (final id in allIds.where((id) => id != 'profile')) {
      final tile = find.byKey(Key('home-feature-$id'));
      expect(tile, findsOneWidget, reason: id);
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }
    expect(calls, allIds.where((id) => id != 'profile'));
  });

  testWidgets('l\'avatar in alto porta al profilo', (tester) async {
    await show(tester);
    await tester.tap(find.byKey(const Key('home-profile')));
    await tester.pumpAndSettle();
    expect(calls, ['profile']);
  });

  testWidgets('le funzioni non disponibili non compaiono', (tester) async {
    await show(
      tester,
      ids: allIds.where((id) => id != 'tournaments' && id != 'endgames'),
    );
    expect(find.byKey(const Key('home-feature-tournaments')), findsNothing);
    expect(find.byKey(const Key('home-feature-endgames')), findsNothing);
    expect(find.byKey(const Key('home-feature-story')), findsOneWidget);
  });

  testWidgets('la ricerca filtra le funzioni e si può svuotare', (
    tester,
  ) async {
    await show(tester);
    await tester.enterText(find.byKey(const Key('home-search')), 'finali');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-feature-endgames')), findsOneWidget);
    expect(find.byKey(const Key('home-feature-badges')), findsNothing);
    expect(find.byKey(const Key('home-hero-story')), findsNothing);

    await tester.enterText(find.byKey(const Key('home-search')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nessuna funzione con questo nome'), findsOneWidget);

    await tester.tap(find.byTooltip('Cancella la ricerca'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-hero-story')), findsOneWidget);
  });

  testWidgets('il bot consigliato è alla portata e si gioca con un tocco', (
    tester,
  ) async {
    await show(tester);
    expect(find.byKey(const Key('home-recommended')), findsOneWidget);
    expect(find.text(bots.first.name), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-recommended')));
    await tester.pumpAndSettle();
    expect(calls, ['bot:${bots.first.id}']);
  });

  testWidgets('senza motore il bot consigliato non compare', (tester) async {
    await show(tester, engine: false);
    expect(find.byKey(const Key('home-recommended')), findsNothing);
  });

  testWidgets('le ultime partite mostrano l\'avversario e la precisione', (
    tester,
  ) async {
    await show(
      tester,
      size: const Size(393, 3000),
      games: [
        saved('a', 'Pino', accuracy: 81.4, day: 3),
        saved('b', 'Chiara', result: '0-1', day: 2),
      ],
    );
    expect(find.text('Ultime partite'), findsOneWidget);
    expect(find.text('81,4'), findsOneWidget);
    expect(find.text('Chiara'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Vittoria contro Pino, precisione 81,4'),
      findsOneWidget,
    );
    await tester.tap(find.text('Chiara'));
    await tester.pumpAndSettle();
    expect(calls, ['open:b']);
  });

  testWidgets('senza partite lo dice', (tester) async {
    await show(tester, size: const Size(393, 3000));
    expect(find.text('Le partite concluse compaiono qui.'), findsOneWidget);
  });

  testWidgets('il grande pulsante apre «Nuova partita»', (tester) async {
    await show(tester);
    await tester.tap(find.byKey(const Key('home-play')));
    await tester.pumpAndSettle();
    expect(calls, ['new']);
  });

  testWidgets('le impostazioni sono un tocco in alto', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();
    expect(calls, ['settings']);
  });

  testWidgets('profilo bambino: senza numeri né ricerca', (tester) async {
    await show(
      tester,
      simple: true,
      ids: const [
        'story',
        'masters',
        'daily',
        'puzzles',
        'minigames',
        'profile',
      ],
      size: const Size(393, 3000),
    );
    expect(find.byKey(const Key('home-search')), findsNothing);
    expect(find.text('Statistiche'), findsNothing);
    expect(find.text('Ultime partite'), findsNothing);
    expect(find.textContaining('Elo'), findsNothing);
    expect(find.text('Giochiamo!'), findsOneWidget);
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('testo al ${scale * 100}% senza overflow', (tester) async {
      await show(
        tester,
        textScale: scale,
        size: const Size(360, 3000),
        games: [saved('a', 'Pino', accuracy: 81.4)],
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('accessibilità: bersagli da 48 dp ed etichette', (tester) async {
    final handle = tester.ensureSemantics();
    await show(tester, games: [saved('a', 'Pino', accuracy: 81.4)]);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
