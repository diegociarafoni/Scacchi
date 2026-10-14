import 'dart:io';

import 'package:rokko/l10n/content.dart';

/// Contenuti di `assets/content/` letti dal disco, nella lingua [language].
Map<String, ContentText> contentFromDisk([String language = 'it']) {
  final base = Directory('assets/content/it');
  final names = [
    if (base.existsSync())
      for (final f in base.listSync().whereType<File>())
        if (f.path.endsWith('.json'))
          f.uri.pathSegments.last.replaceAll('.json', ''),
  ];
  return {
    for (final name in names)
      name: ContentText.fromMaps({
        for (final code in ContentText.fallbackChain(language))
          if (File('assets/content/$code/$name.json').existsSync())
            code: ContentText.parse(
              File('assets/content/$code/$name.json').readAsStringSync(),
              '$code/$name.json',
            ),
      }, language: language),
  };
}

/// Registra i contenuti in [language] per il resto del test.
void useContent([String language = 'it']) =>
    Content.use(contentFromDisk(language));
