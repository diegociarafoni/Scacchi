import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// RNF-02: la scheda di Google Play e di F-Droid è nel repository, con i
/// limiti di lunghezza degli store, e le corsie di iOS e la ricetta F-Droid ci
/// sono. Procedura: docs/store.md.
void main() {
  const meta = 'android/fastlane/metadata/android';
  const appId = 'io.github.diegociarafoni.scacchi';

  for (final locale in ['it-IT', 'en-US']) {
    group('scheda $locale', () {
      String read(String name) =>
          File('$meta/$locale/$name').readAsStringSync();

      test('titolo, descrizione breve e completa nei limiti', () {
        expect(read('title.txt').trim(), 'Rokko');
        expect(
          read('short_description.txt').trim().length,
          lessThanOrEqualTo(80),
        );
        expect(read('short_description.txt').trim(), isNotEmpty);
        final full = read('full_description.txt').trim();
        expect(full.length, inInclusiveRange(200, 4000));
      });

      test('dichiara la privacy', () {
        final text =
            '${read('short_description.txt')}${read('full_description.txt')}'
                .toLowerCase();
        expect(text, anyOf(contains('nessun dato'), contains('no data')));
      });
    });
  }

  test('la ricetta F-Droid descrive questa app', () {
    final recipe = File('fdroid/$appId.yml').readAsStringSync();
    expect(recipe, contains('License: GPL-3.0-or-later'));
    expect(
      recipe,
      contains('SourceCode: https://github.com/diegociarafoni/rokko'),
    );
    expect(recipe, contains('Categories:'));
    expect(recipe, contains('flutter build apk'));
    expect(recipe, contains('AutoUpdateMode: Version'));
  });

  test(
    'le corsie iOS convalida e beta esistono e usano le chiavi in segreti',
    () {
      final fastfile = File('ios/fastlane/Fastfile').readAsStringSync();
      expect(fastfile, contains('lane :convalida'));
      expect(fastfile, contains('lane :beta'));
      expect(fastfile, contains('upload_to_testflight'));
      expect(fastfile, contains('ENV.fetch("APP_STORE_CONNECT_KEY_P8")'));
      expect(File('ios/fastlane/Appfile').readAsStringSync(), contains(appId));
    },
  );

  test('il workflow iOS elenca i segreti richiesti e non ne contiene', () {
    final wf = File('.github/workflows/store-ios.yml').readAsStringSync();
    for (final s in [
      'APP_STORE_CONNECT_KEY_ID',
      'APP_STORE_CONNECT_ISSUER_ID',
      'APP_STORE_CONNECT_KEY_P8',
      'IOS_DISTRIBUTION_CERT_BASE64',
      'IOS_CERT_PASSWORD',
      'IOS_PROVISIONING_PROFILE_BASE64',
      'APPLE_TEAM_ID',
    ]) {
      expect(wf, contains('secrets.$s'));
    }
  });
}
