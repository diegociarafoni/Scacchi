import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Cartella dei file temporanei di condivisione. Su Android il sistema può
/// leggere il file anche dopo che `share()` è tornato, quindi non si elimina
/// subito: si ripulisce alla condivisione successiva e all'avvio.
Future<Directory> _shareDir(Directory? base) async {
  final root = base ?? await getTemporaryDirectory();
  return Directory('${root.path}/condivisione'); // l10n-ok
}

/// Toglie i file di condivisione rimasti da prima.
Future<void> clearShareTemp({Directory? base}) async {
  try {
    final dir = await _shareDir(base);
    if (dir.existsSync()) await dir.delete(recursive: true);
  } on FileSystemException catch (e) {
    // Lo toglie comunque il sistema con la cartella temporanea.
    if (kDebugMode) debugPrint('Pulizia dei file condivisi: $e'); // l10n-ok
  }
}

/// File vuoto [name] nella cartella di condivisione, ripulita dai precedenti.
Future<File> newShareTempFile(String name, {Directory? base}) async {
  await clearShareTemp(base: base);
  final dir = await _shareDir(base);
  await dir.create(recursive: true);
  return File('${dir.path}/$name');
}
