import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tinte dei gruppi di funzioni: la stessa tinta lega icona, titolo e voce.
enum HomeHue {
  play(Color(0xFF3F7A2D), Color(0xFF86BC5A)),
  learn(Color(0xFF3454B8), Color(0xFF7C95F2)),
  train(Color(0xFFB05F0E), Color(0xFFF2B54A)),
  progress(Color(0xFF7A3AAD), Color(0xFFC57FE0));

  const HomeHue(this.dark, this.light);

  final Color dark;
  final Color light;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [light, dark],
  );

  /// Colore del titolo di gruppo, leggibile sullo sfondo del tema.
  Color label(Brightness brightness) =>
      brightness == Brightness.dark ? light : dark;
}

/// Icona della funzione su un riquadro sfumato.
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.label,
    required this.hue,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final HomeHue hue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: hue.gradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: hue.dark.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titolo di un gruppo di funzioni, con un filo che lo accompagna.
class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, required this.title, required this.hue});

  final String title;
  final HomeHue hue;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = hue.label(brightness);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: hue.gradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scheda grande in testa: gradiente della nebulosa, scacchiera sfumata sul
/// fondo e [art] (personaggio o disegno) a destra.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    required this.art,
    this.progress,
  });

  final String label;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;
  final Widget art;

  /// Avanzamento da 0 a 1, se ha senso mostrarlo.
  final double? progress;

  // Testo chiaro su sfondo scuro in entrambi i temi: il contrasto non dipende
  // dalla luminosità del sistema.
  static const _top = Color(0xFF4A4F86);
  static const _bottom = Color(0xFF6A4A8F);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final progress = this.progress;
    return Semantics(
      button: true,
      label: '$label. $title. $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: DecoratedBox(
        // L'ombra sta fuori dal Material, che altrimenti la taglia.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x334A4F86),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_top, _bottom],
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _Checker()),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label.toUpperCase(),
                                  style: text.labelSmall?.copyWith(
                                    color: const Color(0xFFD9D4FF),
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  style: text.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: text.bodyMedium?.copyWith(
                                    color: const Color(0xFFE9E6FF),
                                  ),
                                ),
                                if (progress != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: const Color(0x33FFFFFF),
                                      color: const Color(0xFF9BE8B4),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    action,
                                    style: text.labelLarge?.copyWith(
                                      color: const Color(0xFF2B2D5E),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          art,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scacchiera sfumata in basso a destra: un tocco di gioco senza rubare
/// attenzione al testo.
class _Checker extends CustomPainter {
  const _Checker();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 34.0;
    final paint = Paint()..color = const Color(0x14FFFFFF);
    canvas.save();
    canvas.translate(size.width * 0.62, size.height * 0.55);
    canvas.rotate(-math.pi / 14);
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if ((r + c).isEven) {
          canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), paint);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Checker oldDelegate) => false;
}

/// Disco luminoso dietro un'illustrazione della scheda in testa.
class ArtDisc extends StatelessWidget {
  const ArtDisc({super.key, required this.child, this.size = 96});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
        ),
      ),
      child: child,
    ),
  );
}
