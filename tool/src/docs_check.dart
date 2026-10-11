/// Controlli sulla documentazione: link, percorsi citati, indice e mappa del
/// codice. Lavora su testi già letti, così i test non toccano il disco.
library;

/// Cartelle radice dei percorsi citati tra apici inversi che si verificano.
const checkedRoots = {
  'lib',
  'test',
  'tool',
  'integration_test',
  'docs',
  'assets',
  'android',
  'ios',
  'linux',
  'macos',
  'windows',
  '.github',
};

const indexPath = 'docs/README.md';
const mapPath = 'docs/mappa-del-codice.md';

/// Problemi trovati in [docs] (percorso → testo). [exists] dice se un file o
/// una cartella del repository esiste; [libDirs] sono le cartelle di primo
/// livello di `lib/`, come `lib/game/`.
List<String> checkDocs({
  required Map<String, String> docs,
  required bool Function(String path) exists,
  required Iterable<String> libDirs,
}) {
  final problems = <String>[];
  for (final MapEntry(key: path, value: text) in docs.entries) {
    final lines = _proseLines(text);
    for (final (number, line) in lines) {
      final where = '$path:$number';
      for (final m in RegExp(r'\]\(([^)\s]+)\)').allMatches(line)) {
        final problem = _checkLink(path, m[1]!, docs, exists);
        if (problem != null) problems.add('$where $problem');
      }
      for (final m in RegExp('`([^`]+)`').allMatches(line)) {
        final cited = _citedPath(m[1]!);
        if (cited != null && !exists(cited)) {
          problems.add('$where percorso inesistente: ${m[1]}');
        }
      }
    }
  }
  problems
    ..addAll(_checkIndex(docs))
    ..addAll(_checkMap(docs, libDirs));
  return problems;
}

/// Ancora di un titolo come la calcola GitHub.
String headingSlug(String heading) => heading
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N} _-]', unicode: true), '')
    .replaceAll(' ', '-');

/// Ancore dei titoli di [text], con i suffissi `-1`, `-2` dei duplicati.
Set<String> headingAnchors(String text) {
  final seen = <String, int>{};
  final anchors = <String>{};
  for (final (_, line) in _proseLines(text)) {
    final m = RegExp(r'^#{1,6}\s+(.*?)\s*#*\s*$').firstMatch(line);
    if (m == null) continue;
    final slug = headingSlug(m[1]!);
    final count = seen[slug] ?? 0;
    seen[slug] = count + 1;
    anchors.add(count == 0 ? slug : '$slug-$count');
  }
  return anchors;
}

/// Righe numerate fuori dai blocchi di codice recintati.
List<(int, String)> _proseLines(String text) {
  final result = <(int, String)>[];
  var fenced = false;
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith('```')) {
      fenced = !fenced;
      continue;
    }
    if (!fenced) result.add((i + 1, lines[i]));
  }
  return result;
}

String? _checkLink(
  String from,
  String target,
  Map<String, String> docs,
  bool Function(String) exists,
) {
  if (RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false).hasMatch(target)) {
    return null;
  }
  final hash = target.indexOf('#');
  final file = hash < 0 ? target : target.substring(0, hash);
  final anchor = hash < 0
      ? null
      : Uri.decodeComponent(target.substring(hash + 1));
  final resolved = file.isEmpty ? from : _resolve(from, file);
  if (resolved == null) return 'link fuori dal repository: $target';
  if (!exists(resolved)) return 'link rotto: $target';
  if (anchor != null && anchor.isNotEmpty && resolved.endsWith('.md')) {
    final text = docs[resolved];
    if (text != null && !headingAnchors(text).contains(anchor)) {
      return 'ancora inesistente: $target';
    }
  }
  return null;
}

/// Percorso di [target] relativo al file [from], o `null` se esce dalla radice.
String? _resolve(String from, String target) {
  final parts = from.split('/')..removeLast();
  for (final segment in target.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (parts.isEmpty) return null;
      parts.removeLast();
    } else {
      parts.add(segment);
    }
  }
  return parts.join('/');
}

/// Percorso da verificare in un testo tra apici inversi, se lo è.
/// Si escludono segnaposto e glob (`app_<codice>.arb`, `*.dart`).
String? _citedPath(String code) {
  if (code.contains(RegExp(r'[\s<>*{}$]'))) return null;
  final root = code.split('/').first;
  if (!code.contains('/') || !checkedRoots.contains(root)) return null;
  // `lib/game/clock.dart:42` cita una riga: conta il file.
  final path = code.replaceFirst(RegExp(r':\d+(-\d+)?$'), '');
  return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
}

Iterable<String> _checkIndex(Map<String, String> docs) sync* {
  final index = docs[indexPath];
  if (index == null) {
    yield '$indexPath manca';
    return;
  }
  for (final path in docs.keys) {
    if (!path.startsWith('docs/') || path == indexPath) continue;
    final name = path.substring('docs/'.length);
    if (name.contains('/') || !name.endsWith('.md')) continue;
    if (!index.contains('($name)')) {
      yield '$indexPath: $name non è nell\'indice';
    }
  }
}

Iterable<String> _checkMap(
  Map<String, String> docs,
  Iterable<String> libDirs,
) sync* {
  final map = docs[mapPath];
  if (map == null) {
    yield '$mapPath manca';
    return;
  }
  final mapped = <String, List<String>>{};
  for (final (number, line) in _proseLines(map)) {
    final m = RegExp(r'^\|\s*`(lib/[^`]+/)`\s*\|(.*)\|\s*$').firstMatch(line);
    if (m == null) continue;
    final targets = [
      for (final l in RegExp(r'\]\(([^)#\s]+)').allMatches(m[2]!)) l[1]!,
    ];
    if (targets.isEmpty) {
      yield '$mapPath:$number ${m[1]} senza documento';
    }
    mapped[m[1]!] = targets;
  }
  for (final dir in libDirs) {
    if (!mapped.containsKey(dir)) {
      yield '$mapPath: manca la riga per $dir, con il documento che la descrive';
    }
  }
  for (final dir in mapped.keys) {
    if (!libDirs.contains(dir)) {
      yield '$mapPath: $dir non esiste più in lib/';
    }
  }
}
