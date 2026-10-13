import '../l10n/app_localizations.dart';

/// Punteggio e durata di una sessione di minigioco.
typedef MinigameResult = ({int score, Duration duration});

/// Minigiochi di allenamento (RG-10).
enum Minigame {
  coordinates('coordinate'),
  captureAll('cattura'),
  blind('cieca'),
  material('materiale');

  const Minigame(this.id);

  /// Identificativo stabile, usato nei record.
  final String id;

  String title(AppLocalizations l10n) => switch (this) {
    coordinates => l10n.minigamesCoordinatesTitle,
    captureAll => l10n.minigamesCaptureAllTitle,
    blind => l10n.minigamesBlindTitle,
    material => l10n.minigamesMaterialTitle,
  };

  String description(AppLocalizations l10n) => switch (this) {
    coordinates => l10n.minigamesCoordinatesDescription,
    captureAll => l10n.minigamesCaptureAllDescription,
    blind => l10n.minigamesBlindDescription,
    material => l10n.minigamesMaterialDescription,
  };

  static Minigame? byId(String id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return null;
  }
}
