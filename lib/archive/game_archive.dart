import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../storage/json_file.dart';
import 'pgn.dart' as pgn;
import 'saved_game.dart';

/// Intestazioni ricalcolate dalla partita al salvataggio.
const _computedHeaders = {'Result', 'FEN', 'SetUp'};

/// Archivio locale delle partite in un file JSON.
class GameArchive {
  GameArchive(File file) : _file = JsonFile(file, version: 1);

  /// Archivio condiviso sul file predefinito nella cartella dati dell'app:
  /// tutte le schermate usano la stessa istanza e la stessa cache.
  static Future<GameArchive> open() =>
      _shared ??= _openDefault().catchError((Object e, StackTrace st) {
        // Un errore si riprova alla prossima apertura.
        _shared = null;
        Error.throwWithStackTrace(e, st);
      });

  static Future<GameArchive>? _shared;

  static Future<GameArchive> _openDefault() async {
    final dir = await getApplicationSupportDirectory();
    return GameArchive(File('${dir.path}/games.json'));
  }

  final JsonFile _file;
  Future<List<SavedGame>>? _games;

  /// Partite dalla più recente; a parità di data, dall'ultima inserita.
  Future<List<SavedGame>> list() async {
    final games = (await _load()).indexed.toList()
      ..sort((a, b) {
        final byDate = b.$2.updatedAt.compareTo(a.$2.updatedAt);
        return byDate != 0 ? byDate : b.$1.compareTo(a.$1);
      });
    return [for (final (_, g) in games) g];
  }

  /// Partita propria non conclusa aggiornata più di recente, da riprendere.
  Future<SavedGame?> unfinished() async {
    for (final g in await list()) {
      if (!g.finished && g.mode != SavedGame.imported) return g;
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
  Future<pgn.PgnImport> importPgn(String text, {DateTime? now}) =>
      importRecords(pgn.importPgn(text), now: now);

  /// Aggiunge partite già lette, per esempio filtrate dopo uno scambio QR.
  Future<pgn.PgnImport> importRecords(
    pgn.PgnImport result, {
    DateTime? now,
  }) async {
    final time = now ?? DateTime.now();
    final games = await _load();
    for (final (i, r) in result.games.indexed) {
      games.add(
        SavedGame.fromGame(
          r.game,
          id: 'import-${time.microsecondsSinceEpoch}-$i',
          white: r.headers['White'] ?? '?',
          black: r.headers['Black'] ?? '?',
          mode: SavedGame.imported,
          createdAt: time,
          updatedAt: time,
          headers: {
            for (final h in r.headers.entries)
              if (!_computedHeaders.contains(h.key)) h.key: h.value,
          },
        ),
      );
    }
    await _write(games);
    return result;
  }

  /// Una sola lettura condivisa anche da chiamate contemporanee; dopo un
  /// errore di lettura la prossima chiamata riprova.
  Future<List<SavedGame>> _load() {
    final cached = _games;
    if (cached != null) return cached;
    final games = _games = _read();
    // Gestore aggiunto una sola volta, sulla lettura appena avviata.
    unawaited(
      games.catchError((Object _) {
        if (identical(_games, games)) _games = null;
        return <SavedGame>[];
      }),
    );
    return games;
  }

  Future<List<SavedGame>> _read() async =>
      await _file.read(
        (json) => [
          for (final g in json['games']! as List)
            SavedGame.fromJson((g as Map).cast()),
        ],
      ) ??
      [];

  Future<void> _write(List<SavedGame> games) => _file.write({
    'games': [for (final g in games) g.toJson()],
  });
}
