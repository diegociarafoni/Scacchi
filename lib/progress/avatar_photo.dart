import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { gallery, camera }

/// La foto non si è potuta ottenere, per esempio permesso negato.
class PhotoUnavailable implements Exception {
  const PhotoUnavailable();
}

/// Sceglie una foto per il profilo (RP-09); `null` se si annulla.
abstract interface class PhotoPicker {
  Future<Uint8List?> pick(PhotoSource source);
}

/// Lato massimo della foto salvata: basta per un cerchio e tiene il file
/// piccolo.
const avatarPhotoMaxSide = 512.0;

/// Selettore di sistema: la galleria non chiede permessi all'app, la
/// fotocamera chiede il permesso solo quando la si sceglie.
class SystemPhotoPicker implements PhotoPicker {
  const SystemPhotoPicker();

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: avatarPhotoMaxSide,
        maxHeight: avatarPhotoMaxSide,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      return await file?.readAsBytes();
    } on Exception {
      throw const PhotoUnavailable();
    }
  }
}
