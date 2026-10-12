import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../progress/progress_controller.dart';
import '../style/style_page.dart';
import '../theme/rokko_theme.dart';
import 'section_pages.dart';
import 'settings.dart';

/// Voci del menu delle Impostazioni, nell'ordine in cui compaiono; il profilo
/// bambino sta in fondo, separato.
enum SettingsSection { profile, style, board, game, accessibility, kid }

/// Menu di sezioni: icona, nome e una riga che dice cosa contiene. Le
/// impostazioni stanno nelle pagine delle sezioni.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller, this.progress});

  final SettingsController controller;

  /// Progressi che sbloccano temi e pezzi; senza, tutto è disponibile e il
  /// Profilo ha solo il backup.
  final ProgressController? progress;

  Widget _page(SettingsSection section) => switch (section) {
    SettingsSection.profile => ProfileSettingsPage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.style => StylePage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.board => BoardSettingsPage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.game => GameSettingsPage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.accessibility => AccessibilitySettingsPage(
      controller: controller,
      progress: progress,
    ),
    SettingsSection.kid => KidSettingsPage(
      controller: controller,
      progress: progress,
    ),
  };

  (IconData, String, String) _entry(
    AppLocalizations l10n,
    SettingsSection section,
  ) => switch (section) {
    SettingsSection.profile => (
      Icons.person_outline,
      l10n.settingsSectionProfile,
      l10n.settingsSectionProfileHint,
    ),
    SettingsSection.style => (
      Icons.palette_outlined,
      l10n.styleTitle,
      l10n.styleEntrySubtitle,
    ),
    SettingsSection.board => (
      Icons.grid_on,
      l10n.settingsSectionBoard,
      l10n.settingsSectionBoardHint,
    ),
    SettingsSection.game => (
      Icons.sports_esports_outlined,
      l10n.settingsSectionGame,
      l10n.settingsSectionGameHint,
    ),
    SettingsSection.accessibility => (
      Icons.accessibility_new,
      l10n.settingsSectionAccessibility,
      l10n.settingsSectionAccessibilityHint,
    ),
    SettingsSection.kid => (
      Icons.child_care,
      l10n.kidProfile,
      l10n.kidProfileDescription,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = RokkoTokens.of(context);
    const sections = SettingsSection.values;
    Widget tile(SettingsSection section) {
      final (icon, title, hint) = _entry(l10n, section);
      return ListTile(
        key: Key('section-${section.name}'),
        leading: Icon(icon, color: tokens.action),
        title: Text(title),
        subtitle: Text(hint),
        trailing: const Icon(Icons.chevron_right),
        minTileHeight: tokens.minTouch,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => _page(section)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final s in sections)
            if (s == SettingsSection.kid) ...[
              const Divider(height: 24),
              tile(s),
            ] else
              tile(s),
        ],
      ),
    );
  }
}
