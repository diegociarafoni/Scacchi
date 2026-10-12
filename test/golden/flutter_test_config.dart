import 'dart:async';

import '../support/golden_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadGoldenFonts();
  await testMain();
}
