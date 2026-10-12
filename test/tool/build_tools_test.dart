import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/build_tools.dart';

void main() {
  group('versione più recente dei build-tools', () {
    test('confronta i numeri, non il testo', () {
      expect(latestBuildTools(['9.0.0', '35.0.0', '34.0.0']), '35.0.0');
    });

    test('preferisce una versione stabile alla sua anteprima', () {
      expect(latestBuildTools(['36.0.0-rc1', '36.0.0']), '36.0.0');
    });

    test('nessuna cartella: nessuna versione', () {
      expect(latestBuildTools([]), isNull);
    });
  });
}
