import 'dart:convert';
import 'dart:io';

/// Unisce i file `.arb` di una lingua (uno per funzione) nel file unico che il
/// generatore di Flutter richiede. `@@locale` si aggiunge qui e per primo.
///
/// Con [fallback] (i file di un'altra lingua, di solito l'inglese) le chiavi
/// che mancano si riempiono da lì, così una lingua incompleta non rompe la
/// compilazione.
String mergeArbs(
  String locale,
  Map<String, String> files, {
  Map<String, String>? fallback,
}) {
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
  if (fallback != null) {
    final own = {...merged.keys};
    for (final name in fallback.keys.toList()..sort()) {
      for (final entry in _parse('ripiego/$name', fallback[name]!).entries) {
        if (entry.key == '@@locale') continue;
        final base = entry.key.replaceFirst('@', '');
        if (!own.contains(base)) merged[entry.key] = entry.value;
      }
    }
  }
  return '${const JsonEncoder.withIndent('  ').convert(merged)}\n';
}

/// Problemi di coerenza tra le lingue: stessi file e, in ciascuno, stesse chiavi.
/// Le lingue in [tolerant] (ancora in lavorazione) possono avere meno file e
/// meno chiavi, ma non chiavi che le altre lingue non hanno.
List<String> checkLocales(
  Map<String, Map<String, String>> sources, {
  Set<String> tolerant = const {},
}) {
  final problems = <String>[];
  final names = {for (final files in sources.values) ...files.keys};
  for (final name in names.toList()..sort()) {
    final keys = <String, Set<String>>{};
    for (final MapEntry(key: locale, value: files) in sources.entries) {
      final text = files[name];
      if (text == null) {
        if (!tolerant.contains(locale)) problems.add('$name manca in $locale');
        continue;
      }
      keys[locale] = {
        for (final k in _parse('$locale/$name', text).keys)
          if (!k.startsWith('@')) k,
      };
    }
    final complete = {
      for (final e in keys.entries)
        if (!tolerant.contains(e.key)) ...e.value,
    };
    for (final MapEntry(key: locale, value: set) in keys.entries) {
      final isTolerant = tolerant.contains(locale);
      if (!isTolerant) {
        final all = {for (final set in keys.values) ...set};
        for (final k in all.difference(set).toList()..sort()) {
          problems.add('$locale/$name: manca la chiave "$k"');
        }
      } else {
        for (final k in set.difference(complete).toList()..sort()) {
          problems.add(
            '$locale/$name: la chiave "$k" non esiste nelle altre lingue',
          );
        }
      }
    }
  }
  return problems;
}

/// Legge `<cartella>/<lingua>/*.arb`; le cartelle senza `.arb` non sono lingue.
Map<String, Map<String, String>> readSources(Directory root) {
  final sources = <String, Map<String, String>>{};
  for (final dir in root.listSync().whereType<Directory>()) {
    sources[dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty)] = {
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('.arb'))
          f.uri.pathSegments.last: f.readAsStringSync(),
    };
  }
  sources.removeWhere((_, files) => files.isEmpty);
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

/// Stato di una lingua in `tool/lingue.json`.
enum LanguageState {
  base('base'),
  ready('pronta'),
  beta('beta'),
  inProgress('in lavorazione');

  const LanguageState(this.label);
  final String label;
}

/// Legge `tool/lingue.json`: `{"it": "base", "en": "pronta", ...}`.
Map<String, LanguageState> parseLanguageStates(String text) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException catch (e) {
    throw FormatException('tool/lingue.json: JSON non valido (${e.message})');
  }
  if (json is! Map) {
    throw const FormatException('tool/lingue.json: ci si aspetta un oggetto');
  }
  return {
    for (final MapEntry(key: locale, value: label) in json.entries)
      locale as String: LanguageState.values.firstWhere(
        (s) => s.label == label,
        orElse: () => throw FormatException(
          'tool/lingue.json: stato "$label" sconosciuto per "$locale"',
        ),
      ),
  };
}

/// Lingue a cui è concesso essere incomplete (beta e in lavorazione).
Set<String> tolerantLocales(Map<String, LanguageState> states) => {
  for (final e in states.entries)
    if (e.value == LanguageState.beta || e.value == LanguageState.inProgress)
      e.key,
};

/// Quante chiavi della lingua base una lingua ha già tradotto.
class Coverage {
  Coverage(this.total, this.translated, this.missing);

  final int total;
  final int translated;

  /// Chiavi mancanti per file.
  final Map<String, List<String>> missing;

  double get percent => total == 0 ? 100 : translated * 100 / total;
}

/// Copertura di ogni lingua rispetto alla lingua [base].
Map<String, Coverage> coverage(
  Map<String, Map<String, String>> sources, {
  required String base,
}) {
  Set<String> keysOf(String locale, String name) {
    final text = sources[locale]?[name];
    if (text == null) return {};
    return {
      for (final k in _parse('$locale/$name', text).keys)
        if (!k.startsWith('@')) k,
    };
  }

  final baseFiles = sources[base] ?? const {};
  final result = <String, Coverage>{};
  for (final locale in sources.keys) {
    var total = 0;
    var translated = 0;
    final missing = <String, List<String>>{};
    for (final name in baseFiles.keys.toList()..sort()) {
      final want = keysOf(base, name);
      final have = keysOf(locale, name);
      total += want.length;
      translated += want.intersection(have).length;
      final lacking = (want.difference(have).toList()..sort());
      if (lacking.isNotEmpty) missing[name] = lacking;
    }
    result[locale] = Coverage(total, translated, missing);
  }
  return result;
}
