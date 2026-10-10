import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../storage/json_file.dart';
import 'pgn.dart' as pgn;
import 'saved_game.dart';

/// Archivio locale delle partite in un file JSON.
class GameArchive {
  GameArchive(File file) : _file = JsonFile(file, version: 1);

  /// Archivio sul file predefinito nella cartella dati dell'app.
  static Future<GameArchive> open() async {
    final dir = await getApplicationSupportDirectory();
    return GameArchive(File('${dir.path}/games.json'));
  }

  final JsonFile _file;
  List<SavedGame>? _games;

  /// Partite dalla più recente.
  Future<List<SavedGame>> list() async {
    final games = await _load();
    return [...games]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Partita non conclusa aggiornata più di recente, da riprendere.
  Future<SavedGame?> unfinished() async {
    for (final g in await list()) {
      if (!g.finished) return g;
    }
    return null;
  }

  /// Inserisce o sostituisce la partita con lo stesso `id`.
  Future<void> save(SavedGame game) async {
    final games = await _load();
    games.removeWhere((g) => g.id == game.id);
    games.add(game);
    await _write(games);
  }

  Future<void> delete(String id) async {
    final games = await _load();
    games.removeWhere((g) => g.id == id);
    await _write(games);
  }

  /// Tutto l'archivio in un unico PGN, dalla partita più vecchia.
  Future<String> exportPgn() async =>
      (await list()).reversed.map((g) => g.pgn.trim()).join('\n\n');

  /// Aggiunge all'archivio le partite valide di [text].
  Future<pgn.PgnImport> importPgn(String text, {DateTime? now}) async {
    final result = pgn.importPgn(text);
    final time = now ?? DateTime.now();
    final games = await _load();
    for (final (i, r) in result.games.indexed) {
      games.add(
        SavedGame.fromGame(
          r.game,
          id: 'import-${time.microsecondsSinceEpoch}-$i',
          white: r.headers['White'] ?? '?',
          black: r.headers['Black'] ?? '?',
          mode: 'importata',
          createdAt: time,
          updatedAt: time,
        ),
      );
    }
    await _write(games);
    return result;
  }

  Future<List<SavedGame>> _load() async {
    final cached = _games;
    if (cached != null) return cached;
    final json = await _file.read();
    final games = [
      for (final g in (json?['games'] as List? ?? const []))
        SavedGame.fromJson((g as Map).cast()),
    ];
    return _games = games;
  }

  Future<void> _write(List<SavedGame> games) => _file.write({
    'games': [for (final g in games) g.toJson()],
  });
}
