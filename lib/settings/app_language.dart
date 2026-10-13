import 'dart:ui' show Locale;

/// Lingua dell'app scelta nelle Impostazioni; `system` segue il telefono.
enum AppLanguage {
  system(null),
  italian(Locale('it')),
  english(Locale('en')),
  french(Locale('fr'));

  const AppLanguage(this.locale);

  /// `null` per seguire la lingua del dispositivo.
  final Locale? locale;

  /// Nome della lingua nella lingua stessa, uguale ovunque; `system` ha
  /// un'etichetta tradotta.
  String? get nativeName => switch (this) {
    AppLanguage.system => null,
    AppLanguage.italian => 'Italiano',
    AppLanguage.english => 'English',
    AppLanguage.french => 'Français',
  };
}

/// Lingua da usare per i [device] indicati dal sistema: la prima supportata,
/// altrimenti l'italiano.
Locale resolveAppLocale(List<Locale>? device, Iterable<Locale> supported) {
  for (final d in device ?? const <Locale>[]) {
    for (final s in supported) {
      if (s.languageCode == d.languageCode) return Locale(s.languageCode);
    }
  }
  return const Locale('it');
}
