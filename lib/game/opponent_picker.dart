import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/bot_collection.dart';
import '../engine/bots.dart';
import '../engine/levels.dart';
import '../engine/style.dart';
import '../l10n/app_localizations.dart';

enum Opponent { human, computer, bot }

enum SideChoice { white, black, random }

class GameSetup {
  const GameSetup({
    this.opponent = Opponent.human,
    this.sideChoice = SideChoice.white,
    this.level = defaultEngineLevel,
    this.adaptive = false,
    this.botId = 'pino',
  });

  final Opponent opponent;
  final SideChoice sideChoice;
  final int level;

  /// Il livello segue i risultati del giocatore (RF-26).
  final bool adaptive;

  /// Bot scelto contro cui giocare (RF-23).
  final String botId;

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
    String? botId,
  }) => GameSetup(
    opponent: opponent ?? this.opponent,
    sideChoice: sideChoice ?? this.sideChoice,
    level: level ?? this.level,
    adaptive: adaptive ?? this.adaptive,
    botId: botId ?? this.botId,
  );

  /// Configurazione per il profilo bambino (RP-06): niente computer e solo
  /// bot amichevoli, ripiegando sul primo.
  GameSetup forKids() {
    if (opponent == Opponent.human) return this;
    final friendly = friendlyBots.any((b) => b.id == botId);
    return copyWith(
      opponent: Opponent.bot,
      botId: friendly ? botId : friendlyBots.first.id,
    );
  }
}

/// Scelta dell'avversario e, contro il computer, di colore e livello.
class OpponentPicker extends StatelessWidget {
  const OpponentPicker({
    super.key,
    required this.setup,
    required this.computerAvailable,
    required this.adaptiveLevel,
    required this.collection,
    required this.onChanged,
    this.kidMode = false,
  });

  final GameSetup setup;

  /// Profilo bambino (RP-06): niente computer, solo bot amichevoli e nessun numero.
  final bool kidMode;
  final bool computerAvailable;
  final int adaptiveLevel;
  final BotCollection collection;
  final ValueChanged<GameSetup> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final setup = kidMode ? this.setup.forKids() : this.setup;
    final level = engineLevel(setup.adaptive ? adaptiveLevel : setup.level);
    final vsBot = setup.opponent == Opponent.bot;
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
            if (!kidMode)
              ButtonSegment(
                value: Opponent.computer,
                icon: const Icon(Icons.memory),
                label: const Text('Computer'),
                enabled: computerAvailable,
              ),
            ButtonSegment(
              value: Opponent.bot,
              icon: const Icon(Icons.emoji_people_outlined),
              label: const Text('Bot'),
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
        if (vsComputer || vsBot) ...[
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
          if (vsBot) ...[
            const SizedBox(height: 8),
            for (final bot in kidMode ? friendlyBots : bots)
              _BotTile(
                bot: bot,
                collection: collection,
                kidMode: kidMode,
                selected: bot.id == setup.botId,
                onTap: () => onChanged(setup.copyWith(botId: bot.id)),
              ),
          ],
        ],
        if (vsComputer) ...[
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

class _BotTile extends StatelessWidget {
  const _BotTile({
    required this.bot,
    required this.collection,
    required this.kidMode,
    required this.selected,
    required this.onTap,
  });

  final Bot bot;
  final BotCollection collection;
  final bool kidMode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = collection.isUnlocked(bot);
    final beatenOn = collection.beatenOn(bot);
    final details = kidMode
        ? _kidDescription(AppLocalizations.of(context))
        : [
            '${bot.elo} Elo',
            styleLabel(bot.style),
            bot.openingName,
            if (beatenOn != null) 'Battuto il ${_date(beatenOn)}',
          ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: unlocked,
      selected: selected && unlocked,
      leading: Text(bot.avatar, style: const TextStyle(fontSize: 28)),
      title: Text(bot.name),
      subtitle: Text(details),
      trailing: !unlocked
          ? const Icon(
              Icons.lock_outline,
              semanticLabel: 'Bloccato: batti il bot precedente',
            )
          : beatenOn != null
          ? const Icon(Icons.check_circle_outline, semanticLabel: 'Battuto')
          : null,
      onTap: unlocked ? onTap : null,
    );
  }

  String _kidDescription(AppLocalizations l10n) => switch (bot.id) {
    'pino' => l10n.kidBotPinoDescription,
    'chiara' => l10n.kidBotChiaraDescription,
    'rocco' => l10n.kidBotRoccoDescription,
    _ => '',
  };

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
