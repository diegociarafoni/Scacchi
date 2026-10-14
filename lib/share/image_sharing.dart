import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import 'share_temp.dart';

/// Consegna un PNG al menu di condivisione; nei test si sostituisce.
typedef ShareImage = Future<void> Function(Uint8List png, String fileName);

/// Scrive [png] in un file temporaneo e apre il menu di condivisione del
/// sistema. Il file non si elimina subito (il sistema può leggerlo dopo il
/// ritorno di `share()`): lo ripulisce [clearShareTemp].
///
/// Su iPad il menu si ancora a [origin], che di solito è il pulsante premuto.
Future<void> shareImageWithSystem(
  Uint8List png,
  String fileName, {
  String? subject,
  Rect? origin,
}) async {
  final file = await newShareTempFile(fileName);
  await file.writeAsBytes(png, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      subject: subject,
      sharePositionOrigin: origin,
    ),
  );
}

/// Disegna in un PNG il [RepaintBoundary] che sta sotto [key], o `null` se non
/// è sullo schermo.
Future<Uint8List?> capturePng(
  GlobalKey key, {
  required double pixelRatio,
}) async {
  final boundary = key.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return null;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
