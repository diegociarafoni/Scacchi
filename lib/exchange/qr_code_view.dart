import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Matrice del QR di [data]. Correzione media: tollera riflessi sullo
/// schermo senza far crescere troppo il codice.
QrImage qrImage(String data) =>
    QrImage(QrCode(payload: QrPayload.fromString(data)));

/// Codice QR disegnato in Dart, nero su bianco con il margine bianco
/// richiesto dai lettori, qualunque sia il tema.
class QrCodeView extends StatelessWidget {
  const QrCodeView({
    super.key,
    required this.data,
    required this.label,
    this.image,
  });

  final String data;

  /// Matrice già calcolata per [data], per non ricalcolarla a ogni disegno.
  final QrImage? image;

  /// Descrizione per il lettore di schermo.
  final String label;

  @override
  Widget build(BuildContext context) {
    final image = this.image ?? qrImage(data);
    return Semantics(
      label: label,
      image: true,
      child: AspectRatio(
        aspectRatio: 1,
        // Livello a sé: ridisegna solo il QR quando cambia fotogramma.
        child: RepaintBoundary(
          child: ColoredBox(
            color: Colors.white,
            child: CustomPaint(painter: _QrPainter(image)),
          ),
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;

  // Zona di rispetto standard di 4 moduli per lato.
  static const _quiet = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final n = image.moduleCount;
    final module = size.shortestSide / (n + 2 * _quiet);
    final paint = Paint()..color = Colors.black;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (!image.isDark(r, c)) continue;
        // Mezzo pixel in più evita le righe sottili tra moduli vicini.
        canvas.drawRect(
          Rect.fromLTWH(
            (c + _quiet) * module,
            (r + _quiet) * module,
            module + 0.5,
            module + 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => !identical(old.image, image);
}
