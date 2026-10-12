import 'dart:math' as math;

import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter/material.dart';

import '../backup/backup_page.dart';
import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../progress/progress_controller.dart';
import '../progress/rewards.dart';
import '../theme/rokko_theme.dart';
import 'adult_gate.dart';
import 'board_preview.dart';
import 'notation.dart';
import 'settings.dart';
import 'settings_labels.dart';

/// Sezioni della pagina, nell'ordine in cui compaiono.
enum SettingsSection {
  kid,
  appearance,
  board,
  game,
  accessibility,
  sound,
  data,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    this.progress,
    this.expanded,
  });

  final SettingsController controller;

  /// Progressi che sbloccano temi e pezzi; senza, tutto è disponibile.
  final ProgressController? progress;

  /// Sezioni aperte all'inizio; di norma solo profilo e aspetto.
  final Set<SettingsSection>? expanded;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Set<SettingsSection> _open = {
    ...(widget.expanded ??
        const {SettingsSection.kid, SettingsSection.appearance}),
  };
  bool _previewOpen = true;

  Widget _section(
    SettingsSection id, {
    required IconData icon,
    required String title,
    required String hint,
    required List<Widget> children,
  }) {
    final tokens = RokkoTokens.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: Key('section-${id.name}'),
        initiallyExpanded: _open.contains(id),
        onExpansionChanged: (v) => v ? _open.add(id) : _open.remove(id),
        leading: Icon(icon, color: tokens.action),
        title: Text(title),
        subtitle: Text(hint),
        minTileHeight: tokens.minTouch,
        shape: const Border(),
        collapsedShape: const Border(),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final p = widget.progress;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([controller, p]),
        builder: (context, _) {
          final s = controller.value;
          void set(AppSettings Function(AppSettings) change) =>
              controller.update(change(controller.value));
          Requirement? locked(Enum item) =>
              p == null || isUnlocked(item, p.state, p.settings)
              ? null
              : requirementOf(item);
          return Column(
            children: [
              _PreviewCard(
                settings: s,
                open: _previewOpen,
                onToggle: () => setState(() => _previewOpen = !_previewOpen),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _section(
                      SettingsSection.kid,
                      icon: Icons.child_care,
                      title: l10n.kidProfileSection,
                      hint: l10n.kidProfileDescription,
                      children: [
                        SwitchListTile(
                          key: const Key('kidMode'),
                          title: Text(l10n.kidProfile),
                          value: s.kidMode,
                          onChanged: (v) async {
                            if (!v && !await askAdult(context)) return;
                            set((c) => c.copyWith(kidMode: v));
                          },
                        ),
                      ],
                    ),
                    _section(
                      SettingsSection.appearance,
                      icon: Icons.palette_outlined,
                      title: l10n.settingsSectionAppearance,
                      hint: l10n.settingsSectionAppearanceHint,
                      children: [
                        _Subheader(l10n.settingsAppTheme),
                        _Choices(
                          values: ThemeMode.values,
                          selected: s.themeMode,
                          label: (m) => themeModeLabel(l10n, m),
                          onSelected: (m) =>
                              set((c) => c.copyWith(themeMode: m)),
                        ),
                        _Subheader(l10n.settingsBoardTheme),
                        _Gallery<BoardTheme>(
                          keyPrefix: 'theme-tile',
                          values: BoardTheme.values,
                          selected: s.boardTheme,
                          label: (t) => themeLabel(l10n, t),
                          visual: _ThemeSwatch.new,
                          locked: locked,
                          onSelected: (t) =>
                              set((c) => c.copyWith(boardTheme: t)),
                        ),
                        _Subheader(l10n.settingsPieces),
                        _Gallery<PieceStyle>(
                          keyPrefix: 'piece-tile',
                          values: PieceStyle.values,
                          selected: s.pieceSet,
                          label: (st) => pieceLabel(l10n, st),
                          visual: (st) => Image(
                            key: Key('piece-icon-${st.name}'),
                            image: st.assets[PieceKind.whiteKnight]!,
                            width: 48,
                            height: 48,
                          ),
                          locked: locked,
                          onSelected: (st) =>
                              set((c) => c.copyWith(pieceSet: st)),
                        ),
                        if (p != null && p.settings.enabled)
                          SwitchListTile(
                            key: const Key('unlockAll'),
                            title: Text(l10n.settingsUnlockAll),
                            subtitle: Text(l10n.settingsUnlockAllDescription),
                            value: p.settings.unlockAll,
                            onChanged: (v) => p.updateSettings(
                              p.settings.copyWith(unlockAll: v),
                            ),
                          ),
                        _Subheader(l10n.settingsAnimations),
                        _Choices(
                          values: AnimationSpeed.values,
                          selected: s.animation,
                          label: (a) => animationLabel(l10n, a),
                          onSelected: (a) =>
                              set((c) => c.copyWith(animation: a)),
                        ),
                      ],
                    ),
                    _section(
                      SettingsSection.board,
                      icon: Icons.grid_on,
                      title: l10n.settingsSectionBoard,
                      hint: l10n.settingsSectionBoardHint,
                      children: [
                        SwitchListTile(
                          title: Text(l10n.settingsLegalMoves),
                          value: s.showLegalMoves,
                          onChanged: (v) =>
                              set((c) => c.copyWith(showLegalMoves: v)),
                        ),
                        SwitchListTile(
                          title: Text(l10n.settingsCoordinates),
                          value: s.showCoordinates,
                          onChanged: (v) =>
                              set((c) => c.copyWith(showCoordinates: v)),
                        ),
                        SwitchListTile(
                          key: const Key('coordinatesOutside'),
                          title: Text(l10n.settingsCoordinatesOutside),
                          subtitle: Text(
                            l10n.settingsCoordinatesOutsideDescription,
                          ),
                          value: s.coordinatesOutside,
                          onChanged: s.showCoordinates
                              ? (v) => set(
                                  (c) => c.copyWith(coordinatesOutside: v),
                                )
                              : null,
                        ),
                        SwitchListTile(
                          title: Text(l10n.settingsDrawShapes),
                          subtitle: Text(l10n.settingsDrawShapesDescription),
                          value: s.drawShapes,
                          onChanged: (v) =>
                              set((c) => c.copyWith(drawShapes: v)),
                        ),
                        _Subheader(l10n.settingsNotation),
                        _Choices(
                          values: MoveNotation.values,
                          selected: s.notation,
                          label: (n) => notationLabel(l10n, n),
                          onSelected: (n) =>
                              set((c) => c.copyWith(notation: n)),
                        ),
                      ],
                    ),
                    _section(
                      SettingsSection.game,
                      icon: Icons.sports_esports_outlined,
                      title: l10n.settingsSectionGame,
                      hint: l10n.settingsSectionGameHint,
                      children: [
                        SwitchListTile(
                          title: Text(l10n.settingsAutoQueen),
                          value: s.autoQueen,
                          onChanged: (v) =>
                              set((c) => c.copyWith(autoQueen: v)),
                        ),
                        SwitchListTile(
                          key: const Key('explainWhy'),
                          title: Text(l10n.settingsExplainWhy),
                          subtitle: Text(l10n.settingsExplainWhyDescription),
                          value: s.explainWhy,
                          onChanged: (v) =>
                              set((c) => c.copyWith(explainWhy: v)),
                        ),
                        SwitchListTile(
                          title: Text(l10n.settingsAutoFlip),
                          subtitle: Text(l10n.settingsAutoFlipDescription),
                          value: s.autoFlip,
                          onChanged: (v) => set((c) => c.copyWith(autoFlip: v)),
                        ),
                        SwitchListTile(
                          title: Text(l10n.settingsTableMode),
                          subtitle: Text(l10n.settingsTableModeDescription),
                          value: s.tableMode,
                          onChanged: (v) =>
                              set((c) => c.copyWith(tableMode: v)),
                        ),
                      ],
                    ),
                    _section(
                      SettingsSection.accessibility,
                      icon: Icons.accessibility_new,
                      title: l10n.settingsSectionAccessibility,
                      hint: l10n.settingsSectionAccessibilityHint,
                      children: [
                        SwitchListTile(
                          key: const Key('colorBlind'),
                          title: Text(l10n.settingsColorBlind),
                          subtitle: Text(l10n.settingsColorBlindDescription),
                          value: s.colorBlind,
                          onChanged: (v) =>
                              set((c) => c.copyWith(colorBlind: v)),
                        ),
                        SwitchListTile(
                          key: const Key('zenMode'),
                          title: Text(l10n.settingsZenMode),
                          subtitle: Text(l10n.settingsZenModeDescription),
                          value: s.zenMode,
                          onChanged: (v) => set((c) => c.copyWith(zenMode: v)),
                        ),
                        SwitchListTile(
                          key: const Key('confirmMove'),
                          title: Text(l10n.settingsConfirmMove),
                          subtitle: Text(l10n.settingsConfirmMoveDescription),
                          value: s.confirmMove,
                          onChanged: (v) =>
                              set((c) => c.copyWith(confirmMove: v)),
                        ),
                      ],
                    ),
                    _section(
                      SettingsSection.sound,
                      icon: Icons.volume_up_outlined,
                      title: l10n.settingsSectionSound,
                      hint: l10n.settingsSectionSoundHint,
                      children: [
                        SwitchListTile(
                          title: Text(l10n.settingsSound),
                          value: s.sound,
                          onChanged: (v) => set((c) => c.copyWith(sound: v)),
                        ),
                        ListTile(
                          title: Text(l10n.settingsVolume),
                          subtitle: _VolumeSlider(
                            value: s.volume,
                            enabled: s.sound,
                            onChangeEnd: (v) =>
                                set((c) => c.copyWith(volume: v)),
                          ),
                        ),
                        SwitchListTile(
                          title: Text(l10n.settingsHaptics),
                          value: s.haptics,
                          onChanged: (v) => set((c) => c.copyWith(haptics: v)),
                        ),
                      ],
                    ),
                    _section(
                      SettingsSection.data,
                      icon: Icons.backup_outlined,
                      title: l10n.settingsSectionData,
                      hint: l10n.settingsSectionDataHint,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.backup_outlined),
                          title: Text(l10n.settingsBackup),
                          subtitle: Text(l10n.settingsBackupDescription),
                          onTap: () async {
                            final page = await BackupPage.system();
                            if (context.mounted) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute<void>(builder: (_) => page),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Anteprima fissa in cima alla pagina, per vedere ogni scelta senza scorrere;
/// si comprime a una riga per lasciare spazio alle impostazioni sui telefoni
/// piccoli.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.settings,
    required this.open,
    required this.onToggle,
  });

  final AppSettings settings;
  final bool open;
  final VoidCallback onToggle;

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

class _Subheader extends StatelessWidget {
  const _Subheader(this.text);

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
class _Gallery<T extends Enum> extends StatelessWidget {
  const _Gallery({
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
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch(this.theme);

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

class _Choices<T> extends StatelessWidget {
  const _Choices({
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
class _VolumeSlider extends StatefulWidget {
  const _VolumeSlider({
    required this.value,
    required this.enabled,
    required this.onChangeEnd,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChangeEnd;

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
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
