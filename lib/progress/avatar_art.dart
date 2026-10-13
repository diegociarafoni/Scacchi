import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar.dart';

const _space = [Color(0xff3949ab), Color(0xff7e57c2)];
const _star = Color(0xffffd54f);
const _ink = Color(0xff1f1a3a);
const _blush = Color(0x80ff8aa5);

/// Disegna un [AvatarCharacter] in un quadrato di lato [size]: sfondo
/// spaziale, testa tonda, occhioni e guance. Tutto in codice, senza immagini.
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({
    super.key,
    required this.character,
    required this.size,
    this.expression = AvatarExpression.neutral,
    this.background = true,
  });

  final AvatarCharacter character;
  final double size;
  final AvatarExpression expression;

  /// Sfondo spaziale tondo; senza, il personaggio si disegna su ciò che c'è
  /// dietro.
  final bool background;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.square(size),
      painter: _CharacterPainter(character, expression, background),
    ),
  );
}

class _CharacterPainter extends CustomPainter {
  const _CharacterPainter(this.character, this.expression, this.background);

  final AvatarCharacter character;
  final AvatarExpression expression;
  final bool background;

  @override
  void paint(Canvas canvas, Size size) {
    // Si disegna su 100×100 e si scala, così le proporzioni non dipendono
    // dalla dimensione.
    canvas.scale(size.width / 100);
    if (background) {
      canvas.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, 100, 100)));
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 100, 100),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _space,
          ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
      );
      _stars(canvas);
    }
    switch (character) {
      case AvatarCharacter.chick:
        _chick(canvas);
      case AvatarCharacter.fox:
        _fox(canvas);
      case AvatarCharacter.flower:
        _flower(canvas);
      case AvatarCharacter.owl:
        _owl(canvas);
      case AvatarCharacter.astroCat:
        _astroCat(canvas);
      case AvatarCharacter.rabbit:
        _rabbit(canvas);
      case AvatarCharacter.dragon:
        _dragon(canvas);
      case AvatarCharacter.eagle:
        _eagle(canvas);
      case AvatarCharacter.wolf:
        _wolf(canvas);
      case AvatarCharacter.star:
        _starFace(canvas);
      case AvatarCharacter.butterfly:
        _butterfly(canvas);
      case AvatarCharacter.turtle:
        _turtle(canvas);
      case AvatarCharacter.violet:
        _violet(canvas);
      case AvatarCharacter.lion:
        _lion(canvas);
      case AvatarCharacter.bear:
        _bear(canvas);
      case AvatarCharacter.raccoon:
        _raccoon(canvas);
      case AvatarCharacter.astronomer:
        _astronomer(canvas);
      case AvatarCharacter.hatchling:
        _hatchling(canvas);
    }
    _extras(canvas);
  }

  bool get _arcEyes =>
      expression == AvatarExpression.happy ||
      expression == AvatarExpression.greeting;
  bool get _neutral => expression == AvatarExpression.neutral;

  void _stars(Canvas c) {
    final p = Paint()..color = const Color(0x99ffffff);
    for (final (x, y, r) in const [
      (14.0, 18.0, 1.6),
      (84.0, 14.0, 1.2),
      (90.0, 46.0, 1.5),
      (10.0, 60.0, 1.1),
      (76.0, 88.0, 1.3),
    ]) {
      c.drawCircle(Offset(x, y), r, p);
    }
  }

  Paint _fill(Color color) => Paint()..color = color;

  void _eyes(Canvas c, {double y = 52, double gap = 13, double r = 5.5}) {
    for (final x in [50 - gap, 50 + gap]) {
      if (_arcEyes) {
        _arc(c, Offset(x, y + r * 0.4), r * 1.6, r * 1.3, math.pi, math.pi);
      } else {
        final big = expression == AvatarExpression.surprised ? 1.3 : 1.0;
        c.drawCircle(Offset(x, y), r * big, _fill(_ink));
        c.drawCircle(
          Offset(x + r * 0.35, y - r * 0.35),
          r * 0.38 * big,
          _fill(Colors.white),
        );
      }
    }
    _brows(c, y - r * 1.9, gap);
  }

  void _arc(
    Canvas c,
    Offset center,
    double w,
    double h,
    double from,
    double sweep,
  ) {
    c.drawArc(
      Rect.fromCenter(center: center, width: w, height: h),
      from,
      sweep,
      false,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Sopracciglia: raccontano incoraggiamento, sfida e stupore.
  void _brows(Canvas c, double y, double gap) {
    final (inner, outer) = switch (expression) {
      AvatarExpression.encouraging => (-2.5, 0.5),
      AvatarExpression.challenge => (2.5, -1.0),
      AvatarExpression.surprised => (-3.0, -3.0),
      _ => (null, null),
    };
    if (inner == null || outer == null) return;
    final p = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final s in [-1.0, 1.0]) {
      c.drawLine(
        Offset(50 + s * (gap - 5), y + inner),
        Offset(50 + s * (gap + 5), y + outer),
        p,
      );
    }
  }

  void _cheeks(Canvas c, {double y = 63, double gap = 21}) {
    for (final x in [50 - gap, 50 + gap]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 9, height: 6),
        _fill(_blush),
      );
    }
  }

  void _smile(Canvas c, {double y = 63}) {
    switch (expression) {
      case AvatarExpression.surprised:
        c.drawOval(
          Rect.fromCenter(center: Offset(50, y + 2), width: 6, height: 8),
          _fill(_ink),
        );
      case AvatarExpression.challenge:
        // Sorriso di sfida, un angolo più alto dell'altro.
        c.drawPath(
          Path()
            ..moveTo(44, y + 1)
            ..quadraticBezierTo(51, y + 5, 57, y - 2),
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      case AvatarExpression.happy || AvatarExpression.greeting:
        _arc(c, Offset(50, y - 1), 15, 11, 0.1, math.pi - 0.2);
      default:
        _arc(c, Offset(50, y), 10, 7, 0.2, math.pi - 0.4);
    }
  }

  /// Dettagli fuori dalla testa: saluto con la zampa, scintille, esclamazione.
  void _extras(Canvas c) {
    switch (expression) {
      case AvatarExpression.greeting:
        c.drawCircle(const Offset(88, 52), 6, _fill(_star));
        c.drawLine(
          const Offset(88, 52),
          const Offset(80, 70),
          Paint()
            ..color = _star
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      case AvatarExpression.encouraging:
        for (final (x, y, r) in const [(86.0, 24.0, 4.0), (92.0, 36.0, 2.5)]) {
          c.drawCircle(Offset(x, y), r, _fill(_star));
        }
      case AvatarExpression.surprised:
        final p = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        c.drawLine(const Offset(84, 14), const Offset(88, 22), p);
        c.drawLine(const Offset(92, 20), const Offset(95, 28), p);
        c.drawLine(const Offset(76, 10), const Offset(77, 19), p);
      default:
    }
  }

  Path _triangle(Offset a, Offset b, Offset d) => Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(b.dx, b.dy)
    ..lineTo(d.dx, d.dy)
    ..close();

  void _head(Canvas c, Color color, {double r = 31, double cy = 56}) =>
      c.drawCircle(Offset(50, cy), r, _fill(color));

  void _chick(Canvas c) {
    const yellow = _star;
    for (final dx in [-6.0, 0.0, 6.0]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(50 + dx, 22), width: 7, height: 14),
        _fill(yellow),
      );
    }
    _head(c, yellow);
    _eyes(c);
    _cheeks(c);
    c.drawPath(
      _triangle(
        const Offset(44, 59),
        const Offset(56, 59),
        const Offset(50, 69),
      ),
      _fill(const Color(0xffff9800)),
    );
  }

  void _fox(Canvas c) {
    const orange = Color(0xffef6c00);
    for (final s in [-1.0, 1.0]) {
      c.drawPath(
        _triangle(
          Offset(50 + s * 13, 34),
          Offset(50 + s * 32, 14),
          Offset(50 + s * 30, 44),
        ),
        _fill(orange),
      );
      c.drawPath(
        _triangle(
          Offset(50 + s * 19, 33),
          Offset(50 + s * 28, 21),
          Offset(50 + s * 28, 40),
        ),
        _fill(const Color(0xff3e2723)),
      );
    }
    _head(c, orange);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 69), width: 40, height: 24),
      _fill(Colors.white),
    );
    _eyes(c, y: 50);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 62), width: 9, height: 6),
      _fill(_ink),
    );
    _smile(c, y: 67);
  }

  void _flower(Canvas c) {
    const petal = Color(0xfff48fb1);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      c.drawCircle(
        Offset(50 + 30 * math.cos(a), 54 + 30 * math.sin(a)),
        13,
        _fill(petal),
      );
    }
    _head(c, _star, r: 23, cy: 54);
    _eyes(c, y: 51, gap: 9, r: 4.2);
    _cheeks(c, y: 60, gap: 15);
    _smile(c, y: 59);
  }

  void _owl(Canvas c) {
    const brown = Color(0xff8d6e63);
    for (final s in [-1.0, 1.0]) {
      c.drawPath(
        _triangle(
          Offset(50 + s * 10, 30),
          Offset(50 + s * 30, 16),
          Offset(50 + s * 31, 40),
        ),
        _fill(brown),
      );
    }
    _head(c, brown, r: 33);
    for (final x in [37.0, 63.0]) {
      c.drawCircle(Offset(x, 52), 13, _fill(Colors.white));
      if (_arcEyes) {
        _arc(c, Offset(x, 54), 12, 10, math.pi, math.pi);
      } else {
        final big = expression == AvatarExpression.surprised ? 0.7 : 1.0;
        c.drawCircle(Offset(x, 52), 6.5 * big, _fill(_ink));
        c.drawCircle(Offset(x + 2, 50), 2.2 * big, _fill(Colors.white));
      }
    }
    _brows(c, 36, 13);
    c.drawPath(
      _triangle(
        const Offset(45, 62),
        const Offset(55, 62),
        const Offset(50, 72),
      ),
      _fill(const Color(0xffffb300)),
    );
  }

  void _astroCat(Canvas c) {
    const grey = Color(0xffb0bec5);
    for (final s in [-1.0, 1.0]) {
      c.drawPath(
        _triangle(
          Offset(50 + s * 12, 36),
          Offset(50 + s * 27, 18),
          Offset(50 + s * 30, 46),
        ),
        _fill(grey),
      );
    }
    _head(c, grey, r: 27, cy: 57);
    _eyes(c, y: 54, gap: 11, r: 4.8);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 63), width: 6, height: 4),
      _fill(const Color(0xfff48fb1)),
    );
    _smile(c, y: 64);
    // Casco: vetro appena visibile e bordo chiaro.
    c.drawCircle(const Offset(50, 52), 38, _fill(const Color(0x22ffffff)));
    c.drawCircle(
      const Offset(50, 52),
      38,
      Paint()
        ..color = const Color(0xccffffff)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _rabbit(Canvas c) {
    const fur = Color(0xffeceff1);
    for (final s in [-1.0, 1.0]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(50 + s * 13, 24), width: 14, height: 38),
        _fill(fur),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(50 + s * 13, 25), width: 6, height: 28),
        _fill(const Color(0xfff8bbd0)),
      );
    }
    _head(c, fur, r: 29, cy: 60);
    _eyes(c, y: 56, gap: 12);
    _cheeks(c, y: 67);
    if (!_neutral) _smile(c, y: 68);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 63), width: 7, height: 5),
      _fill(const Color(0xfff48fb1)),
    );
  }

  void _dragon(Canvas c) {
    const green = Color(0xff43a047);
    for (final s in [-1.0, 1.0]) {
      c.drawPath(
        _triangle(
          Offset(50 + s * 14, 32),
          Offset(50 + s * 22, 14),
          Offset(50 + s * 26, 36),
        ),
        _fill(_star),
      );
    }
    _head(c, green);
    _eyes(c, y: 50);
    _cheeks(c, y: 62);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 66), width: 24, height: 15),
      _fill(const Color(0xffa5d6a7)),
    );
    for (final x in [45.0, 55.0]) {
      c.drawCircle(Offset(x, 65), 1.5, _fill(_ink));
    }
    // Una fiammella dal naso.
    c.drawPath(
      Path()
        ..moveTo(50, 80)
        ..quadraticBezierTo(42, 90, 50, 96)
        ..quadraticBezierTo(58, 90, 50, 80),
      _fill(const Color(0xffff7043)),
    );
  }

  void _eagle(Canvas c) {
    const brown = Color(0xff6d4c41);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 94), width: 86, height: 44),
      _fill(brown),
    );
    _head(c, Colors.white, r: 29, cy: 52);
    _eyes(c, y: 48, gap: 11, r: 4.5);
    _cheeks(c, y: 60, gap: 19);
    c.drawPath(
      Path()
        ..moveTo(41, 56)
        ..lineTo(59, 56)
        ..quadraticBezierTo(58, 68, 52, 74)
        ..quadraticBezierTo(50, 66, 41, 56)
        ..close(),
      _fill(const Color(0xffffb300)),
    );
  }

  void _wolf(Canvas c) {
    const grey = Color(0xff78909c);
    for (final s in [-1.0, 1.0]) {
      c.drawPath(
        _triangle(
          Offset(50 + s * 10, 34),
          Offset(50 + s * 30, 10),
          Offset(50 + s * 33, 46),
        ),
        _fill(const Color(0xff455a64)),
      );
    }
    _head(c, grey);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 68), width: 36, height: 24),
      _fill(const Color(0xffcfd8dc)),
    );
    _eyes(c, y: 50);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 61), width: 10, height: 7),
      _fill(_ink),
    );
    _smile(c, y: 67);
  }

  void _starFace(Canvas c) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 40.0 : 19.0;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(50 + r * math.cos(a), 54 + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    c.drawPath(path, _fill(_star));
    c.drawPath(
      path,
      Paint()
        ..color = _star
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round,
    );
    _eyes(c, y: 54, gap: 9, r: 4.5);
    _cheeks(c, y: 62, gap: 15);
    _smile(c, y: 61);
  }

  void _ring(Canvas c, Offset center, double r, Color color, double width) =>
      c.drawCircle(
        center,
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );

  void _butterfly(Canvas c) {
    const wing = Color(0xff4dd0e1);
    const wingLow = Color(0xffba68c8);
    for (final s in [-1.0, 1.0]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(50 + s * 27, 44), width: 38, height: 44),
        _fill(wing),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(50 + s * 22, 72), width: 28, height: 28),
        _fill(wingLow),
      );
      c.drawCircle(Offset(50 + s * 30, 42), 5, _fill(Colors.white54));
      final p = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(50 + s * 8, 34), Offset(50 + s * 14, 18), p);
      c.drawCircle(Offset(50 + s * 14, 18), 2.4, _fill(_star));
    }
    _head(c, const Color(0xffffccbc), r: 23, cy: 58);
    _eyes(c, y: 55, gap: 9, r: 4.2);
    _cheeks(c, y: 64, gap: 15);
    _smile(c);
  }

  void _turtle(Canvas c) {
    const shell = Color(0xff558b2f);
    const skin = Color(0xff9ccc65);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 80), width: 76, height: 40),
      _fill(shell),
    );
    for (final x in [30.0, 50.0, 70.0]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, 82), width: 14, height: 9),
        _fill(const Color(0xff7cb342)),
      );
    }
    _head(c, skin, r: 28, cy: 52);
    _eyes(c, y: 49, gap: 11, r: 4.6);
    _cheeks(c, y: 59, gap: 18);
    _smile(c, y: 58);
  }

  void _violet(Canvas c) {
    const petal = Color(0xff5e35b1);
    for (var i = 0; i < 5; i++) {
      final a = math.pi + (i + 0.5) * math.pi / 5;
      c.drawCircle(
        Offset(50 + 26 * math.cos(a), 56 + 26 * math.sin(a)),
        10,
        _fill(petal),
      );
    }
    _head(c, const Color(0xffede7f6), r: 27, cy: 58);
    _eyes(c, y: 56, gap: 10, r: 4.6);
    _cheeks(c, y: 66, gap: 17);
    _smile(c, y: 65);
    // Nota musicale.
    c.drawOval(
      Rect.fromCenter(center: const Offset(85, 30), width: 9, height: 7),
      _fill(_star),
    );
    c.drawLine(
      const Offset(89, 30),
      const Offset(89, 14),
      Paint()
        ..color = _star
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _lion(Canvas c) {
    const mane = Color(0xffa1632a);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      c.drawCircle(
        Offset(50 + 31 * math.cos(a), 54 + 31 * math.sin(a)),
        12,
        _fill(mane),
      );
    }
    _head(c, const Color(0xffffb74d), r: 26, cy: 55);
    for (final s in [-1.0, 1.0]) {
      c.drawCircle(Offset(50 + s * 20, 33), 6, _fill(const Color(0xffffb74d)));
    }
    _eyes(c, y: 51, gap: 10, r: 4.4);
    c.drawPath(
      _triangle(
        const Offset(45, 59),
        const Offset(55, 59),
        const Offset(50, 65),
      ),
      _fill(const Color(0xff6d4c41)),
    );
    _smile(c, y: 67);
  }

  void _bear(Canvas c) {
    const fur = Color(0xff6d4c41);
    for (final s in [-1.0, 1.0]) {
      c.drawCircle(Offset(50 + s * 25, 28), 11, _fill(fur));
      c.drawCircle(
        Offset(50 + s * 25, 28),
        5.5,
        _fill(const Color(0xffbcaaa4)),
      );
    }
    _head(c, fur, r: 32);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 68), width: 28, height: 21),
      _fill(const Color(0xffd7ccc8)),
    );
    _eyes(c, y: 50, r: 4.6);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 63), width: 10, height: 7),
      _fill(_ink),
    );
    _smile(c, y: 69);
  }

  void _raccoon(Canvas c) {
    const grey = Color(0xff90a4ae);
    const mask = Color(0xff37474f);
    for (final s in [-1.0, 1.0]) {
      c.drawPath(
        _triangle(
          Offset(50 + s * 13, 34),
          Offset(50 + s * 30, 16),
          Offset(50 + s * 31, 44),
        ),
        _fill(grey),
      );
    }
    _head(c, grey);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 38), width: 9, height: 16),
      _fill(Colors.white),
    );
    for (final s in [-1.0, 1.0]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(50 + s * 14, 53), width: 24, height: 17),
        _fill(mask),
      );
      c.drawCircle(Offset(50 + s * 13, 52), 6.5, _fill(Colors.white));
    }
    _eyes(c, r: 3.6);
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 65), width: 9, height: 6),
      _fill(_ink),
    );
    _smile(c, y: 70);
  }

  void _astronomer(Canvas c) {
    const hair = Color(0xff4e342e);
    c.drawCircle(const Offset(50, 22), 11, _fill(hair));
    _head(c, const Color(0xffffccbc), r: 30, cy: 58);
    c.drawPath(
      Path()
        ..moveTo(20, 54)
        ..arcToPoint(const Offset(80, 54), radius: const Radius.circular(30))
        ..quadraticBezierTo(50, 40, 20, 54),
      _fill(hair),
    );
    _eyes(c, y: 56, gap: 12, r: 3.6);
    for (final s in [-1.0, 1.0]) {
      _ring(c, Offset(50 + s * 12, 56), 9.5, _ink, 2);
    }
    c.drawLine(
      const Offset(47, 55),
      const Offset(53, 55),
      Paint()
        ..color = _ink
        ..strokeWidth = 2,
    );
    _cheeks(c, y: 68, gap: 19);
    _smile(c, y: 68);
    c.drawCircle(const Offset(72, 36), 4, _fill(_star));
  }

  void _hatchling(Canvas c) {
    _head(c, _star, r: 27, cy: 54);
    _eyes(c, y: 51, gap: 10, r: 4.6);
    _cheeks(c, y: 61, gap: 17);
    c.drawPath(
      _triangle(
        const Offset(45, 57),
        const Offset(55, 57),
        const Offset(50, 65),
      ),
      _fill(const Color(0xffff9800)),
    );
    // Guscio: la base a zig zag, il pulcino è appena nato.
    final shell = Path()..moveTo(14, 68);
    for (var i = 0; i < 6; i++) {
      shell
        ..lineTo(14 + i * 14.4 + 7.2, 78)
        ..lineTo(14 + (i + 1) * 14.4, 68);
    }
    shell
      ..lineTo(86, 100)
      ..lineTo(14, 100)
      ..close();
    c.drawPath(shell, _fill(const Color(0xfffff3e0)));
  }

  @override
  bool shouldRepaint(_CharacterPainter old) =>
      old.character != character ||
      old.expression != expression ||
      old.background != background;
}
