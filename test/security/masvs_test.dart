import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Controlli statici OWASP MASVS v2 sui sorgenti. Mappa dei controlli e di
/// ciò che non è coperto: docs/sicurezza.md.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
  final policy = jsonDecode(
    File('tool/policy.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final privacy = policy['privacy'] as Map<String, dynamic>;

  group('MASVS-NETWORK', () {
    test('nessun traffico in chiaro consentito su Android', () {
      expect(manifest, isNot(contains('usesCleartextTraffic="true"')));
    });

    test('iOS non disattiva App Transport Security', () {
      expect(infoPlist, isNot(contains('NSAllowsArbitraryLoads')));
    });
  });

  group('MASVS-PLATFORM', () {
    test('solo l\'attività principale è esportata', () {
      final exported = RegExp(
        r'<(activity|service|receiver|provider)[^>]*android:exported="true"',
      ).allMatches(manifest);
      expect(exported.length, 1);
      expect(manifest, contains('android:name=".MainActivity"'));
    });

    test('nessun deep link o schema URL personalizzato', () {
      expect(manifest, isNot(contains('<data android:scheme')));
      expect(infoPlist, isNot(contains('CFBundleURLSchemes')));
    });
  });

  group('MASVS-STORAGE', () {
    // In rilascio `debugPrint` scrive comunque nel logcat. I messaggi esistenti
    // riportano solo errori di lettura e scrittura; la base in tool/policy.json
    // può solo diminuire: ogni nuovo log va dentro `if (kDebugMode)`.
    test('nessun nuovo log fuori da kDebugMode', () {
      final baseline = ((policy['logging'] as Map)['unguardedBaseline'] as Map)
          .map((k, v) => MapEntry(k as String, v as int));
      final logging = RegExp(r'\b(print|debugPrint)\(|dart:developer');
      final unguarded = <String, int>{};
      for (final file in _dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!logging.hasMatch(lines[i])) continue;
          final context = lines.sublist(i < 2 ? 0 : i - 2, i + 1).join('\n');
          if (!context.contains('kDebugMode')) {
            unguarded[path] = (unguarded[path] ?? 0) + 1;
          }
        }
      }
      for (final MapEntry(key: path, value: n) in unguarded.entries) {
        expect(
          n,
          lessThanOrEqualTo(baseline[path] ?? 0),
          reason: '$path: log fuori da kDebugMode',
        );
      }
      for (final MapEntry(key: path, value: n) in baseline.entries) {
        expect(
          unguarded[path] ?? 0,
          n,
          reason: '$path: abbassare la base in tool/policy.json',
        );
      }
    });
  });

  group('MASVS-CODE', () {
    test('il manifest non forza il debug', () {
      expect(manifest, isNot(contains('android:debuggable')));
    });

    test('il rilascio usa la chiave dello store quando è disponibile', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('ANDROID_KEYSTORE_PATH'));
      expect(gradle, contains('create("release")'));
    });
  });

  group('MASVS-PRIVACY', () {
    test('nessun SDK di analisi, pubblicità o tracciamento', () {
      final forbidden = (privacy['forbiddenPackages'] as List).cast<String>();
      final transitiveAllowed = (privacy['transitiveAllowed'] as Map).keys
          .cast<String>()
          .toSet();
      final lock = File('pubspec.lock').readAsStringSync();
      final packages = <String, String>{
        for (final m in RegExp(
          r'^  (\w+):\n    dependency: "?([\w ]+)"?$',
          multiLine: true,
        ).allMatches(lock))
          m.group(1)!: m.group(2)!,
      };
      final found = packages.keys.toSet().intersection(forbidden.toSet());
      // Un pacchetto vietato è ammesso solo come dipendenza indiretta e con
      // un motivo scritto in tool/policy.json.
      expect(found.difference(transitiveAllowed), isEmpty);
      for (final name in found) {
        expect(packages[name], 'transitive', reason: name);
      }
    });

    test('solo i permessi Android elencati in tool/policy.json', () {
      final allowed = (privacy['androidPermissions'] as Map).keys
          .cast<String>()
          .toSet();
      final declared = RegExp(
        r'<uses-permission android:name="([\w.]+)"(?![^>]*tools:node="remove")',
      ).allMatches(manifest).map((m) => m.group(1)!).toSet();
      expect(
        declared.difference(allowed),
        isEmpty,
        reason: 'aggiungere il permesso a tool/policy.json con il motivo',
      );
      expect(allowed.difference(declared), isEmpty, reason: 'permesso inutile');
    });

    test('iOS chiede solo fotocamera e libreria, con la spiegazione', () {
      final keys = RegExp(r'<key>(NS\w+UsageDescription)</key>')
          .allMatches(infoPlist)
          .map((m) => m.group(1))
          .toSet();
      expect(keys, {
        'NSCameraUsageDescription',
        'NSPhotoLibraryUsageDescription',
      });
    });
  });
}

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.contains('generated'));
