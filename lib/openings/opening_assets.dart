import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'opening_book.dart';
import 'opening_stats.dart';

const openingAsset = 'assets/openings/openings.tsv';

Future<OpeningBook>? _book;
OpeningBook? _loaded;

/// Il libro, se è già stato caricato: per chi non può aspettare.
OpeningBook? get loadedOpeningBook => _loaded;

/// Libro delle aperture incluso nell'app, caricato una sola volta; dopo un
/// errore si riprova alla richiesta successiva.
Future<OpeningBook> openingBook() => _book ??= rootBundle
    .loadString(openingAsset)
    .then((tsv) => compute(OpeningBook.parseTsv, tsv))
    .then((book) => _loaded = book)
    .catchError((Object e, StackTrace st) {
      _book = null;
      Error.throwWithStackTrace(e, st);
    });

const openingStatsAsset = 'assets/openings/opening_stats.tsv';

Future<OpeningStats>? _stats;

/// Statistiche per mossa incluse nell'app, caricate una sola volta; dopo un
/// errore si riprova alla richiesta successiva.
Future<OpeningStats> openingStats() => _stats ??= rootBundle
    .loadString(openingStatsAsset)
    .then((tsv) => compute(OpeningStats.parseTsv, tsv))
    .catchError((Object e, StackTrace st) {
      _stats = null;
      Error.throwWithStackTrace(e, st);
    });

/// Come [openingStats], ma un errore di lettura diventa `null`: chi lo usa
/// mostra il solo libro e nessun errore resta senza gestore.
Future<OpeningStats?> openingStatsOrNull() => openingStats()
    .then<OpeningStats?>((s) => s)
    .onError<Object>((_, _) => null);
