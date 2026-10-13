import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/rokko_theme.dart';
import 'credits.dart';

/// Informazioni sull'app: licenza, sorgenti, privacy e crediti. Non usa la
/// rete: l'indirizzo dei sorgenti si copia invece di aprirsi nel browser.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _copySource(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(const ClipboardData(text: sourceCodeUrl));
    messenger.showSnackBar(SnackBar(content: Text(l10n.aboutSourceCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = RokkoTokens.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Column(
              children: [
                Text(l10n.appTitle, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.aboutTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.shield_outlined, color: tokens.action),
            title: Text(l10n.aboutPrivacy),
            subtitle: Text(l10n.aboutPrivacyDescription),
          ),
          ListTile(
            leading: Icon(Icons.gavel_outlined, color: tokens.action),
            title: Text(l10n.aboutLicense),
            subtitle: Text(l10n.aboutLicenseDescription),
          ),
          ListTile(
            key: const Key('about-source'),
            leading: Icon(Icons.code, color: tokens.action),
            title: Text(l10n.aboutSource),
            subtitle: const Text(sourceCodeUrl),
            trailing: const Icon(Icons.copy),
            minTileHeight: tokens.minTouch,
            onTap: () => _copySource(context),
          ),
          ListTile(
            key: const Key('about-licenses'),
            leading: Icon(Icons.description_outlined, color: tokens.action),
            title: Text(l10n.aboutLicenses),
            subtitle: Text(l10n.aboutLicensesDescription),
            trailing: const Icon(Icons.chevron_right),
            minTileHeight: tokens.minTouch,
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(l10n.aboutCredits, style: theme.textTheme.titleMedium),
          ),
          for (final c in credits)
            ListTile(
              dense: true,
              title: Text(c.name),
              subtitle: Text(c.license),
            ),
        ],
      ),
    );
  }
}
