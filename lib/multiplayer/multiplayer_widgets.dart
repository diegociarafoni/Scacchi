import 'package:flutter/material.dart';

import '../exchange/qr_code_view.dart';
import '../l10n/app_localizations.dart';
import '../theme/rokko_theme.dart';

/// Canali con cui i due telefoni possono parlarsi: un canale nuovo è una voce
/// in più qui e nella lista di [ConnectionIndicator].
enum LinkChannel {
  wifi(Icons.wifi),
  bluetooth(Icons.bluetooth),
  remote(Icons.public);

  const LinkChannel(this.icon);
  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
    wifi => l10n.multiplayerUiChannelWifi,
    bluetooth => l10n.multiplayerUiChannelBluetooth,
    remote => l10n.multiplayerUiChannelRemote,
  };
}

/// Quanto è saldo il collegamento di un canale.
enum LinkLevel { connected, connecting, offline }

/// Stato di un canale, da mostrare in [ConnectionIndicator].
class ChannelLink {
  const ChannelLink({required this.channel, required this.level});

  final LinkChannel channel;
  final LinkLevel level;
}

/// Un'unica lista di canali, ognuno con icona, nome e stato. Lo stato si legge
/// dalla forma dell'icona e dal testo, non solo dal colore.
class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key, required this.channels});

  final List<ChannelLink> channels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [for (final c in channels) _ChannelChip(link: c)],
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({required this.link});

  final ChannelLink link;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tokens = RokkoTokens.of(context);
    final (icon, color, state, spoken) = switch (link.level) {
      LinkLevel.connected => (
        Icons.check_circle,
        tokens.success,
        l10n.multiplayerUiLinkConnected,
        l10n.multiplayerUiLinkConnected.toLowerCase(),
      ),
      LinkLevel.connecting => (
        Icons.sync,
        tokens.warning,
        l10n.multiplayerUiLinkConnecting,
        l10n.multiplayerUiLinkConnecting.toLowerCase(),
      ),
      LinkLevel.offline => (
        Icons.error,
        scheme.error,
        l10n.multiplayerUiLinkOffline,
        l10n.multiplayerUiLinkOffline.toLowerCase(),
      ),
    };
    final name = link.channel.label(l10n);
    return Semantics(
      liveRegion: true,
      label: l10n.multiplayerUiLinkSemantics(name, spoken),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          border: Border.all(color: color, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.labelLarge),
                    Text(state, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Il QR dell'invito con la didascalia «mostra al tuo amico». Il QR resta nero
/// su bianco con margine fisso anche nel tema scuro; la cornice lo stacca dallo
/// sfondo.
class InviteCard extends StatelessWidget {
  const InviteCard({super.key, required this.data, this.maxWidth = 320});

  final String data;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = RokkoTokens.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.smartphone, color: tokens.action),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.multiplayerUiShowFriend,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
                // Nodo a sé: il lettore di schermo annuncia il QR separato
                // dalla didascalia.
                child: Semantics(
                  container: true,
                  child: QrCodeView(
                    data: data,
                    label: l10n.multiplayerInviteQrLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
