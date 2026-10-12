import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'opening_book.dart';
import 'opening_stats.dart';

const openingAsset = 'assets/openings/openings.tsv';

Future<OpeningBook>? _book;

/// Libro delle aperture incluso nell'app, caricato una sola volta; dopo un
/// errore si riprova alla richiesta successiva.
Future<OpeningBook> openingBook() => _book ??= rootBundle
    .loadString(openingAsset)
    .then((tsv) => compute(OpeningBook.parseTsv, tsv))
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
