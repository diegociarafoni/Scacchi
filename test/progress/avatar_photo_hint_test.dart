import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Il backup include la foto del profilo: il testo non deve negarlo.
  test('il suggerimento della foto dice che entra solo nel backup', () {
    const attese = {'it': 'file di backup', 'en': 'backup file'};
    for (final MapEntry(key: lang, value: parte) in attese.entries) {
      final arb = jsonDecode(
        File('lib/l10n/$lang/profile.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      final hint = arb['avatarPhotoHint'] as String;
      expect(hint, contains(parte), reason: lang);
      expect(hint, isNot(contains('non viene inviata né salvata')));
      expect(hint, isNot(contains('never sent or included')));
    }
  });
}
