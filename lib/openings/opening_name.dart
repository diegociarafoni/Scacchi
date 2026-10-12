import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'opening_assets.dart';
import 'opening_book.dart';
import 'openings_l10n.dart';

/// Nome dell'apertura raggiunta dalla partita, o [fallback] fuori dal libro
/// (RF-90).
class OpeningName extends StatelessWidget {
  const OpeningName({
    super.key,
    required this.positions,
    required this.fallback,
    this.book,
  });

  /// Posizioni della partita, dalla iniziale all'ultima.
  final List<Position> positions;
  final String fallback;

  /// Sostituibile nei test; di default il libro incluso nell'app.
  final Future<OpeningBook>? book;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpeningBook>(
      future: book ?? openingBook(),
      builder: (context, snapshot) {
        final opening = snapshot.data?.classifyPositions(positions);
        if (opening == null) return Text(fallback);
        final l = openingsL10n(context);
        final name = openingDisplayName(l, opening);
        return Semantics(
          label: l.openingsGameSemantics(name, opening.eco),
          excludeSemantics: true,
          child: Text(
            // Solo il nome, su due righe: il codice ECO occupava lo spazio e
            // il nome veniva troncato.
            name,
            key: const Key('opening-name'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
