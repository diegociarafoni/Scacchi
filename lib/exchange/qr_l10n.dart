import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Testi dello scambio QR. Le schermate che li ospitano (archivio, partita)
/// non usano ancora i file `.arb` e possono essere montate senza i delegate:
/// in quel caso si usa l'italiano, la lingua predefinita.
AppLocalizations qrL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));
