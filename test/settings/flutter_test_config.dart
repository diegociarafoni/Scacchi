import 'dart:async';

import '../content_support.dart';
import '../support/golden_fonts.dart';
import '../support/italian_device.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useContent();
  useItalianDevice();
  await loadGoldenFonts();
  await testMain();
}
