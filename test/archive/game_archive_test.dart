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

    final other = GameArchive(File('${dir.path}/altro.json'));
    final result = await other.importPgn(pgn, now: t0);
    expect(result.games, hasLength(2));
    final games = await other.list();
    expect(games, hasLength(2));
    expect(games.map((g) => g.white), everyElement('Anna'));
    expect(games.map((g) => g.mode), everyElement('importata'));
  });

  test('un file illeggibile viene conservato a parte', () async {
    file.writeAsStringSync('rotto');
    expect(await GameArchive(file).list(), isEmpty);
    expect(dir.listSync().where((f) => f.path.contains('.bad')), hasLength(1));
  });
}
