import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late Directory dir;
  late File file;
  final t0 = DateTime(2026, 10, 10, 9);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('archive');
    file = File('${dir.path}/games.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  SavedGame saved(String id, List<String> moves, {DateTime? at}) =>
      SavedGame.fromGame(
        play(moves),
        id: id,
        white: 'Anna',
        black: 'Bruno',
        mode: 'locale',
        createdAt: at ?? t0,
        updatedAt: at ?? t0,
      );

  test('archivio vuoto', () async {
    expect(await GameArchive(file).list(), isEmpty);
    expect(await GameArchive(file).unfinished(), isNull);
  });

  test('RF-100 salva, aggiorna e ricarica una partita', () async {
    final archive = GameArchive(file);
    await archive.save(saved('a', ['e2e4']));
    await archive.save(saved('a', ['e2e4', 'e7e5']));
    final games = await GameArchive(file).list();
    expect(games, hasLength(1));
    expect(games.single.toGame().moves, hasLength(2));
    expect(games.single.white, 'Anna');
  });

  test('RF-100 ripresa della partita non finita più recente', () async {
    final archive = GameArchive(file);
    await archive.save(saved('vecchia', ['e2e4'], at: t0));
    await archive.save(
      saved('nuova', ['d2d4'], at: t0.add(const Duration(hours: 1))),
    );
    await archive.save(
      saved('finita', [
        'f2f3',
        'e7e5',
        'g2g4',
        'd8h4',
      ], at: t0.add(const Duration(hours: 2))),
    );
    final resume = await archive.unfinished();
    expect(resume?.id, 'nuova');
  });

  test('RF-101 storico dal più recente con risultato', () async {
    final archive = GameArchive(file);
    await archive.save(saved('1', ['e2e4'], at: t0));
    await archive.save(
      saved('2', [
        'f2f3',
        'e7e5',
        'g2g4',
        'd8h4',
      ], at: t0.add(const Duration(days: 1))),
    );
    final games = await archive.list();
    expect(games.map((g) => g.id), ['2', '1']);
    expect(games.first.result, '0-1');
    expect(games.last.result, '*');
    expect(games.first.finished, isTrue);
  });

  test('elimina una partita', () async {
    final archive = GameArchive(file);
    await archive.save(saved('a', ['e2e4']));
    await archive.delete('a');
    expect(await archive.list(), isEmpty);
  });

  test('RF-102 export dell\'intero archivio e import', () async {
    final archive = GameArchive(file);
    await archive.save(saved('a', ['e2e4']));
    await archive.save(saved('b', ['d2d4', 'd7d5']));
    final pgn = await archive.exportPgn();
    expect('[Event'.allMatches(pgn), hasLength(2));
    expect(pgn, contains('[Event "Rokko"]'));

    final other = GameArchive(File('${dir.path}/altro.json'));
    final result = await other.importPgn(pgn, now: t0);
    expect(result.games, hasLength(2));
    final games = await other.list();
    expect(games, hasLength(2));
    expect(games.map((g) => g.white), everyElement('Anna'));
    expect(games.map((g) => g.mode), everyElement('importata'));
  });

  test('l\'import conserva le intestazioni originali e l\'ordine', () async {
    final archive = GameArchive(file);
    const pgn = '''
[Event "Rated Blitz"]
[Date "2019.05.01"]
[White "Primo"]
[Black "B"]
[WhiteElo "1500"]

1. e4 *

[White "Secondo"]
[Black "B"]

1. d4 *

[White "Terzo"]
[Black "B"]

1. c4 *
''';
    await archive.importPgn(pgn, now: t0);
    final exported = await archive.exportPgn();
    expect(exported, contains('[Event "Rated Blitz"]'));
    expect(exported, contains('[Date "2019.05.01"]'));
    expect(exported, contains('[WhiteElo "1500"]'));
    expect(RegExp(r'\[White "(\w+)"\]').allMatches(exported).map((m) => m[1]), [
      'Primo',
      'Secondo',
      'Terzo',
    ]);
  });

  test('una partita importata in corso non è quella da riprendere', () async {
    final archive = GameArchive(file);
    await archive.save(saved('mia', ['e2e4'], at: t0));
    await archive.importPgn('1. d4 *', now: t0.add(const Duration(hours: 1)));
    expect((await archive.unfinished())?.id, 'mia');
  });

  test('letture e scritture contemporanee non perdono partite', () async {
    final archive = GameArchive(file);
    await Future.wait([
      archive.list(),
      archive.save(saved('a', ['e2e4'])),
      archive.list(),
      archive.save(saved('b', ['d2d4'])),
    ]);
    expect(await GameArchive(file).list(), hasLength(2));
  });

  test('una voce non valida mette da parte il file', () async {
    file.writeAsStringSync('{"version":1,"games":[{"id":"a"}]}');
    expect(await GameArchive(file).list(), isEmpty);
    expect(dir.listSync().where((f) => f.path.contains('.bad')), hasLength(1));
  });

  test('un file illeggibile viene conservato a parte', () async {
    file.writeAsStringSync('rotto');
    expect(await GameArchive(file).list(), isEmpty);
    expect(dir.listSync().where((f) => f.path.contains('.bad')), hasLength(1));
  });
}
