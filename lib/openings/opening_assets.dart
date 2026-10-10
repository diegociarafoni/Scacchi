import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'opening_book.dart';

const openingAsset = 'assets/openings/openings.tsv';

Future<OpeningBook>? _book;

/// Libro delle aperture incluso nell'app, caricato una sola volta.
Future<OpeningBook> openingBook() => _book ??= rootBundle
    .loadString(openingAsset)
    .then((tsv) => compute(OpeningBook.parseTsv, tsv));
