import 'dart:async';

import '../support/golden_fonts.dart';
import '../support/italian_device.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useItalianDevice();
  await loadGoldenFonts();
  await testMain();
}
