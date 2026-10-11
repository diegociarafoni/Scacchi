// Ordine rilevante: i testi più specifici prima di quelli che li contengono.
final _patterns = <String, List<RegExp>>{
  'AGPL-3.0': [
    RegExp('GNU AFFERO GENERAL PUBLIC LICENSE', caseSensitive: false),
  ],
  'LGPL-3.0': [
    RegExp('GNU LESSER GENERAL PUBLIC LICENSE', caseSensitive: false),
    RegExp(r'Version 3'),
  ],
  'LGPL-2.1': [
    RegExp('GNU LESSER GENERAL PUBLIC LICENSE', caseSensitive: false),
    RegExp(r'Version 2\.1'),
  ],
  'GPL-3.0': [
    RegExp('GNU GENERAL PUBLIC LICENSE', caseSensitive: false),
    RegExp(r'Version 3'),
  ],
  'GPL-2.0': [
    RegExp('GNU GENERAL PUBLIC LICENSE', caseSensitive: false),
    RegExp(r'Version 2'),
  ],
  'MPL-2.0': [RegExp('Mozilla Public License,? (Version|v\\.?) ?2\\.0')],
  'Apache-2.0': [
    RegExp(r'Apache License,?\s+Version 2\.0', caseSensitive: false),
  ],
  'BSD-3-Clause': [
    RegExp('Redistribution and use in source and binary forms'),
    RegExp(r'(Neither the name|names of its\s+contributors)'),
  ],
  'BSD-2-Clause': [RegExp('Redistribution and use in source and binary forms')],
  'MIT': [RegExp('Permission is hereby granted, free of charge')],
  'ISC': [
    RegExp(
      'Permission to use, copy, modify, and(/or)? distribute this software',
    ),
  ],
  'Zlib': [
    RegExp("This software is provided 'as-is', without any express or implied"),
  ],
  'Unlicense': [RegExp('This is free and unencumbered software')],
};

// Le licenze GNU si citano a vicenda nel testo: conta solo il titolo iniziale.
const _gnuHeaderLength = 400;

/// Identificativo SPDX dedotto dal testo della licenza, oppure `null`.
String? detectLicense(String text) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final header = normalized.length > _gnuHeaderLength
      ? normalized.substring(0, _gnuHeaderLength)
      : normalized;
  for (final entry in _patterns.entries) {
    final source = entry.key.contains('GPL') ? header : normalized;
    if (entry.value.every((p) => p.hasMatch(source))) return entry.key;
  }
  return null;
}

bool isAllowed(String? spdx, Set<String> allowed) =>
    spdx != null && allowed.contains(spdx);
