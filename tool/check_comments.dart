import 'dart:io';

import 'src/comment_check.dart';

/// Controlla i commenti di lib, test, integration_test e tool.
/// Si lancia dalla radice del repository.
void main() {
  final sources = <String, String>{};
  for (final root in ['lib', 'test', 'integration_test', 'tool']) {
    for (final f in Directory(root).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final path = f.path.replaceAll(r'\', '/');
      // Il controllo e il suo test contengono i termini che cercano.
      if (path.endsWith('comment_check.dart') ||
          path.endsWith('comment_check_test.dart')) {
        continue;
      }
      sources[path] = f.readAsStringSync();
    }
  }
  final problems = checkComments(sources);
  if (problems.isEmpty) {
    stdout.writeln('✓ commenti in regola: ${sources.length} file controllati');
    return;
  }
  problems.forEach(stderr.writeln);
  stderr.writeln(
    '\n✗ ${problems.length} commenti fuori regola. '
    'Vedi docs/convenzioni-git.md#commenti-nel-codice',
  );
  exit(1);
}
