import 'dart:math';

import 'package:flutter/material.dart';

import 'badge_def.dart';

/// Colori di una famiglia: chiaro in alto a sinistra, scuro in basso a destra.
(Color, Color) badgePalette(BadgeFamily family) => switch (family) {
  BadgeFamily.learn => (const Color(0xFF6366F1), const Color(0xFF312E81)),
  BadgeFamily.puzzles => (const Color(0xFFA855F7), const Color(0xFF581C87)),
  BadgeFamily.games => (const Color(0xFFFB7185), const Color(0xFF9F1239)),
  BadgeFamily.story => (const Color(0xFF2DD4BF), const Color(0xFF115E59)),
  BadgeFamily.habit => (const Color(0xFFFBBF24), const Color(0xFF92400E)),
};

/// Contorno della medaglia: ogni famiglia ha la sua sagoma.
Path badgeShape(BadgeFamily family, Rect box) {
  final c = box.center;
  final r = box.shortestSide / 2;
  switch (family) {
    case BadgeFamily.learn:
      // Scudo: spalle larghe e punta in basso.
      return Path()
        ..moveTo(box.left + r * 0.12, box.top + r * 0.2)
        ..quadraticBezierTo(
          c.dx,
          box.top - r * 0.1,
          box.right - r * 0.12,
          box.top + r * 0.2,
        )
        ..lineTo(box.right - r * 0.12, box.top + r * 1.0)
        ..quadraticBezierTo(
          box.right - r * 0.12,
          box.top + r * 1.65,
          c.dx,
          box.bottom,
        )
        ..quadraticBezierTo(
          box.left + r * 0.12,
          box.top + r * 1.65,
          box.left + r * 0.12,
          box.top + r * 1.0,
        )
        ..close();
    case BadgeFamily.puzzles:
      return _polygon(c, r, 6, rotation: pi / 6);
    case BadgeFamily.games:
      // Rombo smussato, come una casa della scacchiera ruotata.
      final square = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: c, radius: r * 0.78),
            Radius.circular(r * 0.3),
          ),
        );
      final turn = Matrix4.identity()
        ..translateByDouble(c.dx, c.dy, 0, 1)
        ..rotateZ(pi / 4)
        ..translateByDouble(-c.dx, -c.dy, 0, 1);
      return square.transform(turn.storage);
    case BadgeFamily.story:
      return Path()..addOval(Rect.fromCircle(center: c, radius: r));
    case BadgeFamily.habit:
      return _rosette(c, r, 12);
  }
}

Path _polygon(Offset c, double r, int sides, {double rotation = 0}) {
  final path = Path();
  for (var i = 0; i < sides; i++) {
    final a = rotation + 2 * pi * i / sides - pi / 2;
    final p = c + Offset(cos(a), sin(a)) * r;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

Path _rosette(Offset c, double r, int bumps) {
  final path = Path();
  const steps = 96;
  for (var i = 0; i <= steps; i++) {
    final a = 2 * pi * i / steps;
    final radius = r * (0.92 + 0.08 * cos(bumps * a));
    final p = c + Offset(cos(a), sin(a)) * radius;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// Medaglia disegnata in codice: sagoma e colore della famiglia, bordo del
/// gradino, riflesso e simbolo. Da ottenere è grigia con il lucchetto.
class BadgeArt extends StatelessWidget {
  const BadgeArt({
    super.key,
    required this.badge,
    required this.earned,
    required this.size,
  });

  final BadgeDef badge;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _MedalPainter(
              family: badge.family,
              tier: badge.tier,
              earned: earned,
              locked: scheme.surfaceContainerHighest,
              lockedEdge: scheme.outlineVariant,
            ),
          ),
          Icon(
            earned ? badge.icon : Icons.lock_rounded,
            size: size * (earned ? 0.46 : 0.36),
            color: earned ? Colors.white : scheme.onSurfaceVariant,
            shadows: earned
                ? const [
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 3,
                      offset: Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
        ],
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter({
    required this.family,
    required this.tier,
    required this.earned,
    required this.locked,
    required this.lockedEdge,
  });

  final BadgeFamily family;
  final BadgeTier tier;
  final bool earned;
  final Color locked;
  final Color lockedEdge;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final inner = box.deflate(size.width * 0.05);
    final shape = badgeShape(family, inner);
    if (!earned) {
      canvas
        ..drawPath(shape, Paint()..color = locked)
        ..drawPath(
          shape,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.03
            ..color = lockedEdge,
        );
      return;
    }
    final (light, dark) = badgePalette(family);
    canvas
      ..drawShadow(shape, const Color(0xFF000000), size.width * 0.04, true)
      ..drawPath(
        shape,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [light, dark],
          ).createShader(inner),
      );
    // Riflesso morbido sulla metà alta.
    canvas
      ..save()
      ..clipPath(shape)
      ..drawOval(
        Rect.fromLTWH(
          inner.left - inner.width * 0.1,
          inner.top - inner.height * 0.5,
          inner.width * 1.2,
          inner.height * 0.95,
        ),
        Paint()..color = const Color(0x2EFFFFFF),
      )
      ..restore();
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045
        ..color = _rim(),
    );
  }

  Color _rim() => switch (tier) {
    BadgeTier.none => const Color(0x66FFFFFF),
    BadgeTier.bronze => const Color(0xFFCD7F32),
    BadgeTier.silver => const Color(0xFFE5E7EB),
    BadgeTier.gold => const Color(0xFFFFD700),
  };

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.family != family ||
      old.tier != tier ||
      old.earned != earned ||
      old.locked != locked ||
      old.lockedEdge != lockedEdge;
}
