import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Testi della scacchiera fisica. Senza i delegate (schermate montate nei
/// test) si usa l'italiano, la lingua predefinita.
AppLocalizations physicalL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));
