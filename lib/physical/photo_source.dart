import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import 'board_photo.dart';

/// Da dove arriva la foto della scacchiera.
abstract interface class PhotoSource {
  /// Scatta una foto con la fotocamera; null se si annulla.
  Future<Uint8List?> take();
}

/// Fotocamera di sistema: l'immagine resta sul telefono e non viene salvata.
class CameraPhotoSource implements PhotoSource {
  const CameraPhotoSource();

  @override
  Future<Uint8List?> take() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    return file?.readAsBytes();
  }
}

/// Decodifica [bytes] in toni di grigio con il lato lungo al massimo di
/// [maxSide] punti; null se non è un'immagine leggibile.
Future<BoardFrame?> decodeFrame(Uint8List bytes, {int maxSide = 480}) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    // Le foto piccole non si ingrandiscono.
    final scale = math.min(
      1.0,
      maxSide / math.max(descriptor.width, descriptor.height),
    );
    codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * scale).round().clamp(1, maxSide),
      targetHeight: (descriptor.height * scale).round().clamp(1, maxSide),
    );
    image = (await codec.getNextFrame()).image;
    final data = await image.toByteData();
    if (data == null) return null;
    final rgba = data.buffer.asUint8List();
    final luma = Uint8List(image.width * image.height);
    for (var i = 0; i < luma.length; i++) {
      luma[i] =
          (rgba[i * 4] * 299 + rgba[i * 4 + 1] * 587 + rgba[i * 4 + 2] * 114) ~/
          1000;
    }
    return BoardFrame(width: image.width, height: image.height, luma: luma);
  } on Object {
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}
