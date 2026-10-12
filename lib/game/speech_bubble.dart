import 'package:flutter/material.dart';

import '../engine/bots.dart';
import '../progress/avatar.dart';
import '../progress/avatar_art.dart';
import '../progress/guardian_avatar.dart';

/// Chi parla sopra la scacchiera: lo sfidante o, per aiuti e spiegazioni,
/// l'allenatore.
class Speech {
  const Speech(
    this.text, {
    this.bot,
    this.expression = AvatarExpression.neutral,
    this.icon,
  });

  final String text;

  /// Icona di stato davanti al testo (per esempio la spunta di «risolto»).
  final Widget? icon;

  /// `null` per l'allenatore.
  final Bot? bot;
  final AvatarExpression expression;
}

const double speechStripHeight = 96;

/// Personaggio con il suo fumetto, nello spazio libero sopra la scacchiera.
/// Senza [speech] mostra solo lo sfidante, se c'è.
class SpeechStrip extends StatelessWidget {
  const SpeechStrip({
    super.key,
    required this.opponent,
    required this.speech,
    required this.onDismiss,
  });

  final Bot? opponent;
  final Speech? speech;
  final VoidCallback onDismiss;

  static const double _avatar = 64;

  @override
  Widget build(BuildContext context) {
    final speech = this.speech;
    final bot = speech == null ? opponent : speech.bot;
    final Widget face = bot != null
        ? GuardianAvatar(
            bot: bot,
            size: _avatar,
            expression: speech?.expression ?? AvatarExpression.neutral,
          )
        : ExcludeSemantics(
            child: CharacterAvatar(
              character: AvatarCharacter.astroCat,
              size: _avatar,
              expression: speech?.expression ?? AvatarExpression.encouraging,
            ),
          );
    return SizedBox(
      height: speechStripHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            face,
            if (speech != null)
              Expanded(
                child: SpeechBubble(
                  key: const ValueKey('speechBubble'),
                  text: speech.text,
                  icon: speech.icon,
                  onTap: onDismiss,
                ),
              )
            else if (bot != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    bot.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Il fumetto da solo, con la codina a sinistra verso il personaggio; per
/// puzzle e partite con l'istruttore.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
  });

  final String text;
  final VoidCallback onTap;
  final Widget? icon;

  static const double _tail = 10;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = scheme.surfaceContainerHighest;
    return Semantics(
      liveRegion: true,
      container: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: CustomPaint(
            painter: _TailPainter(fill),
            child: Container(
              constraints: const BoxConstraints(maxHeight: speechStripHeight),
              margin: const EdgeInsets.only(left: _tail),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 10)],
                  Flexible(
                    // Le frasi lunghe (spiegazioni) scorrono nel fumetto.
                    child: SingleChildScrollView(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurface),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Codina del fumetto, a sinistra, verso il personaggio.
class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawPath(
      Path()
        ..moveTo(SpeechBubble._tail + 1, y - 8)
        ..lineTo(0, y)
        ..lineTo(SpeechBubble._tail + 1, y + 8)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
