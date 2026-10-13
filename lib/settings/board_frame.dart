import 'dart:io';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/widgets.dart';

import 'settings.dart';

/// Cornice con le coordinate fuori dalla scacchiera, così non coprono i pezzi.
/// Senza [outside] passa a [builder] tutta la [size]; con un [backdrop]
/// diverso dallo standard toglie [backdropRatio] per lato come margine.
class BoardFrame extends StatelessWidget {
  const BoardFrame({
    super.key,
    required this.size,
    required this.outside,
    required this.orientation,
    required this.theme,
    required this.builder,
    this.backdrop = BoardBackdrop.standard,
    this.backdropPhoto = '',
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
    backdrop: settings.backdrop,
    backdropPhoto: settings.backdropPhoto,
  );

  final double size;
  final bool outside;
  final Side orientation;
  final BoardTheme theme;
  final BoardBackdrop backdrop;
  final String backdropPhoto;

  /// Disegna la scacchiera nel lato che le resta.
  final Widget Function(double size) builder;

  /// Spessore della cornice rispetto al lato.
  static const marginRatio = 0.05;

  /// Margine di sfondo rispetto al lato, per ciascun bordo.
  static const backdropRatio = 0.04;

  @override
  Widget build(BuildContext context) {
    if (backdrop == BoardBackdrop.standard) return _frame(size);
    final margin = size * backdropRatio;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        key: const Key('board-backdrop'),
        decoration: _backdropDecoration(),
        child: Center(child: _frame(size - margin * 2)),
      ),
    );
  }

  /// La foto che manca o non si legge lascia un colore sobrio, mai un buco.
  BoxDecoration _backdropDecoration() {
    const fallback = Color(0xff2b2a28);
    if (backdrop == BoardBackdrop.photo) {
      return BoxDecoration(
        color: fallback,
        image: backdropPhoto.isEmpty
            ? null
            : DecorationImage(
                image: ResizeImage(
                  FileImage(File(backdropPhoto)),
                  width: 1024,
                  policy: ResizeImagePolicy.fit,
                ),
                fit: BoxFit.cover,
                onError: (_, _) {},
              ),
      );
    }
    final asset = backdrop.asset;
    return BoxDecoration(
      color: backdrop.color ?? fallback,
      gradient: backdrop.gradient,
      image: asset == null
          ? null
          : DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
    );
  }

  Widget _frame(double size) {
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
