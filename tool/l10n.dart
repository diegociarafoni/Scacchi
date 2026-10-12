import 'dart:io';

import 'src/l10n_merge.dart';

/// Genera i testi tradotti: unisce `lib/l10n/<lingua>/*.arb` in
/// `lib/l10n/app_<lingua>.arb` e lancia `flutter gen-l10n`. I file prodotti non
/// sono nel repository, così le PR parallele non vanno in conflitto.
///
/// Uso: `dart tool/l10n.dart` (da rifare dopo ogni modifica ai file `.arb`).
/// Con `--solo-unione` si salta `flutter gen-l10n`: serve prima del primo
/// `flutter pub get` di una copia nuova, che altrimenti non trova il modello
/// e poi genera il codice da sé.
Future<void> main(List<String> args) async {
  // I percorsi sono relativi alla radice del repository, da qualunque cartella.
  Directory.current = File.fromUri(Platform.script).parent.parent;
  final root = Directory('lib/l10n');
  final sources = readSources(root);
  if (sources.isEmpty) {
    stderr.writeln('✗ nessuna lingua in lib/l10n/<lingua>/');
    exit(1);
  }
  final problems = checkLocales(sources);
  if (problems.isNotEmpty) {
    stderr.writeln('✗ traduzioni incoerenti:\n  ${problems.join('\n  ')}');
    exit(1);
  }
  // Un file di una lingua tolta resterebbe e `gen-l10n` la genererebbe ancora.
  for (final f in root.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (RegExp(r'^app_\w+\.arb$').hasMatch(name) &&
        !sources.containsKey(name.substring(4, name.length - 4))) {
      f.deleteSync();
    }
  }
  try {
    for (final MapEntry(key: locale, value: files) in sources.entries) {
      File('lib/l10n/app_$locale.arb')
          .writeAsStringSync(mergeArbs(locale, files));
    }
  } on FormatException catch (e) {
    stderr.writeln('✗ ${e.message}');
    exit(1);
  }
  if (args.contains('--solo-unione')) return;
  final result = await Process.start(
    'flutter',
    ['gen-l10n'],
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  exit(await result.exitCode);
}
