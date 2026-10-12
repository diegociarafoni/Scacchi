import 'package:flutter/material.dart';

import '../engine/bots.dart';
import 'avatar.dart';
import 'avatar_art.dart';

/// Personaggio di un bot (custode della Storia), per ricorrere nelle attività
/// del capitolo; `null` per un bot senza personaggio.
AvatarCharacter? guardianCharacter(String botId) => switch (botId) {
  'pino' => AvatarCharacter.chick,
  'chiara' => AvatarCharacter.flower,
  'rocco' => AvatarCharacter.fox,
  'marta' => AvatarCharacter.owl,
  'duilio' => AvatarCharacter.dragon,
  'elena' => AvatarCharacter.eagle,
  'massimo' => AvatarCharacter.wolf,
  'stella' => AvatarCharacter.star,
  _ => null,
};

/// Il custode [bot] con l'[expression] data (RP-08). Decorativo: la battuta
/// va in un testo a parte, quindi i lettori di schermo lo saltano. Senza un
/// personaggio disegnato mostra l'emoji del bot.
class GuardianAvatar extends StatelessWidget {
  const GuardianAvatar({
    super.key,
    required this.bot,
    this.expression = AvatarExpression.neutral,
    this.size = 56,
    this.background = true,
  });

  final Bot bot;
  final AvatarExpression expression;
  final double size;
  final bool background;

  @override
  Widget build(BuildContext context) {
    final character = guardianCharacter(bot.id);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: character == null
            ? FittedBox(child: Text(bot.avatar))
            : CharacterAvatar(
                character: character,
                size: size,
                expression: expression,
                background: background,
              ),
      ),
    );
  }
}
