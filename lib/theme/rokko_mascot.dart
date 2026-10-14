import 'package:flutter/material.dart';

/// Torre sorridente di Rokko, la stessa dell'icona (`tool/generate_icons.py`).
/// Solo decorativa: non ha testo per i lettori di schermo.
class RokkoMascot extends StatelessWidget {
  const RokkoMascot({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: const _RookPainter()),
  );
}

/// Stato vuoto: la torre sopra una frase breve che dice cosa fare.
class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RokkoMascot(),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    ),
  );
}

const _orange = Color(0xFFF2994A);
const _brown = Color(0xFF8A3B12);

class _RookPainter extends CustomPainter {
  const _RookPainter();

  // Coordinate della griglia da 108 dp dell'icona, ritagliate sulla torre.
  static const _left = 36.0;
  static const _top = 33.0;
  static const _side = 36.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..scale(size.width / _side, size.height / _side)
      ..translate(-_left, -_top);
    final body = Paint()..color = _orange;
    final face = Paint()..color = _brown;

    canvas.drawRRect(
      RRect.fromLTRBR(37, 69, 71, 77, const Radius.circular(3)),
      body,
    );
    canvas.drawPath(
      Path()
        ..moveTo(42, 46)
        ..lineTo(66, 46)
        ..lineTo(68.5, 69)
        ..lineTo(39.5, 69)
        ..close(),
      body,
    );
    canvas.drawPath(
      Path()
        ..moveTo(38, 47)
        ..lineTo(38, 36.5)
        ..arcToPoint(const Offset(40.5, 34), radius: const Radius.circular(2.5))
        ..lineTo(45.5, 34)
        ..lineTo(45.5, 39.5)
        ..lineTo(51, 39.5)
        ..lineTo(51, 34)
        ..lineTo(57, 34)
        ..lineTo(57, 39.5)
        ..lineTo(62.5, 39.5)
        ..lineTo(62.5, 34)
        ..lineTo(67.5, 34)
        ..arcToPoint(const Offset(70, 36.5), radius: const Radius.circular(2.5))
        ..lineTo(70, 47)
        ..close(),
      body,
    );
    canvas
      ..drawCircle(const Offset(49, 55), 3, face)
      ..drawCircle(const Offset(59, 55), 3, face)
      ..drawPath(
        Path()
          ..moveTo(49.5, 61.5)
          ..quadraticBezierTo(54, 65.5, 58.5, 61.5),
        Paint()
          ..color = _brown
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_RookPainter oldDelegate) => false;
}
