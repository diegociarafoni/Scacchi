import 'dart:async';

import 'content_support.dart';
import 'support/italian_device.dart';

/// Ogni test parte con il telefono in italiano e i contenuti già caricati,
/// come nell'app.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useItalianDevice();
  useContent();
  await testMain();
}
