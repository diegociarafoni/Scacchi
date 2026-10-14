import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/rokko_theme.dart';
import '../theme/sheets.dart';
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
                padding: context.withSystemBottom(
                  const EdgeInsets.only(bottom: 24),
                ),
                children: builder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
