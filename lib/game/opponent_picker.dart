import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/levels.dart';

enum Opponent { human, computer }

enum SideChoice { white, black, random }

class GameSetup {
  const GameSetup({
    this.opponent = Opponent.human,
    this.sideChoice = SideChoice.white,
    this.level = defaultEngineLevel,
    this.adaptive = false,
  });

  final Opponent opponent;
  final SideChoice sideChoice;
  final int level;

  /// Il livello segue i risultati del giocatore (RF-26).
  final bool adaptive;

  Side resolveHumanSide(math.Random random) => switch (sideChoice) {
    SideChoice.white => Side.white,
    SideChoice.black => Side.black,
    SideChoice.random => random.nextBool() ? Side.white : Side.black,
  };

  GameSetup copyWith({
    Opponent? opponent,
    SideChoice? sideChoice,
    int? level,
    bool? adaptive,
  }) => GameSetup(
    opponent: opponent ?? this.opponent,
    sideChoice: sideChoice ?? this.sideChoice,
    level: level ?? this.level,
    adaptive: adaptive ?? this.adaptive,
  );
}

/// Scelta dell'avversario e, contro il computer, di colore e livello.
class OpponentPicker extends StatelessWidget {
  const OpponentPicker({
    super.key,
    required this.setup,
    required this.computerAvailable,
    required this.adaptiveLevel,
    required this.onChanged,
  });

  final GameSetup setup;
  final bool computerAvailable;
  final int adaptiveLevel;
  final ValueChanged<GameSetup> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = engineLevel(setup.adaptive ? adaptiveLevel : setup.level);
    final vsComputer = setup.opponent == Opponent.computer;
    return Column(
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
              enabled: computerAvailable,
            ),
          ],
          selected: {setup.opponent},
          onSelectionChanged: (s) =>
              onChanged(setup.copyWith(opponent: s.first)),
        ),
        if (!computerAvailable) ...[
          const SizedBox(height: 8),
          Text(
            'Per giocare contro il computer qui serve Stockfish installato.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (vsComputer) ...[
          const SizedBox(height: 16),
          Text('Giochi con', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          SegmentedButton<SideChoice>(
            segments: const [
              ButtonSegment(value: SideChoice.white, label: Text('Bianco')),
              ButtonSegment(value: SideChoice.random, label: Text('Caso')),
              ButtonSegment(value: SideChoice.black, label: Text('Nero')),
            ],
            selected: {setup.sideChoice},
            onSelectionChanged: (s) =>
                onChanged(setup.copyWith(sideChoice: s.first)),
          ),
          const SizedBox(height: 16),
          Text(
            'Livello ${level.id}: ${level.name}',
            style: theme.textTheme.titleSmall,
          ),
          Text(
            'Circa ${level.approxElo} Elo',
            style: theme.textTheme.bodySmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Adattivo'),
            subtitle: const Text(
              'Il livello si adegua ai tuoi risultati, per vincere circa metà delle partite.',
            ),
            value: setup.adaptive,
            onChanged: (v) => onChanged(setup.copyWith(adaptive: v)),
          ),
          if (!setup.adaptive)
            Slider(
              value: setup.level.toDouble(),
              min: 1,
              max: engineLevels.length.toDouble(),
              divisions: engineLevels.length - 1,
              label: level.name,
              onChanged: (v) => onChanged(setup.copyWith(level: v.round())),
            ),
        ],
      ],
    );
  }
}
