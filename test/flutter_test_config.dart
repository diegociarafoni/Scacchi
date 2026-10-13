import 'dart:async';

import 'support/italian_device.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useItalianDevice();
  await testMain();
}
