import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Simula un telefono in italiano: l'app segue la lingua del dispositivo e i
/// test, scritti sui testi italiani, non dipendono da quella della macchina.
void useItalianDevice() {
  setUp(() {
    final dispatcher =
        TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
    dispatcher.localesTestValue = const [Locale('it', 'IT')];
    addTearDown(dispatcher.clearLocalesTestValue);
  });
}
