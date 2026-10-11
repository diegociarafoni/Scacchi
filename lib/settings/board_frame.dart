import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/widgets.dart';

import 'settings.dart';

/// Cornice con le coordinate fuori dalla scacchiera, come nei libri: le
/// lettere sotto e i numeri a sinistra non coprono mai i pezzi. Senza
/// [outside] passa a [builder] tutta la [size].
class BoardFrame extends StatelessWidget {
  const BoardFrame({
    super.key,
    required this.size,
    required this.outside,
    required this.orientation,
    required this.theme,
    required this.builder,
  });

  /// Cornice e coordinate secondo le impostazioni correnti.
  factory BoardFrame.of(
    AppSettings settings, {
    Key? key,
    required double size,
    required Side orientation,
    required Widget Function(double size) builder,
  }) => BoardFrame(
    key: key,
    size: size,
    outside: settings.outsideCoordinates,
    orientation: orientation,
    theme: settings.boardTheme,
    builder: builder,
  );

  final double size;
  final bool outside;
  final Side orientation;
  final BoardTheme theme;

  /// Disegna la scacchiera nel lato che le resta.
  final Widget Function(double size) builder;

  /// Spessore della cornice rispetto al lato.
  static const marginRatio = 0.05;

  @override
  Widget build(BuildContext context) {
    if (!outside) return builder(size);
    final margin = size * marginRatio;
    final inner = size - margin * 2;
    final square = inner / 8;
    final scheme = theme.colorScheme;
    final style = TextStyle(
      color: scheme.lightSquare,
      fontSize: margin * 0.62,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    final white = orientation == Side.white;
    Widget label(String text) => Center(
      child: Text(text, style: style, textScaler: TextScaler.noScaling),
    );
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: scheme.darkSquare),
        child: Stack(
          // I pezzi trascinati verso il bordo non vanno tagliati dalla cornice.
          clipBehavior: Clip.none,
          children: [
            Positioned(left: margin, top: margin, child: builder(inner)),
            // Le caselle si leggono già dalla scacchiera accessibile.
            ExcludeSemantics(
              child: Stack(
                children: [
                  for (var i = 0; i < 8; i++)
                    Positioned(
                      left: margin + i * square,
                      top: margin + inner,
                      width: square,
                      height: margin,
                      child: label(
                        String.fromCharCode(97 + (white ? i : 7 - i)),
                      ),
                    ),
                  for (var i = 0; i < 8; i++)
                    Positioned(
                      left: 0,
                      top: margin + i * square,
                      width: margin,
                      height: square,
                      child: label('${white ? 8 - i : i + 1}'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
