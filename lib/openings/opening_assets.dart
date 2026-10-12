import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'opening_book.dart';

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
