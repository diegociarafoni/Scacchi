import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';

import 'tablebase_service.dart';

TablebaseService? _shared;

/// Servizio unico dell'app: le tabelle calcolate restano in memoria tra una
/// schermata e l'altra e sul disco tra un avvio e l'altro.
TablebaseService sharedTablebase() =>
    _shared ??= TablebaseService(getApplicationSupportDirectory);

@visibleForTesting
void resetSharedTablebase() => _shared = null;
