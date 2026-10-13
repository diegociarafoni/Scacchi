import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'opening_assets.dart';
import 'opening_book.dart';

/// Nome dell'apertura raggiunta dalla partita, o [fallback] fuori dal libro
/// (RF-90).
class OpeningName extends StatelessWidget {
  const OpeningName({
    super.key,
    required this.positions,
    required this.fallback,
    this.fallbackWidget,
    this.book,
  });

  /// Posizioni della partita, dalla iniziale all'ultima.
  final List<Position> positions;
  final String fallback;

  /// Mostrato al posto di [fallback] finché la posizione non ha un nome.
  final Widget? fallbackWidget;

  /// Sostituibile nei test; di default il libro incluso nell'app.
  final Future<OpeningBook>? book;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpeningBook>(
      future: book ?? openingBook(),
      builder: (context, snapshot) {
        final opening = snapshot.data?.classifyPositions(positions);
        if (opening == null) return fallbackWidget ?? Text(fallback);
        return Semantics(
          label: AppLocalizations.of(context)
              .openingsNameSemantics(opening.localName, opening.eco),
          excludeSemantics: true,
          child: Text(
            // Solo il nome italiano, su due righe: il codice ECO occupava lo
            // spazio e il nome veniva troncato.
            opening.localName,
            key: const Key('opening-name'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
