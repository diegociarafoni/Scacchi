import 'dart:convert';
import 'dart:io';

import 'src/licenses.dart';

/// Verifica le licenze delle dipendenze distribuite con l'app.
/// Richiede `flutter pub get`; considera solo le dipendenze non di sviluppo.
void main() {
  final policy =
      (jsonDecode(File('tool/policy.json').readAsStringSync())
              as Map<String, dynamic>)['licenses']
          as Map<String, dynamic>;
  final allowed = (policy['allowed'] as List).cast<String>().toSet();
  final overrides = (policy['overrides'] as Map).cast<String, String>();

  final deps = Process.runSync('flutter', [
    'pub',
    'deps',
    '--json',
  ], runInShell: true);
  if (deps.exitCode != 0) _fail('flutter pub deps: ${deps.stderr}');
  final stdoutText = deps.stdout as String;
  final graph = jsonDecode(
    stdoutText.substring(stdoutText.indexOf('{')),
  ) as Map<String, dynamic>;
  final byName = {
    for (final p in (graph['packages'] as List).cast<Map<String, dynamic>>())
      p['name'] as String: p,
  };
  final root = graph['root'] as String;

  // Chiusura transitiva delle dipendenze dirette, escluse quelle di sviluppo.
  final shipped = <String>{};
  final queue = [
    ...(byName[root]!['directDependencies'] as List).cast<String>(),
  ];
  while (queue.isNotEmpty) {
    final name = queue.removeLast();
    if (!shipped.add(name)) continue;
    queue.addAll((byName[name]!['dependencies'] as List).cast<String>());
  }

  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  // rootUri può essere relativo alla cartella .dart_tool/.
  final base = Directory('.dart_tool').absolute.uri;
  final roots = {
    for (final p in (config['packages'] as List).cast<Map<String, dynamic>>())
      p['name'] as String: base
          .resolve(
            '${(p['rootUri'] as String).replaceFirst(RegExp(r'/$'), '')}/',
          )
          .toFilePath(),
  };
  final rows = <String>[];
  var failed = false;
  for (final name in shipped) {
    final p = byName[name]!;
    String? spdx;
    if (p['source'] == 'sdk') {
      spdx = 'BSD-3-Clause';
    } else {
      spdx = overrides[name] ?? _detect(roots[name]);
    }
    final ok = isAllowed(spdx, allowed);
    if (!ok) failed = true;
    rows.add(
      '${ok ? '✓' : '✗'} $name ${p['version']}: ${spdx ?? 'sconosciuta'}',
    );
  }
  rows.sort();
  rows.forEach(stdout.writeln);
  if (failed) {
    stderr.writeln(
      '\nLicenze non compatibili o non riconosciute. Vedi docs/dipendenze-e-licenze.md',
    );
    exit(1);
  }
  stdout.writeln('\n✓ ${rows.length} dipendenze con licenza compatibile');
}

String? _detect(String? dir) {
  if (dir == null) return null;
  final d = Directory(dir);
  if (!d.existsSync()) return null;
  for (final e in d.listSync()) {
    final base = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (e is File &&
        RegExp('^(LICEN[SC]E|COPYING)', caseSensitive: false).hasMatch(base)) {
      final spdx = detectLicense(e.readAsStringSync());
      if (spdx != null) return spdx;
    }
  }
  return null;
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(2);
}
