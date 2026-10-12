import 'package:flutter/material.dart';

/// Valori di stile condivisi da tutte le schermate: le schermate li leggono con
/// `RokkoTokens.of(context)` invece di scrivere colori e misure a mano.
@immutable
class RokkoTokens extends ThemeExtension<RokkoTokens> {
  const RokkoTokens({
    required this.action,
    required this.boardGreen,
    this.radiusSmall = 12,
    this.radiusLarge = 20,
    this.minTouch = 48,
    this.kidTouch = 56,
  });

  /// Arancione dell'icona: colore dei pulsanti principali.
  final Color action;

  /// Verde storico: solo per la scacchiera, mai per i comandi.
  final Color boardGreen;
  final double radiusSmall;
  final double radiusLarge;

  /// Lato minimo dei bersagli tattili; nel profilo bambino vale [kidTouch].
  final double minTouch;
  final double kidTouch;

  static RokkoTokens of(BuildContext context) =>
      Theme.of(context).extension<RokkoTokens>() ??
      const RokkoTokens(
        action: RokkoTheme.orange,
        boardGreen: RokkoTheme.green,
      );

  @override
  RokkoTokens copyWith({Color? action, Color? boardGreen}) => RokkoTokens(
    action: action ?? this.action,
    boardGreen: boardGreen ?? this.boardGreen,
    radiusSmall: radiusSmall,
    radiusLarge: radiusLarge,
    minTouch: minTouch,
    kidTouch: kidTouch,
  );

  @override
  RokkoTokens lerp(RokkoTokens? other, double t) => this;
}

/// Tema dell'app: arancione d'azione, forme a raggi 12/20 dp.
abstract final class RokkoTheme {
  static const orange = Color(0xFFF2994A);
  static const green = Color(0xFF769656);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    const tokens = RokkoTokens(action: orange, boardGreen: green);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radiusSmall),
    );
    final minSize = Size(tokens.minTouch, tokens.minTouch);
    return ThemeData(
      colorSchemeSeed: orange,
      brightness: brightness,
      extensions: const [tokens],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: shape, minimumSize: minSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape, minimumSize: minSize),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
        ),
      ),
    );
  }
}

/// Marchio per la barra del titolo: torre e nome. Per i lettori di schermo
/// resta un solo testo, la torre è decorativa.
class RokkoWordmark extends StatelessWidget {
  const RokkoWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = RokkoTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Icon(Icons.castle, color: tokens.action)),
        const SizedBox(width: 8),
        const Text('Rokko', style: TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
