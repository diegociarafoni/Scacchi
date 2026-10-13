import 'dart:convert';
import 'dart:io';

import 'src/fixed_strings.dart';

/// Cerca i testi italiani scritti nel codice di `lib/` invece che nei `.arb`.
/// Il conteggio per cartella non può salire rispetto a
/// `tool/stringhe_fisse_base.json`: esce con 1 se una cartella peggiora.
///
/// Uso: `dart tool/stringhe_fisse.dart [--elenco] [--aggiorna]`
///  - `--elenco`: stampa ogni testo con file e riga;
///  - `--aggiorna`: riscrive la base con i conteggi attuali (dopo una migrazione).
/// Una riga con il commento `// l10n-ok` è esclusa (nomi propri, dati).
void main(List<String> args) {
  Directory.current = File.fromUri(Platform.script).parent.parent;
  final sources = {
    for (final f in Directory('lib').listSync(recursive: true))
      if (f is File && f.path.endsWith('.dart'))
        f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
  };
  if (args.contains('--elenco')) {
    for (final e
        in sources.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      if (e.key.startsWith('lib/l10n/')) continue;
      for (final h in findFixedStrings(e.value)) {
        stdout.writeln('${e.key}:${h.line}: ${h.text}');
      }
    }
    return;
  }
  final current = countByFolder(sources);
  final baseFile = File('tool/stringhe_fisse_base.json');
  if (args.contains('--aggiorna')) {
    final sorted = Map.fromEntries(
      current.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    baseFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
    );
    stdout.writeln(
      '✓ base aggiornata: ${current.values.fold(0, (a, b) => a + b)} testi',
    );
    return;
  }
  final Map<String, int> base;
  try {
    base = (jsonDecode(baseFile.readAsStringSync()) as Map).cast<String, int>();
  } on Object catch (e) {
    stderr.writeln(
      '✗ base non valida (${baseFile.path}): $e. '
      'Rigenerala con `dart tool/stringhe_fisse.dart --aggiorna`.',
    );
    exit(1);
  }
  final worse = regressions(current, base);
  final total = current.values.fold(0, (a, b) => a + b);
  if (worse.isEmpty) {
    final better = improvements(current, base);
    if (better.isNotEmpty) {
      stderr.writeln(
        '✗ testi fissi scesi sotto la base in: ${better.keys.join(', ')}. '
        'Abbassa la base con `dart tool/stringhe_fisse.dart --aggiorna` '
        'e includila nel commit, così non può risalire.',
      );
      exit(1);
    }
    stdout.writeln('✓ testi fissi: $total (base invariata)');
    return;
  }
  for (final e in worse.entries) {
    stderr.writeln(
      '✗ ${e.key == rootFolder ? 'lib/' : 'lib/${e.key}/'}: ${e.value} testi fissi, la base ne ammette ${base[e.key] ?? 0}',
    );
  }
  stderr.writeln(
    'Sposta i nuovi testi nei file .arb (docs/localizzazione.md). '
    '`dart tool/stringhe_fisse.dart --elenco` mostra dove sono.',
  );
  exit(1);
}
