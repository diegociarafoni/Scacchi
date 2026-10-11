import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/levels.dart';
import 'clock.dart';

enum Opponent { human, computer }

enum SideChoice { white, black, random }

class GameSetup {
  const GameSetup({
    this.opponent = Opponent.human,
    this.sideChoice = SideChoice.white,
    this.level = defaultEngineLevel,
    this.timeControl,
  });

  final Opponent opponent;
  final SideChoice sideChoice;
  final int level;

  /// Cadenza dell'orologio; `null` per giocare senza tempo.
  final TimeControl? timeControl;

  Side resolveHumanSide(math.Random random) => switch (sideChoice) {
    SideChoice.white => Side.white,
    SideChoice.black => Side.black,
    SideChoice.random => random.nextBool() ? Side.white : Side.black,
  };

  GameSetup copyWith({
    Opponent? opponent,
    SideChoice? sideChoice,
    int? level,
  }) => GameSetup(
    opponent: opponent ?? this.opponent,
    sideChoice: sideChoice ?? this.sideChoice,
    level: level ?? this.level,
    timeControl: timeControl,
  );

  GameSetup withTime(TimeControl? control) => GameSetup(
    opponent: opponent,
    sideChoice: sideChoice,
    level: level,
    timeControl: control,
  );
}

Future<GameSetup?> showNewGameDialog(
  BuildContext context, {
  required GameSetup initial,
  required bool computerAvailable,
}) => showDialog<GameSetup>(
  context: context,
  builder: (context) =>
      _NewGameDialog(initial: initial, computerAvailable: computerAvailable),
);

class _NewGameDialog extends StatefulWidget {
  const _NewGameDialog({
    required this.initial,
    required this.computerAvailable,
  });

  final GameSetup initial;
  final bool computerAvailable;

  @override
  State<_NewGameDialog> createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<_NewGameDialog> {
  late GameSetup _setup = widget.computerAvailable
      ? widget.initial
      : widget.initial.copyWith(opponent: Opponent.human);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = engineLevel(_setup.level);
    final vsComputer = _setup.opponent == Opponent.computer;
    return AlertDialog(
      title: const Text('Nuova partita'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<Opponent>(
              segments: [
                const ButtonSegment(
                  value: Opponent.human,
                  icon: Icon(Icons.people_outline),
                  label: Text('Due giocatori'),
                ),
                ButtonSegment(
                  value: Opponent.computer,
                  icon: const Icon(Icons.memory),
                  label: const Text('Computer'),
                  enabled: widget.computerAvailable,
                ),
              ],
              selected: {_setup.opponent},
              onSelectionChanged: (s) =>
                  setState(() => _setup = _setup.copyWith(opponent: s.first)),
            ),
            if (!widget.computerAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'Il computer è disponibile su Android e iOS.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (vsComputer) ...[
              const SizedBox(height: 20),
              Text('Giochi con', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<SideChoice>(
                segments: const [
                  ButtonSegment(value: SideChoice.white, label: Text('Bianco')),
                  ButtonSegment(value: SideChoice.random, label: Text('Caso')),
                  ButtonSegment(value: SideChoice.black, label: Text('Nero')),
                ],
                selected: {_setup.sideChoice},
                onSelectionChanged: (s) => setState(
                  () => _setup = _setup.copyWith(sideChoice: s.first),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Livello ${level.id}: ${level.name}',
                style: theme.textTheme.labelLarge,
              ),
              Text(
                'Circa ${level.approxElo} Elo',
                style: theme.textTheme.bodySmall,
              ),
              Slider(
                value: _setup.level.toDouble(),
                min: 1,
                max: engineLevels.length.toDouble(),
                divisions: engineLevels.length - 1,
                label: level.name,
                onChanged: (v) =>
                    setState(() => _setup = _setup.copyWith(level: v.round())),
              ),
            ],
            const SizedBox(height: 20),
            Text('Tempo', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final control in <TimeControl?>[
                  null,
                  ...TimeControl.presets,
                ])
                  ChoiceChip(
                    label: Text(control?.label ?? 'Senza tempo'),
                    selected: _setup.timeControl == control,
                    onSelected: (_) =>
                        setState(() => _setup = _setup.withTime(control)),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _setup),
          child: const Text('Gioca'),
        ),
      ],
    );
  }
}
