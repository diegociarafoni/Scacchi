import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Cartella delle foto di sfondo, dentro quella dei dati dell'app.
Future<Directory> backdropPhotoDirectory() async {
  final root = await getApplicationSupportDirectory();
  return Directory('${root.path}/stile');
}

/// Nome del file di un percorso di foto: è l'unica parte che si salva nelle
/// impostazioni.
String backdropPhotoName(String path) => path.split(RegExp(r'[\\/]')).last;

/// Sceglie una foto dalla galleria e la copia nella cartella dati dell'app,
/// ridotta: non esce mai dal telefono e Android la esclude dai backup. Restituisce il
/// percorso, o null se si annulla; una foto illeggibile solleva un errore.
Future<String?> pickBackdropPhoto() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 80,
  );
  if (picked == null) return null;
  final dir = await backdropPhotoDirectory()
    ..createSync(recursive: true);
  // Un nome nuovo a ogni scelta: la cache delle immagini non serve la vecchia.
  final target = File(
    '${dir.path}/sfondo-${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  await File(picked.path).copy(target.path);
  return target.path;
}

/// Toglie dalla cartella delle foto quelle diverse da [keep]: si chiama solo
/// dopo aver salvato la scelta, così un errore non lascia l'impostazione senza
/// il suo file.
Future<void> pruneBackdropPhotos(String keep) async {
  final dir = File(keep).parent;
  if (!dir.path.endsWith('/stile') || !dir.existsSync()) return;
  for (final old in dir.listSync().whereType<File>()) {
    if (old.path != keep) old.deleteSync();
  }
}
