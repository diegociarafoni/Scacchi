import 'dart:async';

import 'package:scacchi/engine/uci_transport.dart';

import '../content_support.dart';
import '../support/golden_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // I riferimenti mostrano il computer disponibile: non dipendono dal motore installato.
  StockfishTransport.debugSupported = true;
  useContent();
  await loadGoldenFonts();
  await testMain();
}
