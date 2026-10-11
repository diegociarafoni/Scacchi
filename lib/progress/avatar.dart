import 'dart:ui' show Color;

/// Avatar del profilo: il simbolo di un pezzo.
enum Avatar {
  pawn('Pedone', '♟'),
  knight('Cavallo', '♞'),
  bishop('Alfiere', '♝'),
  rook('Torre', '♜'),
  queen('Donna', '♛'),
  king('Re', '♚');

  const Avatar(this.label, this.glyph);

  final String label;
  final String glyph;
}

/// Cornice attorno all'avatar; `null` è l'assenza di cornice.
enum AvatarFrame {
  none('Nessuna', null),
  bronze('Bronzo', Color(0xffcd7f32)),
  silver('Argento', Color(0xffa8a9ad)),
  gold('Oro', Color(0xffd4af37)),
  flame('Fiamma', Color(0xffe8590c)),
  laurel('Alloro', Color(0xff2f9e44));

  const AvatarFrame(this.label, this.color);

  final String label;
  final Color? color;
}
