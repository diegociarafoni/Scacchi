/// Confronto fra i contenuti di una lingua e quelli italiani (base).
///
/// Ogni valore è un testo o una lista di testi (vedi `ContentText.parse`).
class ContentReport {
  ContentReport({
    required this.missing,
    required this.extra,
    required this.placeholders,
    required this.empty,
    required this.kind,
  });

  /// Id presenti in italiano e assenti nell'altra lingua.
  final List<String> missing;

  /// Id presenti solo nell'altra lingua.
  final List<String> extra;

  /// Id con segnaposto diversi dall'italiano.
  final List<String> placeholders;

  /// Id con testo vuoto o lista vuota (o con una frase vuota).
  final List<String> empty;

  /// Id che sono un testo in una lingua e una lista nell'altra.
  final List<String> kind;

  bool get isOk =>
      missing.isEmpty &&
      extra.isEmpty &&
      placeholders.isEmpty &&
      empty.isEmpty &&
      kind.isEmpty;

  String describe(String file) {
    final lines = [
      if (missing.isNotEmpty) 'manca: ${missing.join(', ')}',
      if (extra.isNotEmpty) 'in più: ${extra.join(', ')}',
      if (placeholders.isNotEmpty)
        'segnaposto diversi: ${placeholders.join(', ')}',
      if (empty.isNotEmpty) 'vuoti: ${empty.join(', ')}',
      if (kind.isNotEmpty) 'testo/lista: ${kind.join(', ')}',
    ];
    return '$file\n  ${lines.join('\n  ')}';
  }
}

final _placeholder = RegExp(r'\{(\w+)\}');

Set<String> _names(Object value) => {
  for (final text in value is List ? value : [value])
    for (final m in _placeholder.allMatches(text as String)) m.group(1)!,
};

bool _isEmpty(Object value) => value is List
    ? value.isEmpty || value.any((s) => (s as String).trim().isEmpty)
    : (value as String).trim().isEmpty;

/// Confronta [other] con la base italiana [base].
ContentReport compareContent(
  Map<String, Object> base,
  Map<String, Object> other,
) {
  final shared = [
    for (final id in base.keys)
      if (other.containsKey(id)) id,
  ]..sort();
  bool differs(Set<String> a, Set<String> b) =>
      a.length != b.length || !a.containsAll(b);
  return ContentReport(
    missing: [
      for (final id in base.keys)
        if (!other.containsKey(id)) id,
    ]..sort(),
    extra: [
      for (final id in other.keys)
        if (!base.containsKey(id)) id,
    ]..sort(),
    placeholders: [
      for (final id in shared)
        if (differs(_names(base[id]!), _names(other[id]!))) id,
    ],
    empty: [
      for (final id in shared)
        if (_isEmpty(other[id]!)) id,
    ],
    kind: [
      for (final id in shared)
        if ((base[id]! is List) != (other[id]! is List)) id,
    ],
  );
}
