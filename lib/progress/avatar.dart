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
  pawn('Pedone', glyph: '♟'),
  knight('Cavallo', glyph: '♞'),
  bishop('Alfiere', glyph: '♝'),
  rook('Torre', glyph: '♜'),
  queen('Donna', glyph: '♛'),
  king('Re', glyph: '♚'),
  chick('Pino', character: AvatarCharacter.chick),
  fox('Rocco', character: AvatarCharacter.fox),
  flower('Chiara', character: AvatarCharacter.flower),
  owl('Marta', character: AvatarCharacter.owl),
  astroCat('Gatto astronauta', character: AvatarCharacter.astroCat),
  rabbit('Coniglio lunare', character: AvatarCharacter.rabbit),
  dragon('Duilio', character: AvatarCharacter.dragon),
  eagle('Elena', character: AvatarCharacter.eagle),
  wolf('Massimo', character: AvatarCharacter.wolf),
  star('Stella', character: AvatarCharacter.star);

  const Avatar(this.label, {this.glyph, this.character});

  final String label;

  /// Simbolo del pezzo; `null` per i personaggi.
  final String? glyph;
  final AvatarCharacter? character;
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
