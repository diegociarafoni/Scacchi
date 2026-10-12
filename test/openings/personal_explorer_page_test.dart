import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/game_archive.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/openings/explorer_page.dart';
import 'package:scacchi/openings/opening_book.dart';
import 'package:scacchi/openings/personal_explorer_page.dart';

import '../localized_app.dart';

final book = OpeningBook.parseTsv(
  'eco\tname\tuci\n'
  'B20\tSicilian Defense\te2e4 c7c5\n',
);

final _t = DateTime(2026, 10, 10);

SavedGame game(
  String id,
  String moves,
  String result, {
  Side side = Side.white,
  String opponent = 'Bot',
}) => SavedGame(
  id: id,
  createdAt: _t,
  updatedAt: _t,
  white: side == Side.white ? 'Io' : opponent,
  black: side == Side.white ? opponent : 'Io',
  mode: SavedGame.computer,
  result: result,
  pgn: '$moves $result',
  playerSide: side,
);

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  late Directory dir;
  late GameArchive archive;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('personal');
    archive = GameArchive(File('${dir.path}/games.json'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    List<SavedGame> games = const [],
    List<Move> initialMoves = const [],
    Locale locale = const Locale('it'),
  }) async {
    await tester.runAsync(() async {
      for (final g in games) {
        await archive.save(g);
      }
    });
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        locale: locale,
        home: PersonalExplorerPage(
          archive: Future.value(archive),
          book: Future.value(book),
          initialMoves: initialMoves,
        ),
      ),
    );
    await settle(tester);
  }

  final sample = [
    game('1', '1. e4 c5', '1-0'),
    game('2', '1. e4 c5', '0-1', opponent: 'Anna'),
    game('3', '1. e4 e5', '1/2-1/2', opponent: 'Anna'),
    game('4', '1. d4 d5', '1-0', side: Side.black, opponent: 'Zeno'),
  ];

  testWidgets('RF-96 senza partite invita a giocare', (tester) async {
    await show(tester);
    expect(find.textContaining('Gioca qualche partita'), findsOneWidget);
  });

  testWidgets('RF-96 mostra le mosse giocate con numero e risultati', (
    tester,
  ) async {
    await show(tester, games: sample);
    expect(find.text('e4'), findsOneWidget);
    expect(find.text('3 partite'), findsOneWidget);
    expect(find.text('1V · 1P · 1S'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.properties.label == '1 vinte, 1 patte, 1 perse',
      ),
      findsOneWidget,
    );
    expect(find.text('4 partite considerate'), findsOneWidget);
  });

  testWidgets('RF-96 si scende nell\'albero e compare il nome dell\'apertura', (
    tester,
  ) async {
    await show(tester, games: sample);
    await tester.tap(find.text('e4'));
    await settle(tester);
    expect(find.text('c5'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);
    await tester.tap(find.text('c5'));
    await settle(tester);
    expect(
      tester.widget<Text>(find.byKey(const Key('personal-opening'))).data,
      'B20 Difesa siciliana',
    );
    expect(find.text('Non hai mai giocato da questa posizione.'), findsOne);
    await tester.tap(find.text('Indietro'));
    await settle(tester);
    expect(find.text('e5'), findsOneWidget);
    await tester.tap(find.text('Inizio'));
    await settle(tester);
    expect(find.text('d4'), findsOneWidget);
  });

  testWidgets('RF-96 il filtro per colore restringe le partite', (
    tester,
  ) async {
    await show(tester, games: sample);
    await tester.tap(find.text('Nero'));
    await settle(tester);
    expect(find.text('d4'), findsOneWidget);
    expect(find.text('e4'), findsNothing);
    expect(find.text('1 partita considerata'), findsOneWidget);
  });

  testWidgets('RF-96 il filtro per avversario restringe le partite', (
    tester,
  ) async {
    await show(tester, games: sample);
    await tester.tap(find.byKey(const Key('personal-opponent')));
    await settle(tester);
    await tester.tap(find.text('Anna').last);
    await settle(tester);
    expect(find.text('2 partite'), findsOneWidget);
    expect(find.text('d4'), findsNothing);
    expect(find.text('2 partite considerate'), findsOneWidget);
  });

  testWidgets('RF-96 filtri senza partite lo dicono', (tester) async {
    await show(tester, games: [game('1', '1. e4 e5', '1-0')]);
    await tester.tap(find.text('Nero'));
    await settle(tester);
    expect(find.text('Nessuna partita con questi filtri.'), findsOneWidget);
  });

  testWidgets('RF-96 le mosse iniziali partono dalla posizione indicata', (
    tester,
  ) async {
    await show(tester, games: sample, initialMoves: [Move.parse('e2e4')!]);
    expect(find.text('1. e4'), findsOneWidget);
    expect(find.text('c5'), findsOneWidget);
  });

  testWidgets('RF-96 si apre l\'explorer delle aperture nella stessa '
      'posizione', (tester) async {
    await show(tester, games: sample, initialMoves: [Move.parse('e2e4')!]);
    await tester.tap(find.byTooltip('Apri nell\'explorer delle aperture'));
    await settle(tester);
    expect(find.text('Esplora aperture'), findsOneWidget);
    expect(find.text('1. e4'), findsOneWidget);
  });

  testWidgets('RF-96 dall\'explorer si aprono le proprie partite da lì', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final g in sample) {
        await archive.save(g);
      }
    });
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        home: ExplorerPage(
          book: Future.value(book),
          initialMoves: [Move.parse('e2e4')!],
          archive: () => Future.value(archive),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Le tue partite da questa posizione'));
    await settle(tester);
    expect(find.text('Le tue aperture'), findsOneWidget);
    expect(find.text('1. e4'), findsOneWidget);
    expect(find.text('c5'), findsOneWidget);
  });

  testWidgets('RF-96 senza archivio l\'explorer non propone le proprie '
      'partite', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(home: ExplorerPage(book: Future.value(book))),
    );
    await settle(tester);
    expect(find.byTooltip('Le tue partite da questa posizione'), findsNothing);
  });

  testWidgets('RF-96 un archivio illeggibile non lascia la rotella', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final failing = Future<GameArchive>.error(const FileSystemException('x'))
      ..ignore();
    await tester.pumpWidget(
      localizedApp(home: PersonalExplorerPage(archive: failing)),
    );
    await settle(tester);
    expect(find.textContaining('non si è potuto leggere'), findsOneWidget);
  });

  testWidgets('RF-96 i testi esistono anche in inglese', (tester) async {
    await show(tester, games: sample, locale: const Locale('en'));
    expect(find.text('Your openings'), findsOneWidget);
    expect(find.text('3 games'), findsOneWidget);
    expect(find.text('1W · 1D · 1L'), findsOneWidget);
  });
}
