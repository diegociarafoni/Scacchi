import 'dart:io';

import 'src/docs_check.dart';

/// Controlla link, percorsi citati, indice di docs/ e mappa del codice.
/// Si lancia dalla radice del repository.
void main() {
  final docs = <String, String>{
    for (final f in [
      ...Directory('.').listSync().whereType<File>(),
      ...Directory('docs').listSync(recursive: true).whereType<File>(),
    ])
      if (f.path.endsWith('.md')) _relative(f.path): f.readAsStringSync(),
  };
  final libDirs = [
    for (final d in Directory('lib').listSync().whereType<Directory>())
      '${_relative(d.path)}/',
  ]..sort();

  final problems = checkDocs(
    docs: docs,
    exists: (p) =>
        FileSystemEntity.typeSync(p) != FileSystemEntityType.notFound,
    libDirs: libDirs,
  );
  if (problems.isEmpty) {
    stdout.writeln(
      '✓ documentazione coerente: ${docs.length} file controllati',
    );
    return;
  }
  problems.forEach(stderr.writeln);
  stderr.writeln(
    '\n✗ ${problems.length} problemi nella documentazione. '
    'Vedi docs/mappa-del-codice.md',
  );
  exit(1);
}

String _relative(String path) =>
    path.replaceAll(r'\', '/').replaceFirst(RegExp(r'^\./'), '');
