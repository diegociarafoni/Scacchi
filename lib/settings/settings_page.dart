import 'package:flutter/material.dart';

import '../progress/progress_controller.dart';
import '../progress/rewards.dart';
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
          void set(AppSettings Function(AppSettings) change) =>
              controller.update(change(controller.value));
          final p = progress;
          Requirement? locked(Enum item) =>
              p == null || isUnlocked(item, p.state, p.settings)
              ? null
              : requirementOf(item);
          return ListView(
            children: [
              const _Header('Scacchiera'),
              SwitchListTile(
                title: const Text('Mostra le mosse legali'),
                value: s.showLegalMoves,
                onChanged: (v) => set((c) => c.copyWith(showLegalMoves: v)),
              ),
              SwitchListTile(
                title: const Text('Coordinate'),
                value: s.showCoordinates,
                onChanged: (v) => set((c) => c.copyWith(showCoordinates: v)),
              ),
              SwitchListTile(
                title: const Text('Promuovi sempre a donna'),
                value: s.autoQueen,
                onChanged: (v) => set((c) => c.copyWith(autoQueen: v)),
              ),
              SwitchListTile(
                title: const Text('Frecce e cerchi'),
                subtitle: const Text('Disegna con due dita sulla scacchiera'),
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
                locked: locked,
                onSelected: (t) => set((c) => c.copyWith(boardTheme: t)),
              ),
              const _Header('Pezzi'),
              _Choices(
                values: PieceStyle.values,
                selected: s.pieceSet,
                label: (p) => p.label,
                locked: locked,
                onSelected: (p) => set((c) => c.copyWith(pieceSet: p)),
              ),
              if (p != null && p.settings.enabled)
                SwitchListTile(
                  key: const Key('unlockAll'),
                  title: const Text('Sblocca tutto'),
                  subtitle: const Text(
                    'Temi, pezzi e avatar disponibili senza doverli sbloccare',
                  ),
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
              const SizedBox(height: 24),
            ],
          );
        },
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

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.locked,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  /// Condizione ancora da soddisfare per poter scegliere il valore.
  final Requirement? Function(T)? locked;

  @override
  Widget build(BuildContext context) {
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
                tooltip: 'Si sblocca con: ${requirement.label}',
                selected: v == selected,
                onSelected: (_) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '${label(v)} si sblocca con: ${requirement.label}',
                      ),
                    ),
                  );
                },
              )
            else
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
