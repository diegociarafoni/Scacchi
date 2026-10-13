import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// RNF-10: dichiarazioni «nessun dato raccolto» per App Store e Google Play.
/// Testi e motivazioni: docs/privacy-store.md.
void main() {
  final manifest = File('ios/Runner/PrivacyInfo.xcprivacy');
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
  final project = File('ios/Runner.xcodeproj/project.pbxproj')
      .readAsStringSync();

  test('il manifest di privacy iOS esiste e dichiara nessun dato raccolto', () {
    expect(manifest.existsSync(), isTrue);
    final xml = manifest.readAsStringSync();
    expect(
      RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>').hasMatch(xml),
      isTrue,
    );
    expect(
      RegExp(r'<key>NSPrivacyTrackingDomains</key>\s*<array/>').hasMatch(xml),
      isTrue,
    );
    expect(
      RegExp(r'<key>NSPrivacyCollectedDataTypes</key>\s*<array/>')
          .hasMatch(xml),
      isTrue,
    );
  });

  test('il manifest elenca le API a motivo obbligatorio che l\'app usa', () {
    final xml = manifest.readAsStringSync();
    // Ogni categoria deve avere il proprio motivo subito dopo.
    for (final (category, reason) in [
      ('UserDefaults', 'CA92.1'),
      ('FileTimestamp', 'C617.1'),
    ]) {
      expect(
        RegExp(
          'NSPrivacyAccessedAPICategory$category</string>\\s*'
          '<key>NSPrivacyAccessedAPITypeReasons</key>\\s*'
          '<array>\\s*<string>$reason</string>\\s*</array>',
        ).hasMatch(xml),
        isTrue,
        reason: category,
      );
    }
  });

  test('il manifest è tra le risorse del bersaglio Runner', () {
    expect(project, contains('PrivacyInfo.xcprivacy in Resources'));
  });

  test('la crittografia del multigiocatore è dichiarata per l\'export', () {
    expect(
      RegExp(r'<key>ITSAppUsesNonExemptEncryption</key>\s*<true/>')
          .hasMatch(infoPlist),
      isTrue,
    );
  });

  test('i testi per le schede degli store ci sono', () {
    final doc = File('docs/privacy-store.md').readAsStringSync();
    for (final s in [
      'Data safety',
      'Privacy Nutrition Label',
      'Data Not Collected',
    ]) {
      expect(doc, contains(s));
    }
  });
}
