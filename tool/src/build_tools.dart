/// Cartella più recente tra quelle di `build-tools` dell'SDK Android,
/// confrontando i numeri di versione; le anteprime (`-rc1`) vengono prima
/// della versione stabile. `null` se l'elenco è vuoto.
String? latestBuildTools(Iterable<String> names) {
  String? best;
  for (final name in names) {
    if (best == null || _compare(name, best) > 0) best = name;
  }
  return best;
}

int _compare(String a, String b) {
  final (av, ap) = _parse(a);
  final (bv, bp) = _parse(b);
  for (var i = 0; i < 3; i++) {
    final c = av[i].compareTo(bv[i]);
    if (c != 0) return c;
  }
  if (ap == bp) return 0;
  if (ap.isEmpty) return 1;
  if (bp.isEmpty) return -1;
  return ap.compareTo(bp);
}

(List<int>, String) _parse(String name) {
  final dash = name.indexOf('-');
  final version = dash < 0 ? name : name.substring(0, dash);
  final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  while (parts.length < 3) {
    parts.add(0);
  }
  return (parts, dash < 0 ? '' : name.substring(dash + 1));
}
