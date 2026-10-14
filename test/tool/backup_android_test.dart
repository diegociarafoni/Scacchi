import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('il backup automatico di Android è disattivato', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync()
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
    final application = RegExp(r'<application[^>]*>').firstMatch(manifest)!;
    expect(application.group(0), contains('android:allowBackup="false"'));
    expect(manifest, isNot(contains('fullBackupContent')));
    expect(manifest, isNot(contains('dataExtractionRules')));
  });
}
