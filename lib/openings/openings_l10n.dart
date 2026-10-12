import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'opening_book.dart';
import 'repertoire.dart';

/// Testi localizzati; senza localizzazione nel contesto si usa l'italiano.
AppLocalizations openingsL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));

/// Nome dell'apertura nella lingua dell'interfaccia: il libro è in inglese,
/// la traduzione esiste solo in italiano.
String openingDisplayName(AppLocalizations l, Opening opening) =>
    l.localeName == 'it' ? opening.localName : opening.name;

String repertoireErrorText(AppLocalizations l, RepertoireError error) =>
    switch (error.kind) {
      RepertoireErrorKind.empty => l.openingsErrorEmpty,
      RepertoireErrorKind.illegal => l.openingsErrorIllegal,
      RepertoireErrorKind.noOwnMoves => l.openingsErrorNoOwnMoves,
      RepertoireErrorKind.conflict => l.openingsErrorConflict(error.san!),
    };
