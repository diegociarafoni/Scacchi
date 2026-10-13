import 'package:flutter/material.dart';

/// Valori di stile condivisi da tutte le schermate: le schermate li leggono con
/// `RokkoTokens.of(context)` invece di scrivere colori e misure a mano.
@immutable
class RokkoTokens extends ThemeExtension<RokkoTokens> {
  const RokkoTokens({
    required this.action,
    required this.onAction,
    required this.star,
    required this.success,
    required this.warning,
    required this.boardGreen,
    this.radiusSmall = 12,
    this.radiusLarge = 20,
    this.minTouch = 48,
    this.kidTouch = 56,
  });

  /// Colore dei pulsanti principali (lavanda nel tema scuro, indaco nel chiaro).
  final Color action;

  /// Colore di testo e icone sopra [action].
  final Color onAction;

  /// Stati: riuscito (collegato, corretto) e in attesa (collegamento in corso).
  /// Mai da soli: vanno sempre con un'icona e un testo.
  final Color success;
  final Color warning;

  /// Giallo delle stelline: accenti rari (premi, serie, mascotte).
  final Color star;

  /// Verde classico: solo per la scacchiera, mai per i comandi.
  final Color boardGreen;
  final double radiusSmall;
  final double radiusLarge;

  /// Lato minimo dei bersagli tattili; nel profilo bambino vale [kidTouch].
  final double minTouch;
  final double kidTouch;

  static RokkoTokens of(BuildContext context) =>
      Theme.of(context).extension<RokkoTokens>() ??
      RokkoTheme.light().extension<RokkoTokens>()!;

  @override
  RokkoTokens copyWith({
    Color? action,
    Color? onAction,
    Color? star,
    Color? success,
    Color? warning,
    Color? boardGreen,
  }) => RokkoTokens(
    action: action ?? this.action,
    onAction: onAction ?? this.onAction,
    star: star ?? this.star,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    boardGreen: boardGreen ?? this.boardGreen,
    radiusSmall: radiusSmall,
    radiusLarge: radiusLarge,
    minTouch: minTouch,
    kidTouch: kidTouch,
  );

  @override
  RokkoTokens lerp(RokkoTokens? other, double t) => other == null
      ? this
      : RokkoTokens(
          action: Color.lerp(action, other.action, t)!,
          onAction: Color.lerp(onAction, other.onAction, t)!,
          star: Color.lerp(star, other.star, t)!,
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          boardGreen: Color.lerp(boardGreen, other.boardGreen, t)!,
          radiusSmall: radiusSmall,
          radiusLarge: radiusLarge,
          minTouch: minTouch,
          kidTouch: kidTouch,
        );
}

/// Tema dell'app in stile spaziale, derivato dalla scacchiera «Spazio»: indaco e
/// viola profondi con accenti di stella; forme a raggi 12/20 dp.
abstract final class RokkoTheme {
  /// Case chiare e scure della scacchiera Spazio e viola della nebulosa.
  static const indigo = Color(0xFF4A4F86);
  static const night = Color(0xFF1D1F45);
  static const nebula = Color(0xFF725692);
  static const green = Color(0xFF769656);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final tokens = RokkoTokens(
      action: dark ? const Color(0xFFB9B3FF) : indigo,
      onAction: dark ? const Color(0xFF14152E) : const Color(0xFFFFFFFF),
      star: dark ? const Color(0xFFFFE9A8) : const Color(0xFF8A6A00),
      success: dark ? const Color(0xFF7FE3A6) : const Color(0xFF1B6B3A),
      warning: dark ? const Color(0xFFFFC27A) : const Color(0xFF8A4B00),
      boardGreen: green,
    );
    final scheme =
        ColorScheme.fromSeed(
          seedColor: indigo,
          brightness: brightness,
        ).copyWith(
          primary: tokens.action,
          onPrimary: tokens.onAction,
          secondary: dark ? const Color(0xFFD2B4F5) : nebula,
          onSecondary: dark ? const Color(0xFF1D1033) : const Color(0xFFFFFFFF),
          tertiary: tokens.star,
          surface: dark ? const Color(0xFF12132B) : const Color(0xFFF5F3FC),
          onSurface: dark ? const Color(0xFFE8E6F7) : const Color(0xFF1A1A33),
          surfaceContainer: dark ? night : const Color(0xFFE9E6F6),
          surfaceContainerHigh: dark
              ? const Color(0xFF282B5A)
              : const Color(0xFFDFDBF0),
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radiusSmall),
    );
    final minSize = Size(tokens.minTouch, tokens.minTouch);
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [tokens],
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: shape, minimumSize: minSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape, minimumSize: minSize),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: scheme.outlineVariant),
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
        // Con il testo grande il titolo cede spazio ai comandi della barra.
        const Flexible(
          child: Text(
            'Rokko',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
