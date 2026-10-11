import 'dart:convert';
import 'dart:io';

import 'src/licenses.dart';

/// Verifica le licenze delle dipendenze distribuite con l'app.
/// Richiede `flutter pub get`; considera solo le dipendenze non di sviluppo.
void main() {
  try {
    _run();
  } on FormatException catch (e) {
    _fail('Formato inatteso: $e');
  } on TypeError catch (e) {
    _fail('Struttura inattesa dell\'elenco delle dipendenze: $e');
  }
}

void _run() {
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
    final List<String> found;
    if (p['source'] == 'sdk') {
      found = ['BSD-3-Clause'];
    } else if (overrides[name] != null) {
      found = [overrides[name]!];
    } else {
      found = _detect(roots[name]);
    }
    // Con più file di licenza devono essere tutte ammesse: una ammessa non ne copre un'altra.
    final ok = found.isNotEmpty && found.every((l) => isAllowed(l, allowed));
    if (!ok) failed = true;
    rows.add(
      '${ok ? '✓' : '✗'} $name ${p['version']}: '
      '${found.isEmpty ? 'sconosciuta' : found.join(' + ')}',
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

/// Licenze riconosciute in tutti i file LICENSE/COPYING/UNLICENSE del pacchetto.
List<String> _detect(String? dir) {
  if (dir == null) return const [];
  final d = Directory(dir);
  if (!d.existsSync()) return const [];
  final found = <String>{};
  for (final e in d.listSync()) {
    final base = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (e is File &&
        RegExp(
          '^(LICEN[SC]E|COPYING|UNLICENSE)',
          caseSensitive: false,
        ).hasMatch(base)) {
      final spdx = detectLicense(e.readAsStringSync());
      if (spdx != null) found.add(spdx);
    }
  }
  return found.toList()..sort();
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(2);
}
