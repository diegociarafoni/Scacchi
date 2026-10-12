import 'package:flutter/material.dart' show ThemeMode;

import '../l10n/app_localizations.dart';
import 'notation.dart';
import 'settings.dart';

/// Nomi tradotti delle scelte; le etichette delle enum restano il ripiego
/// italiano per chi non ha un contesto di traduzione.
String themeModeLabel(AppLocalizations l, ThemeMode m) => switch (m) {
  ThemeMode.system => l.settingsModeSystem,
  ThemeMode.light => l.settingsModeLight,
  ThemeMode.dark => l.settingsModeDark,
};

String animationLabel(AppLocalizations l, AnimationSpeed a) => switch (a) {
  AnimationSpeed.none => l.settingsAnimationNone,
  AnimationSpeed.fast => l.settingsAnimationFast,
  AnimationSpeed.normal => l.settingsAnimationNormal,
  AnimationSpeed.slow => l.settingsAnimationSlow,
};

String notationLabel(AppLocalizations l, MoveNotation n) =>
    l.settingsNotationChoice(switch (n) {
      MoveNotation.figurine => l.settingsNotationFigurine,
      MoveNotation.italian => l.settingsNotationItalian,
      MoveNotation.english => l.settingsNotationEnglish,
    }, n.example);

/// I set di pezzi hanno nomi propri, uguali in ogni lingua, tranne il classico.
String pieceLabel(AppLocalizations l, PieceStyle p) =>
    p == PieceStyle.cburnett ? l.settingsPieceClassic : p.label;

String themeLabel(AppLocalizations l, BoardTheme t) => switch (t) {
  BoardTheme.green => l.settingsThemeGreen,
  BoardTheme.brown => l.settingsThemeBrown,
  BoardTheme.blue => l.settingsThemeBlue,
  BoardTheme.grey => l.settingsThemeGrey,
  BoardTheme.sand => l.settingsThemeSand,
  BoardTheme.ocean => l.settingsThemeOcean,
  BoardTheme.coral => l.settingsThemeCoral,
  BoardTheme.night => l.settingsThemeNight,
  BoardTheme.gold => l.settingsThemeGold,
  BoardTheme.arancia => l.settingsThemeArancia,
  BoardTheme.crepuscolo => l.settingsThemeCrepuscolo,
  BoardTheme.pergamena => l.settingsThemePergamena,
  BoardTheme.castello => l.settingsThemeCastello,
  BoardTheme.bosco => l.settingsThemeBosco,
  BoardTheme.noce => l.settingsThemeNoce,
  BoardTheme.spazio => l.settingsThemeSpazio,
  BoardTheme.retro => l.settingsThemeRetro,
  BoardTheme.giardino => l.settingsThemeGiardino,
  BoardTheme.terracotta => l.settingsThemeTerracotta,
};
