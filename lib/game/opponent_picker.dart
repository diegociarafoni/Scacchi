import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/bot_collection.dart';
import '../engine/bots.dart';
import '../engine/levels.dart';
import '../engine/style.dart';
import '../l10n/app_localizations.dart';

enum Opponent { human, computer, bot, friend }

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

/// Testi localizzati; senza localizzazione nel contesto si usa l'italiano.
AppLocalizations _l10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));

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
    this.friendAvailable = false,
  });

  final GameSetup setup;

  /// Mostra «Sfida un amico», con partita sullo stesso telefono o su due
  /// telefoni (RMP-08), al posto di «Due giocatori»; non c'è nel profilo bambino.
  final bool friendAvailable;

  /// Profilo bambino (RP-06): niente computer, solo bot amichevoli e nessun numero.
  final bool kidMode;
  final bool computerAvailable;
  final int adaptiveLevel;
  final BotCollection collection;
  final ValueChanged<GameSetup> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = kidMode ? setup.forKids() : setup;
    final level = engineLevel(adaptiveLevel);
    // «Adattivo» è un avversario senza volto che gioca col motore: lo si sceglie
    // tra i bot, dove stanno anche i livelli fissi.
    final vsAdaptive = shown.opponent == Opponent.computer && shown.adaptive;
    final vsBot = shown.opponent == Opponent.bot;
    final withFriend =
        shown.opponent == Opponent.human || shown.opponent == Opponent.friend;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (friendAvailable && !kidMode) ...[
          // Due scelte: contro un bot (anche adattivo) o contro un amico, che
          // a sua volta gioca sullo stesso telefono o sul suo.
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.emoji_people_outlined),
                label: const Text('Bot'),
                enabled: computerAvailable,
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.people_outline),
                label: Text(_l10n(context).opponentFriend),
              ),
            ],
            selected: {withFriend},
            onSelectionChanged: (s) => onChanged(
              s.first == withFriend
                  ? shown
                  : s.first
                  ? shown.copyWith(opponent: Opponent.human)
                  : shown.copyWith(opponent: Opponent.computer, adaptive: true),
            ),
          ),
          if (withFriend) ...[
            const SizedBox(height: 8),
            SegmentedButton<Opponent>(
              segments: [
                ButtonSegment(
                  value: Opponent.human,
                  icon: const Icon(Icons.phone_android),
                  label: Text(_l10n(context).opponentFriendSame),
                ),
                ButtonSegment(
                  value: Opponent.friend,
                  icon: const Icon(Icons.smartphone),
                  label: Text(_l10n(context).opponentFriendApart),
                ),
              ],
              selected: {shown.opponent},
              onSelectionChanged: (s) =>
                  onChanged(shown.copyWith(opponent: s.first)),
            ),
          ],
        ] else
          SegmentedButton<Opponent>(
            segments: [
              const ButtonSegment(
                value: Opponent.human,
                icon: Icon(Icons.people_outline),
                label: Text('Due giocatori'),
              ),
              ButtonSegment(
                value: Opponent.bot,
                icon: const Icon(Icons.emoji_people_outlined),
                label: const Text('Bot'),
                enabled: computerAvailable,
              ),
            ],
            selected: {
              shown.opponent == Opponent.computer
                  ? Opponent.bot
                  : shown.opponent,
            },
            onSelectionChanged: (s) => onChanged(
              s.first == Opponent.bot && vsAdaptive
                  ? shown
                  : shown.copyWith(opponent: s.first),
            ),
          ),
        const SizedBox(height: 8),
        Text(switch (shown.opponent) {
          Opponent.human => _l10n(context).opponentHintHuman,
          Opponent.computer || Opponent.bot => _l10n(context).opponentHintBot,
          Opponent.friend => _l10n(context).opponentHintFriend,
        }, style: theme.textTheme.bodySmall),
        if (!computerAvailable) ...[
          const SizedBox(height: 8),
          Text(
            kidMode ? AppLocalizations.of(context).kidBotUnavailable : 'Per giocare contro il computer qui serve Stockfish installato.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (vsAdaptive || vsBot) ...[
          const SizedBox(height: 16),
          Text('Giochi con', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          SegmentedButton<SideChoice>(
            segments: const [
              ButtonSegment(value: SideChoice.white, label: Text('Bianco')),
              ButtonSegment(value: SideChoice.random, label: Text('Caso')),
              ButtonSegment(value: SideChoice.black, label: Text('Nero')),
            ],
            selected: {shown.sideChoice},
            onSelectionChanged: (s) =>
                onChanged(shown.copyWith(sideChoice: s.first)),
          ),
          const SizedBox(height: 8),
          if (!kidMode)
            ListTile(
              key: const ValueKey('adaptive-opponent'),
              contentPadding: EdgeInsets.zero,
              selected: vsAdaptive,
              leading: const Icon(Icons.trending_up, size: 28),
              title: const Text('Adattivo'),
              subtitle: Text(
                'Livello ${level.id}, circa ${level.approxElo} Elo: si adegua '
                'ai tuoi risultati, per vincere circa metà delle partite.',
              ),
              onTap: () => onChanged(
                shown.copyWith(opponent: Opponent.computer, adaptive: true),
              ),
            ),
          for (final bot in kidMode ? friendlyBots : bots)
            _BotTile(
              bot: bot,
              collection: collection,
              kidMode: kidMode,
              selected: vsBot && bot.id == shown.botId,
              onTap: () => onChanged(
                shown.copyWith(opponent: Opponent.bot, botId: bot.id),
              ),
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
        ? friendlyBotDescriptions[bot.id]?.call(AppLocalizations.of(context)) ??
              ''
        : [
            '${bot.elo} Elo',
            styleLabel(bot.style),
            bot.openingName,
            if (beatenOn != null) 'Battuto il ${_date(beatenOn)}',
            if (!unlocked)
              _l10n(context).botUnlockHint(
                BotCollection.unlockedBy(bot).map((b) => b.name).join(' / '),
              ),
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
              semanticLabel: 'Bloccato: batti un bot del gradino sotto',
            )
          : beatenOn != null
          ? const Icon(Icons.check_circle_outline, semanticLabel: 'Battuto')
          : null,
      onTap: unlocked ? onTap : null,
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
