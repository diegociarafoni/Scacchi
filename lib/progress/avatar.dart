import 'dart:ui' show Color;

/// Personaggi disegnati in codice (RP-08): i custodi della Storia.
enum AvatarCharacter {
  chick,
  fox,
  flower,
  owl,
  astroCat,
  rabbit,
  dragon,
  eagle,
  wolf,
  star,
  butterfly,
  turtle,
  violet,
  lion,
  bear,
  raccoon,
  astronomer,
  hatchling,
}

/// Espressione di un personaggio, per accompagnare le attività della Storia.
enum AvatarExpression {
  neutral,
  greeting,
  happy,
  encouraging,
  challenge,
  surprised,
}

/// Avatar del profilo: il simbolo di un pezzo o un personaggio.
enum Avatar {
  pawn(glyph: '♟'),
  knight(glyph: '♞'),
  bishop(glyph: '♝'),
  rook(glyph: '♜'),
  queen(glyph: '♛'),
  king(glyph: '♚'),
  chick(character: AvatarCharacter.chick),
  fox(character: AvatarCharacter.fox),
  flower(character: AvatarCharacter.flower),
  owl(character: AvatarCharacter.owl),
  astroCat(character: AvatarCharacter.astroCat),
  rabbit(character: AvatarCharacter.rabbit),
  dragon(character: AvatarCharacter.dragon),
  eagle(character: AvatarCharacter.eagle),
  wolf(character: AvatarCharacter.wolf),
  star(character: AvatarCharacter.star);

  const Avatar({this.glyph, this.character});

  /// Simbolo del pezzo; `null` per i personaggi.
  final String? glyph;
  final AvatarCharacter? character;
}

/// Cornice attorno all'avatar; `null` è l'assenza di cornice.
enum AvatarFrame {
  none(null),
  bronze(Color(0xffcd7f32)),
  silver(Color(0xffa8a9ad)),
  gold(Color(0xffd4af37)),
  flame(Color(0xffe8590c)),
  laurel(Color(0xff2f9e44));

  const AvatarFrame(this.color);
  final Color? color;
}
