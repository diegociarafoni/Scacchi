import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../progress/rewards.dart';
import '../theme/rokko_theme.dart';
import 'board_preview.dart';
import 'settings.dart';
import 'settings_labels.dart';

/// Anteprima fissa in cima alla pagina, per vedere ogni scelta senza scorrere;
/// si comprime a una riga per lasciare spazio alle impostazioni sui telefoni
/// piccoli.
class SettingsPreviewCard extends StatefulWidget {
  const SettingsPreviewCard({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SettingsPreviewCard> createState() => _SettingsPreviewCardState();
}

class _SettingsPreviewCardState extends State<SettingsPreviewCard> {
  bool open = true;

  AppSettings get settings => widget.settings;

  void onToggle() => setState(() => open = !open);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final size = math
        .min(media.size.width * 0.34, media.size.height * 0.2)
        .clamp(56.0, 128.0);
    final summary =
        '${themeLabel(l10n, settings.boardTheme)} · '
        '${pieceLabel(l10n, settings.pieceSet)}';
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: 1.3),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          key: const Key('preview-bar'),
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (open)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 16),
                  child: BoardPreview(settings: settings, size: size),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.settingsPreview,
                            style: text.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: open
                              ? l10n.settingsPreviewCollapse
                              : l10n.settingsPreviewExpand,
                          onPressed: onToggle,
                          style: IconButton.styleFrom(
                            minimumSize: Size.square(
                              RokkoTokens.of(context).minTouch,
                            ),
                          ),
                          icon: Icon(
                            open ? Icons.expand_less : Icons.expand_more,
                          ),
                        ),
                      ],
                    ),
                    Text(summary, style: text.bodyMedium),
                    if (open) ...[
                      const SizedBox(height: 4),
                      Text(l10n.settingsPreviewHint, style: text.bodySmall),
                    ],
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

class SettingsSubheader extends StatelessWidget {
  const SettingsSubheader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

/// Griglia di scelte con anteprima reale: tema o pezzo, nome, lucchetto se
/// ancora da sbloccare e segno di spunta su quella attiva.
class SettingsGallery<T extends Enum> extends StatelessWidget {
  const SettingsGallery({
    super.key,
    required this.keyPrefix,
    required this.values,
    required this.selected,
    required this.label,
    required this.visual,
    required this.onSelected,
    required this.locked,
  });

  final String keyPrefix;
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final Widget Function(T) visual;
  final ValueChanged<T> onSelected;
  final Requirement? Function(Enum) locked;

  @override
  Widget build(BuildContext context) {
    final tokens = RokkoTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    // Profilo bambino (RP-06): il requisito non cita il livello.
    final kid = AppSettings.of(context).kidMode;
    String why(Requirement r) =>
        kid ? kidRequirement(l10n) : l10n.settingsUnlockWith(r.label);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = 8.0;
          final columns = (box.maxWidth / 96).floor().clamp(3, 6);
          final width = (box.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final v in values)
                _tile(
                  context,
                  v,
                  width: width,
                  tokens: tokens,
                  scheme: scheme,
                  l10n: l10n,
                  kid: kid,
                  why: why,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    T v, {
    required double width,
    required RokkoTokens tokens,
    required ColorScheme scheme,
    required AppLocalizations l10n,
    required bool kid,
    required String Function(Requirement) why,
  }) {
    final requirement = locked(v);
    final isSelected = v == selected;
    final name = label(v);
    final radius = BorderRadius.circular(tokens.radiusSmall);
    void tap() {
      if (requirement == null) return onSelected(v);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            kid
                ? l10n.settingsLockedKidMessage(
                    name,
                    why(requirement).toLowerCase(),
                  )
                : l10n.settingsLockedMessage(name, requirement.label),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        selected: isSelected,
        enabled: requirement == null,
        label: requirement == null
            ? name
            : l10n.settingsLockedSemantics(name, why(requirement)),
        excludeSemantics: true,
        onTap: tap,
        child: Material(
          key: Key('$keyPrefix-${v.name}'),
          color: isSelected
              ? scheme.secondaryContainer
              : scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: tap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: tokens.minTouch),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: requirement == null ? 1 : 0.55,
                          child: visual(v),
                        ),
                        if (requirement != null)
                          Icon(Icons.lock_outline, color: scheme.onSurface),
                        if (isSelected)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Icon(
                              Icons.check_circle,
                              size: 20,
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scacchiera 4×4 con le case chiare e scure del tema.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch(this.theme, {super.key});

  final BoardTheme theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return ExcludeSemantics(
      child: ClipRRect(
        key: Key('theme-swatch-${theme.name}'),
        borderRadius: BorderRadius.circular(
          RokkoTokens.of(context).radiusSmall / 3,
        ),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Column(
            children: [
              for (var r = 0; r < 4; r++)
                Expanded(
                  child: Row(
                    children: [
                      for (var c = 0; c < 4; c++)
                        Expanded(
                          child: ColoredBox(
                            color: (r + c).isEven
                                ? scheme.lightSquare
                                : scheme.darkSquare,
                            child: const SizedBox.expand(),
                          ),
                        ),
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

class SettingsChoices<T> extends StatelessWidget {
  const SettingsChoices({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(label(v)),
              selected: v == selected,
              onSelected: (_) => onSelected(v),
            ),
        ],
      ),
    );
  }
}

/// Cursore del volume che salva solo al rilascio.
class SettingsVolumeSlider extends StatefulWidget {
  const SettingsVolumeSlider({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChangeEnd,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChangeEnd;

  @override
  State<SettingsVolumeSlider> createState() => _SettingsVolumeSliderState();
}

class _SettingsVolumeSliderState extends State<SettingsVolumeSlider> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final value = _dragging ?? widget.value;
    final l10n = AppLocalizations.of(context);
    return Slider(
      value: value,
      divisions: 10,
      label: l10n.settingsVolumeValue((value * 100).round()),
      semanticFormatterCallback: (v) =>
          l10n.settingsVolumeValue((v * 100).round()),
      onChanged: widget.enabled ? (v) => setState(() => _dragging = v) : null,
      onChangeEnd: (v) {
        setState(() => _dragging = null);
        widget.onChangeEnd(v);
      },
    );
  }
}

/// Scelta tra più valori con titolo, riga di spiegazione e chip.
class SettingsChoiceTile<T> extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.title,
    required this.description,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final String title;
  final String description;
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSubheader(title),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            description,
            style: text.bodyMedium?.copyWith(color: muted),
          ),
        ),
        SettingsChoices<T>(
          values: values,
          selected: selected,
          label: label,
          onSelected: onSelected,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Pagina di una sezione: barra del titolo, parte fissa facoltativa in cima
/// e l'elenco delle impostazioni, che segue le modifiche del controllo.
class SettingsSectionScaffold extends StatelessWidget {
  const SettingsSectionScaffold({
    super.key,
    required this.title,
    required this.listenable,
    required this.builder,
    this.pinned,
  });

  final String title;
  final Listenable listenable;
  final List<Widget> Function(BuildContext context) builder;
  final Widget Function(BuildContext context)? pinned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListenableBuilder(
        listenable: listenable,
        builder: (context, _) => Column(
          children: [
            if (pinned != null) pinned!(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: builder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
