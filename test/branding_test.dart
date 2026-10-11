import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Il nome sotto l'icona viene dai file nativi, non dalle traduzioni:
// questi controlli li tengono allineati a Rokko.
void main() {
  test('Android mostra Rokko e mantiene l\'identificativo', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:label="Rokko"'));
    expect(
      File('android/app/build.gradle.kts').readAsStringSync(),
      contains('applicationId = "io.github.diegociarafoni.scacchi"'),
    );
  });

  test('iOS mostra Rokko', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      plist,
      matches(
        RegExp(r'<key>CFBundleDisplayName</key>\s*<string>Rokko</string>'),
      ),
    );
  });

  test('icone adattive con versione monocromatica', () {
    final xml = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    expect(xml, contains('<monochrome>'));
  });
}
