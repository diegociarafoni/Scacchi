import 'dart:async';

import 'content_support.dart';

/// Ogni test parte con i contenuti italiani già caricati, come nell'app.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useContent();
  await testMain();
}
