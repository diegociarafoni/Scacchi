import 'dart:async';

import '../content_support.dart';
import '../support/golden_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useContent();
  await loadGoldenFonts();
  await testMain();
}
