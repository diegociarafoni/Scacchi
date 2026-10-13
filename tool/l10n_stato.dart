import 'dart:io';

import 'src/l10n_merge.dart';

/// Copertura delle traduzioni: per ogni lingua le chiavi tradotte rispetto
/// all'italiano, e con `--manca` anche quali mancano. Esce con 1 se una lingua
/// «pronta» o «base» non è completa.
///
/// Uso: `dart tool/l10n_stato.dart [--manca]`.
void main(List<String> args) {
  Directory.current = File.fromUri(Platform.script).parent.parent;
  final sources = readSources(Directory('lib/l10n'));
  final states = parseLanguageStates(
    File('tool/lingue.json').readAsStringSync(),
  );
  final result = coverage(sources, base: 'it');
  var incomplete = false;
  for (final locale in result.keys.toList()..sort()) {
    final c = result[locale]!;
    final state = states[locale]?.label ?? 'non dichiarata';
    stdout.writeln(
      '${locale.padRight(4)} ${c.translated}/${c.total} '
      '(${c.percent.toStringAsFixed(1)}%)  $state',
    );
    final strict =
        states[locale] == null ||
        states[locale] == LanguageState.base ||
        states[locale] == LanguageState.ready;
    if (strict && c.translated < c.total) incomplete = true;
    if (args.contains('--manca')) {
      for (final e in c.missing.entries) {
        stdout.writeln('  ${e.key}: ${e.value.join(', ')}');
      }
    }
  }
  if (incomplete) {
    stderr.writeln('✗ una lingua pronta non è completa');
    exit(1);
  }
}
