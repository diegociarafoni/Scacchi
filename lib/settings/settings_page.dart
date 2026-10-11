import 'dart:math' as math;

import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter/material.dart';

import '../backup/backup_page.dart';
import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../progress/progress_controller.dart';
import '../progress/rewards.dart';
import 'adult_gate.dart';
import 'board_preview.dart';
import 'settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller, this.progress});

  final SettingsController controller;

  /// Progressi che sbloccano temi e pezzi; senza, tutto è disponibile.
  final ProgressController? progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListenableBuilder(
        listenable: Listenable.merge([controller, progress]),
        builder: (context, _) {
          final s = controller.value;
          final l10n = AppLocalizations.of(context);
          void set(AppSettings Function(AppSettings) change) =>
              controller.update(change(controller.value));
          final p = progress;
          Requirement? locked(Enum item) =>
              p == null || isUnlocked(item, p.state, p.settings)
              ? null
              : requirementOf(item);
          return Column(
            children: [
              _PreviewBar(settings: s),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    _Header(l10n.kidProfileSection),
                    SwitchListTile(
                      key: const Key('kidMode'),
                      secondary: const Icon(Icons.child_care),
                      title: Text(l10n.kidProfile),
                      subtitle: Text(l10n.kidProfileDescription),
                      value: s.kidMode,
                      onChanged: (v) async {
                        if (!v && !await askAdult(context)) return;
                        set((c) => c.copyWith(kidMode: v));
                      },
                    ),
                    const _Header('Aspetto dell\'app'),
                    _Choices(
                      values: ThemeMode.values,
                      selected: s.themeMode,
                      label: (m) => switch (m) {
                        ThemeMode.system => 'Sistema',
                        ThemeMode.light => 'Chiaro',
                        ThemeMode.dark => 'Scuro',
                      },
                      onSelected: (m) => set((c) => c.copyWith(themeMode: m)),
                    ),
                    const _Header('Scacchiera'),
                    SwitchListTile(
                      title: const Text('Mostra le mosse legali'),
                      value: s.showLegalMoves,
                      onChanged: (v) =>
                          set((c) => c.copyWith(showLegalMoves: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Coordinate'),
                      value: s.showCoordinates,
                      onChanged: (v) =>
                          set((c) => c.copyWith(showCoordinates: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Promuovi sempre a donna'),
                      value: s.autoQueen,
                      onChanged: (v) => set((c) => c.copyWith(autoQueen: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Frecce e cerchi'),
                      subtitle: const Text(
                        'Disegna con due dita sulla scacchiera',
                      ),
                      value: s.drawShapes,
                      onChanged: (v) => set((c) => c.copyWith(drawShapes: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Conferma la mossa'),
                      subtitle: const Text(
                        'Chiede conferma prima di giocare ogni mossa',
                      ),
                      value: s.confirmMove,
                      onChanged: (v) => set((c) => c.copyWith(confirmMove: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Ruota a ogni turno'),
                      subtitle: const Text('Nelle partite tra due persone'),
                      value: s.autoFlip,
                      onChanged: (v) => set((c) => c.copyWith(autoFlip: v)),
                    ),
                    SwitchListTile(
                      title: const Text('Modalità tavolo'),
                      subtitle: const Text(
                        'Pezzi in alto capovolti, per giocare uno di fronte all\'altro',
                      ),
                      value: s.tableMode,
                      onChanged: (v) => set((c) => c.copyWith(tableMode: v)),
                    ),
                    const _Header('Suoni e vibrazione'),
                    SwitchListTile(
                      title: const Text('Suoni'),
                      value: s.sound,
                      onChanged: (v) => set((c) => c.copyWith(sound: v)),
                    ),
                    ListTile(
                      title: const Text('Volume'),
                      subtitle: _VolumeSlider(
                        value: s.volume,
                        enabled: s.sound,
                        onChangeEnd: (v) => set((c) => c.copyWith(volume: v)),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Vibrazione'),
                      value: s.haptics,
                      onChanged: (v) => set((c) => c.copyWith(haptics: v)),
                    ),
                    const _Header('Tema della scacchiera'),
                    _Choices(
                      values: BoardTheme.values,
                      selected: s.boardTheme,
                      label: (t) => t.label,
                      avatar: _ThemeSwatch.new,
                      locked: locked,
                      onSelected: (t) => set((c) => c.copyWith(boardTheme: t)),
                    ),
                    SwitchListTile(
                      title: const Text('Colori per daltonici'),
                      subtitle: const Text(
                        'Evidenziazioni senza rosso né verde, ben contrastate su ogni tema',
                      ),
                      value: s.colorBlind,
                      onChanged: (v) => set((c) => c.copyWith(colorBlind: v)),
                    ),
                    const _Header('Pezzi'),
                    _Choices(
                      values: PieceStyle.values,
                      selected: s.pieceSet,
                      label: (p) => p.label,
                      avatar: (p) => Image(
                        key: Key('piece-icon-${p.name}'),
                        image: p.pieceSet.assets[PieceKind.whiteKnight]!,
                        width: 24,
                        height: 24,
                      ),
                      locked: locked,
                      onSelected: (p) => set((c) => c.copyWith(pieceSet: p)),
                    ),
                    if (p != null && p.settings.enabled)
                      SwitchListTile(
                        key: const Key('unlockAll'),
                        title: const Text(unlockAllTitle),
                        subtitle: const Text(unlockAllSubtitle),
                        value: p.settings.unlockAll,
                        onChanged: (v) =>
                            p.updateSettings(p.settings.copyWith(unlockAll: v)),
                      ),
                    const _Header('Animazioni'),
                    _Choices(
                      values: AnimationSpeed.values,
                      selected: s.animation,
                      label: (a) => a.label,
                      onSelected: (a) => set((c) => c.copyWith(animation: a)),
                    ),
                    const _Header('Dati'),
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Backup e ripristino'),
                      subtitle: const Text(
                        'Salva o recupera tutti i dati locali',
                      ),
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
                    const SizedBox(height: 24),
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

/// Anteprima fissa in cima alla pagina, per vedere ogni scelta senza scorrere.
class _PreviewBar extends StatelessWidget {
  const _PreviewBar({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final size = math
        .min(media.size.width * 0.34, media.size.height * 0.2)
        .clamp(56.0, 128.0);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: 1.3),
      ),
      child: Padding(
        key: const Key('preview-bar'),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            BoardPreview(settings: settings, size: size),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anteprima', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${settings.boardTheme.label} · ${settings.pieceSet.label}',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('Tocca per provare la mossa.', style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

/// Due quadratini con i colori delle case chiare e scure del tema.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch(this.theme);

  final BoardTheme theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return ExcludeSemantics(
      child: ClipRRect(
        key: Key('theme-swatch-${theme.name}'),
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Row(
            children: [
              Expanded(child: ColoredBox(color: scheme.lightSquare)),
              Expanded(child: ColoredBox(color: scheme.darkSquare)),
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
    this.locked,
    this.avatar,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  /// Segno distintivo mostrato nel chip, per riconoscere il valore a colpo d'occhio.
  final Widget Function(T)? avatar;

  /// Condizione ancora da soddisfare per poter scegliere il valore.
  final Requirement? Function(T)? locked;

  @override
  Widget build(BuildContext context) {
    // Profilo bambino (RP-06): il requisito non cita il livello.
    final kid = AppSettings.of(context).kidMode;
    String why(Requirement r) => kid
        ? kidRequirement(AppLocalizations.of(context))
        : 'Si sblocca con: ${r.label}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values)
            if (locked?.call(v) case final requirement?)
              ChoiceChip(
                avatar: const Icon(Icons.lock_outline, size: 18),
                label: Text(label(v)),
                tooltip: why(requirement),
                selected: v == selected,
                onSelected: (_) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        kid
                            ? '${label(v)}: ${why(requirement).toLowerCase()}'
                            : '${label(v)} si sblocca con: ${requirement.label}',
                      ),
                    ),
                  );
                },
              )
            else
              ChoiceChip(
                avatar: avatar?.call(v),
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
    return Slider(
      value: value,
      divisions: 10,
      label: '${(value * 100).round()}%',
      onChanged: widget.enabled ? (v) => setState(() => _dragging = v) : null,
      onChangeEnd: (v) {
        setState(() => _dragging = null);
        widget.onChangeEnd(v);
      },
    );
  }
}
