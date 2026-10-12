import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/rokko_theme.dart';
import 'curriculum.dart';

/// Testi del percorso. Senza i delegate (schermate montate nei test) si usa
/// l'italiano, la lingua predefinita.
AppLocalizations pathL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));

/// Tre stelle, piene quanto [stars]; il conteggio è letto dal nodo che le
/// contiene, non dalle singole icone.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 16});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < stars ? Icons.star : Icons.star_border,
              size: size,
              color: color,
            ),
        ],
      ),
    );
  }
}

/// Contorno tratteggiato di una forma: le tappe bloccate si riconoscono dalla
/// forma del tratto, non solo dal colore.
class DashedShapePainter extends CustomPainter {
  const DashedShapePainter({
    required this.shape,
    required this.color,
    this.width = 2,
  });

  final ShapeBorder shape;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    final outline = shape.getOuterPath(Offset.zero & size);
    _dashed(canvas, outline, paint);
  }

  @override
  bool shouldRepaint(DashedShapePainter old) =>
      old.shape != shape || old.color != color || old.width != width;
}

void _dashed(Canvas canvas, Path path, Paint paint) {
  const dash = 7.0;
  const gap = 6.0;
  for (final metric in path.computeMetrics()) {
    for (var at = 0.0; at < metric.length; at += dash + gap) {
      canvas.drawPath(
        metric.extractPath(at, (at + dash).clamp(0, metric.length)),
        paint,
      );
    }
  }
}

/// Tratto del sentiero che attraversa la riga di una tappa: arriva dalla
/// precedente (se c'è) fino al centro del nodo e riparte verso la successiva.
/// Pieno se la tappa raggiunta è aperta, tratteggiato se è bloccata.
class TrailPainter extends CustomPainter {
  const TrailPainter({
    required this.centerX,
    required this.centerY,
    required this.inX,
    required this.outX,
    required this.color,
    required this.lockedColor,
    required this.inDashed,
    required this.outDashed,
  });

  final double centerX;
  final double centerY;

  /// Ascissa del tratto sul bordo alto e basso della riga; `null` se non c'è.
  final double? inX;
  final double? outX;
  final Color color;
  final Color lockedColor;
  final bool inDashed;
  final bool outDashed;

  @override
  void paint(Canvas canvas, Size size) {
    final x = inX;
    if (x != null) {
      _segment(
        canvas,
        Path()
          ..moveTo(x, 0)
          ..cubicTo(x, centerY / 2, centerX, centerY / 2, centerX, centerY),
        inDashed,
      );
    }
    final out = outX;
    if (out != null) {
      _segment(
        canvas,
        Path()
          ..moveTo(centerX, centerY)
          ..cubicTo(
            centerX,
            (centerY + size.height) / 2,
            out,
            (centerY + size.height) / 2,
            out,
            size.height,
          ),
        outDashed,
      );
    }
  }

  void _segment(Canvas canvas, Path path, bool dashed) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = dashed ? lockedColor : color;
    if (dashed) {
      _dashed(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(TrailPainter old) =>
      old.centerX != centerX ||
      old.centerY != centerY ||
      old.inX != inX ||
      old.outX != outX ||
      old.color != color ||
      old.lockedColor != lockedColor ||
      old.inDashed != inDashed ||
      old.outDashed != outDashed;
}

/// Una tappa del sentiero: lezione (cerchio) o guardiano (esagono).
class StageNode extends StatelessWidget {
  const StageNode({
    super.key,
    required this.stage,
    required this.stars,
    required this.unlocked,
    required this.current,
    required this.alignment,
    required this.onTap,
    this.previousAlignment,
    this.nextAlignment,
    this.nextUnlocked = false,
  });

  final Stage stage;
  final int stars;
  final bool unlocked;
  final bool current;

  /// Posizione orizzontale (-1…1) di questa tappa, della precedente e della
  /// successiva dello stesso capitolo; `null` ai capi del sentiero.
  final double alignment;
  final double? previousAlignment;
  final double? nextAlignment;
  final bool nextUnlocked;
  final VoidCallback onTap;

  static const _block = 84.0;
  static const _width = 160.0;
  static const _top = 12.0;

  @override
  Widget build(BuildContext context) {
    final l10n = pathL10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = RokkoTokens.of(context);
    final done = stars > 0;
    final guardian = stage.isGuardian;
    final size = guardian ? 84.0 : 72.0;
    final state = done
        ? l10n.pathStageDone(stars)
        : unlocked
        ? l10n.pathStageTodo
        : l10n.pathStageLocked;
    final ShapeBorder shape = guardian
        ? const StarBorder.polygon(sides: 6, pointRounding: .25)
        : const CircleBorder();
    final ShapeBorder ring = guardian
        ? const StarBorder.polygon(
            sides: 6,
            pointRounding: .25,
          ).copyWith(side: BorderSide(color: tokens.action, width: 4))
        : CircleBorder(side: BorderSide(color: tokens.action, width: 4));
    final background = !unlocked
        ? scheme.surface
        : done
        ? scheme.primary
        : scheme.primaryContainer;
    final foreground = !unlocked
        ? scheme.onSurfaceVariant
        : done
        ? scheme.onPrimary
        : scheme.onPrimaryContainer;
    final icon = !unlocked
        ? Icons.lock_outline
        : done
        ? Icons.check
        : guardian
        ? Icons.shield_outlined
        : Icons.school_outlined;

    return LayoutBuilder(
      builder: (context, box) {
        double centerX(double a) =>
            _width / 2 + (box.maxWidth - _width) * (1 + a) / 2;
        final cx = centerX(alignment);
        final prev = previousAlignment;
        final next = nextAlignment;
        return CustomPaint(
          key: ValueKey('stage-${stage.id}'),
          painter: TrailPainter(
            centerX: cx,
            centerY: _top + _block / 2,
            inX: prev == null ? null : (centerX(prev) + cx) / 2,
            outX: next == null ? null : (centerX(next) + cx) / 2,
            color: scheme.primary,
            lockedColor: scheme.outline,
            inDashed: !unlocked,
            outDashed: !nextUnlocked,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: _top, bottom: 20),
            child: Align(
              alignment: Alignment(alignment, -1),
              heightFactor: 1,
              child: Semantics(
                button: unlocked,
                enabled: unlocked,
                label:
                    '${stage.title}, $state'
                    '${guardian ? ', ${l10n.pathGuardian}' : ''}'
                    '${current ? ', ${l10n.pathStageHere}' : ''}',
                hint: unlocked ? null : l10n.pathStageLockedHint,
                excludeSemantics: true,
                child: SizedBox(
                  width: _width,
                  child: InkWell(
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusSmall),
                    ),
                    onTap: unlocked ? onTap : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: _block,
                          height: _block,
                          child: Center(
                            child: SizedBox(
                              width: size,
                              height: size,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  DecoratedBox(
                                    decoration: ShapeDecoration(
                                      color: background,
                                      shape: shape,
                                      shadows: unlocked
                                          ? [
                                              BoxShadow(
                                                color: scheme.shadow.withValues(
                                                  alpha: .18,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      icon,
                                      color: foreground,
                                      size: 32,
                                    ),
                                  ),
                                  if (!unlocked)
                                    CustomPaint(
                                      key: ValueKey('dashed-${stage.id}'),
                                      painter: DashedShapePainter(
                                        shape: shape,
                                        color: scheme.outline,
                                      ),
                                    ),
                                  if (current)
                                    DecoratedBox(
                                      decoration: ShapeDecoration(shape: ring),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: unlocked
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        if (guardian)
                          Text(
                            l10n.pathGuardian,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        if (current)
                          Text(
                            l10n.pathStageHere,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (unlocked)
                          StarRow(stars: stars),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
