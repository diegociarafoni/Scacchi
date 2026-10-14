import '../l10n/app_localizations.dart';
import 'settings_page.dart';

/// Una voce trovabile dalla ricerca delle Impostazioni: apre la sezione che
/// la contiene.
class SettingsHit {
  const SettingsHit({
    required this.section,
    required this.sectionTitle,
    required this.title,
    this.description,
  });

  final SettingsSection section;
  final String sectionTitle;
  final String title;
  final String? description;
}

/// Voci delle Impostazioni che contengono tutte le parole di [query], senza
/// badare a maiuscole e accenti, cercate nel titolo e nella descrizione.
/// [hasProgress] dice se ci sono i progressi: senza, le voci del profilo che li
/// riguardano non esistono.
List<SettingsHit> settingsHits(
  AppLocalizations l10n,
  String query, {
  required bool hasProgress,
}) {
  final words = _fold(query).split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  return [
    for (final h in _index(l10n, hasProgress: hasProgress))
      if (_matches(h, words)) h,
  ];
}

bool _matches(SettingsHit hit, List<String> words) {
  final text = _fold('${hit.title} ${hit.description ?? ''}');
  return words.every(text.contains);
}

/// Lettere con accento o segno proprio, ridotte alla base.
const _base = {
  'àáâäãåāą': 'a',
  'èéêëēę': 'e',
  'ìíîïı': 'i',
  'òóôöõő': 'o',
  'ùúûüű': 'u',
  'ýÿ': 'y',
  'ñń': 'n',
  'çćč': 'c',
  'šşś': 's',
  'žźż': 'z',
  'ğ': 'g',
  'ł': 'l',
  'ё': 'е',
};

/// Minuscole e senza accenti, con spazi singoli.
String _fold(String s) {
  final out = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final base = _base.entries.where((e) => e.key.contains(c));
    out.write(base.isEmpty ? c : base.first.value);
  }
  return out.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

List<SettingsHit> _index(AppLocalizations l10n, {required bool hasProgress}) {
  SettingsHit hit(
    SettingsSection section,
    String sectionTitle,
    String title, [
    String? description,
  ]) => SettingsHit(
    section: section,
    sectionTitle: sectionTitle,
    title: title,
    description: description,
  );
  final profile = l10n.settingsSectionProfile;
  final board = l10n.settingsSectionBoard;
  final game = l10n.settingsSectionGame;
  final access = l10n.settingsSectionAccessibility;
  const p = SettingsSection.profile;
  const b = SettingsSection.board;
  const g = SettingsSection.game;
  const a = SettingsSection.accessibility;
  return [
    if (hasProgress) ...[
      hit(
        p,
        profile,
        l10n.settingsOpenProfile,
        l10n.settingsOpenProfileDescription,
      ),
      hit(
        p,
        profile,
        l10n.settingsProgressEnabled,
        l10n.settingsProgressEnabledDescription,
      ),
      hit(
        p,
        profile,
        l10n.settingsUnlockAll,
        l10n.settingsUnlockAllDescription,
      ),
    ],
    hit(p, profile, l10n.settingsBackup, l10n.settingsBackupDescription),
    for (final tab in [
      l10n.styleTabBoard,
      l10n.styleTabPieces,
      l10n.styleTabBackdrop,
      l10n.styleTabSounds,
    ])
      hit(SettingsSection.style, l10n.styleTitle, tab),
    hit(b, board, l10n.settingsSound, l10n.settingsSoundDescription),
    hit(b, board, l10n.settingsVolume, l10n.settingsVolumeDescription),
    hit(b, board, l10n.settingsHaptics, l10n.settingsHapticsDescription),
    hit(
      b,
      board,
      l10n.settingsCoordinates,
      l10n.settingsCoordinatesDescription,
    ),
    hit(
      b,
      board,
      l10n.settingsCoordinatesOutside,
      l10n.settingsCoordinatesOutsideDescription,
    ),
    hit(b, board, l10n.settingsLastMove, l10n.settingsLastMoveDescription),
    hit(b, board, l10n.settingsLegalMoves, l10n.settingsLegalMovesDescription),
    hit(b, board, l10n.settingsDrawShapes, l10n.settingsDrawShapesDescription),
    hit(b, board, l10n.settingsMarkColor, l10n.settingsMarkColorDescription),
    hit(b, board, l10n.settingsAnimations, l10n.settingsAnimationsDescription),
    hit(b, board, l10n.settingsNotation, l10n.settingsNotationDescription),
    hit(g, game, l10n.settingsAutoQueen, l10n.settingsAutoQueenDescription),
    hit(g, game, l10n.settingsAutoFlip, l10n.settingsAutoFlipDescription),
    hit(g, game, l10n.settingsTableMode, l10n.settingsTableModeDescription),
    hit(g, game, l10n.settingsExplainWhy, l10n.settingsExplainWhyDescription),
    hit(g, game, l10n.settingsPremove, l10n.settingsPremoveDescription),
    hit(g, game, l10n.settingsMoveMethod, l10n.settingsMoveMethodDescription),
    hit(a, access, l10n.settingsAppTheme, l10n.settingsAppThemeDescription),
    hit(a, access, l10n.settingsColorBlind, l10n.settingsColorBlindDescription),
    hit(a, access, l10n.settingsZenMode, l10n.settingsZenModeDescription),
    hit(
      a,
      access,
      l10n.settingsConfirmMove,
      l10n.settingsConfirmMoveDescription,
    ),
    hit(a, access, l10n.settingsLanguage, l10n.settingsLanguageDescription),
    hit(
      SettingsSection.kid,
      l10n.kidProfile,
      l10n.kidProfile,
      l10n.kidProfileDescription,
    ),
    hit(SettingsSection.about, l10n.aboutTitle, l10n.aboutTitle),
  ];
}
