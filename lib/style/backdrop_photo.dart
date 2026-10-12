import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Sceglie una foto dalla galleria e la copia nella cartella dati dell'app,
/// ridotta: non esce mai dal telefono e non entra nel backup. Restituisce il
/// percorso, o null se si annulla; una foto illeggibile solleva un errore.
Future<String?> pickBackdropPhoto() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 80,
  );
  if (picked == null) return null;
  final root = await getApplicationSupportDirectory();
  final dir = Directory('${root.path}/stile')..createSync(recursive: true);
  // Un nome nuovo a ogni scelta: la cache delle immagini non serve la vecchia.
  final target = File(
    '${dir.path}/sfondo-${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  await File(picked.path).copy(target.path);
  for (final old in dir.listSync().whereType<File>()) {
    if (old.path != target.path) old.deleteSync();
  }
  return target.path;
}
