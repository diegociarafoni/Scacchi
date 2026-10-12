import 'dart:convert';
import 'dart:io';

import 'src/android_manifest.dart';
import 'src/build_tools.dart';

/// Controlli OWASP MASVS sul manifest finale di un APK, dopo l'unione con i
/// manifest delle librerie. Uso: `check_apk.dart [--debug] <file.apk>`.
///
/// Con `--debug` si accetta la build di debug: è debuggable e ha il permesso
/// INTERNET aggiunto dagli strumenti, quindi si saltano quei due controlli.
void main(List<String> args) {
  final debug = args.contains('--debug');
  final files = args.where((a) => a != '--debug').toList();
  if (files.length != 1) {
    stderr.writeln('uso: check_apk.dart [--debug] <file.apk>');
    exit(2);
  }
  final dump = Process.runSync(_aapt2(), [
    'dump',
    'xmltree',
    '--file',
    'AndroidManifest.xml',
    files.single,
  ]);
  if (dump.exitCode != 0) {
    stderr.writeln('aapt2: ${dump.stderr}');
    exit(2);
  }
  final manifest = AndroidManifest.parseXmlTree(dump.stdout as String);
  final pkg = manifest.packageName;
  final policy = jsonDecode(
    File('tool/policy.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final privacy = policy['privacy'] as Map<String, dynamic>;
  // Le librerie aggiungono permessi propri: quelli del manifest finale sono
  // elencati a parte, ognuno con il motivo.
  final allowed = {
    ...(privacy['androidPermissions'] as Map<String, dynamic>).keys,
    ...(privacy['mergedPermissions'] as Map<String, dynamic>).keys,
    if (debug) 'android.permission.INTERNET',
  };

  final unexpected = [
    for (final p in manifest.permissions)
      // androidx aggiunge un permesso firmato dall'app per i receiver interni.
      if (p != '$pkg.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION' &&
          !allowed.contains(p))
        p,
  ];
  final checks = <String, bool>{
    if (!debug) 'MASVS-CODE: APK non debuggable': !manifest.isDebuggable,
    'MASVS-NETWORK/PRIVACY: solo i permessi di tool/policy.json':
        unexpected.isEmpty,
    'MASVS-PLATFORM: esportata senza permessi solo MainActivity':
        manifest.unprotectedExportedComponents.length == 1 &&
        manifest.unprotectedExportedComponents.single.endsWith('.MainActivity'),
  };

  stdout.writeln('Pacchetto: $pkg');
  stdout.writeln('Permessi: ${manifest.permissions}');
  stdout.writeln(
    'Componenti esportati senza permesso: '
    '${manifest.unprotectedExportedComponents}',
  );
  if (unexpected.isNotEmpty) {
    stdout.writeln('Permessi non previsti: $unexpected');
  }
  var failed = false;
  checks.forEach((name, ok) {
    if (!ok) failed = true;
    stdout.writeln('${ok ? '✓' : '✗'} $name');
  });
  if (failed) exit(1);
}

String _aapt2() {
  final sdk =
      Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  if (sdk == null) return 'aapt2';
  final dir = Directory('$sdk/build-tools');
  if (!dir.existsSync()) return 'aapt2';
  final latest = latestBuildTools(
    dir.listSync().whereType<Directory>().map(
      (d) => d.path.split(Platform.pathSeparator).last,
    ),
  );
  return latest == null ? 'aapt2' : '${dir.path}/$latest/aapt2';
}
