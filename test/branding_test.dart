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
      contains('applicationId = "io.github.diegociarafoni.rokko"'),
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
    expect(
      plist,
      matches(RegExp(r'<key>CFBundleName</key>\s*<string>Rokko</string>')),
    );
  });

  // flutter_launcher_icons 0.14 scrive per errore AppIcon in questa opzione.
  test('il progetto Xcode non porta la modifica errata delle icone', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();
    expect(project, isNot(contains('SYMBOL_EXTENSIONS = AppIcon')));
  });

  test('Linux e Windows mostrano Rokko', () {
    expect(
      File('linux/runner/my_application.cc').readAsStringSync(),
      isNot(contains('"scacchi"')),
    );
    expect(
      File('windows/runner/main.cpp').readAsStringSync(),
      contains('L"Rokko"'),
    );
  });

  test('icone adattive con versione monocromatica', () {
    final xml = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    expect(xml, contains('<monochrome>'));
  });
}
