import 'dart:convert';
import 'dart:io';

/// Unisce i file `.arb` di una lingua (uno per funzione) nel file unico che il
/// generatore di Flutter richiede. `@@locale` si aggiunge qui e per primo.
String mergeArbs(String locale, Map<String, String> files) {
  final merged = <String, Object?>{'@@locale': locale};
  final owner = <String, String>{};
  for (final name in files.keys.toList()..sort()) {
    for (final entry in _parse(name, files[name]!).entries) {
      if (entry.key == '@@locale') {
        throw FormatException(
          '$name: @@locale va tolto, lo aggiunge tool/l10n.dart',
        );
      }
      // `@chiave` segue la propria chiave: il duplicato si segnala una volta.
      if (!entry.key.startsWith('@')) {
        final other = owner[entry.key];
        if (other != null) {
          throw FormatException(
            'la chiave "${entry.key}" è sia in $other sia in $name',
          );
        }
        owner[entry.key] = name;
      }
      merged[entry.key] = entry.value;
    }
  }
  return '${const JsonEncoder.withIndent('  ').convert(merged)}\n';
}

/// Problemi di coerenza tra le lingue: stessi file e, in ciascuno, stesse chiavi.
List<String> checkLocales(Map<String, Map<String, String>> sources) {
  final problems = <String>[];
  final names = {for (final files in sources.values) ...files.keys};
  for (final name in names.toList()..sort()) {
    final keys = <String, Set<String>>{};
    for (final MapEntry(key: locale, value: files) in sources.entries) {
      final text = files[name];
      if (text == null) {
        problems.add('$name manca in $locale');
        continue;
      }
      keys[locale] = {
        for (final k in _parse('$locale/$name', text).keys)
          if (!k.startsWith('@')) k,
      };
    }
    final all = {for (final set in keys.values) ...set};
    for (final MapEntry(key: locale, value: set) in keys.entries) {
      for (final k in all.difference(set).toList()..sort()) {
        problems.add('$locale/$name: manca la chiave "$k"');
      }
    }
  }
  return problems;
}

/// Legge `<cartella>/<lingua>/*.arb`.
Map<String, Map<String, String>> readSources(Directory root) {
  final sources = <String, Map<String, String>>{};
  for (final dir in root.listSync().whereType<Directory>()) {
    sources[dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty)] = {
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('.arb'))
          f.uri.pathSegments.last: f.readAsStringSync(),
    };
  }
  return sources;
}

Map<String, Object?> _parse(String name, String text) {
  try {
    return (jsonDecode(text) as Map).cast<String, Object?>();
  } on FormatException catch (e) {
    throw FormatException('$name: JSON non valido (${e.message})');
  } on TypeError {
    throw FormatException('$name: ci si aspetta un oggetto JSON');
  }
}
