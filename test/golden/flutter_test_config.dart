import 'dart:async';

import 'package:scacchi/engine/uci_transport.dart';

import '../support/golden_fonts.dart';
import '../support/italian_device.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // I riferimenti mostrano il computer disponibile: non dipendono dal motore installato.
  StockfishTransport.debugSupported = true;
  useItalianDevice();
  await loadGoldenFonts();
  await testMain();
}
