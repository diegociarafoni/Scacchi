import 'package:flutter/material.dart' show ThemeMode;

import '../l10n/app_localizations.dart';
import 'app_language.dart';
import 'notation.dart';
import 'settings.dart';

/// Nomi tradotti delle scelte.
String themeModeLabel(AppLocalizations l, ThemeMode m) => switch (m) {
  ThemeMode.system => l.settingsModeSystem,
  ThemeMode.light => l.settingsModeLight,
  ThemeMode.dark => l.settingsModeDark,
};

String markColorLabel(AppLocalizations l, MarkColor c) => switch (c) {
  MarkColor.green => l.settingsMarkColorGreen,
  MarkColor.red => l.settingsMarkColorRed,
  MarkColor.blue => l.settingsMarkColorBlue,
  MarkColor.yellow => l.settingsMarkColorYellow,
};

String animationLabel(AppLocalizations l, AnimationSpeed a) => switch (a) {
  AnimationSpeed.none => l.settingsAnimationNone,
  AnimationSpeed.fast => l.settingsAnimationFast,
  AnimationSpeed.normal => l.settingsAnimationNormal,
  AnimationSpeed.slow => l.settingsAnimationSlow,
};

/// I nomi delle lingue restano nella lingua stessa, così si ritrovano anche
/// quando l'app è in una lingua che non si capisce.
String languageLabel(AppLocalizations l, AppLanguage a) =>
    a.nativeName ?? l.settingsLanguageSystem;

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
  BoardTheme.marmo => l.styleThemeMarmo,
  BoardTheme.metallo => l.styleThemeMetallo,
  BoardTheme.vetro => l.styleThemeVetro,
  BoardTheme.menta => l.styleThemeMenta,
  BoardTheme.cipria => l.styleThemeCipria,
  BoardTheme.ardesia => l.styleThemeArdesia,
};

String backdropLabel(AppLocalizations l, BoardBackdrop b) => switch (b) {
  BoardBackdrop.standard => l.styleBackdropStandard,
  BoardBackdrop.graphite => l.styleBackdropGraphite,
  BoardBackdrop.feltro => l.styleBackdropFeltro,
  BoardBackdrop.ardesia => l.styleBackdropArdesia,
  BoardBackdrop.perla => l.styleBackdropPerla,
  BoardBackdrop.notte => l.styleBackdropNotte,
  BoardBackdrop.tramonto => l.styleBackdropTramonto,
  BoardBackdrop.oceano => l.styleBackdropOceano,
  BoardBackdrop.foresta => l.styleBackdropForesta,
  BoardBackdrop.cuoio => l.styleBackdropCuoio,
  BoardBackdrop.spazio => l.styleBackdropSpazio,
  BoardBackdrop.photo => l.styleBackdropPhoto,
};

String soundSetLabel(AppLocalizations l, SoundSet s) => switch (s) {
  SoundSet.classico => l.styleSoundClassico,
  SoundSet.legno => l.styleSoundLegno,
  SoundSet.cristallo => l.styleSoundCristallo,
};
