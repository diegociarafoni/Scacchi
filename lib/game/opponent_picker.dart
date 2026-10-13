import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../bot_gallery/bot_gallery_page.dart';
import '../bot_gallery/game_options.dart';
import '../engine/bot_collection.dart';
import '../engine/bots.dart';
import '../engine/levels.dart';
import '../engine/style.dart';
import '../l10n/app_localizations.dart';
import '../story/story_controller.dart';

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

/// Testi localizzati; senza localizzazione nel contesto si usa l'italiano.
AppLocalizations _l10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));

/// Apre la galleria dei bot; con [options] mostra anche il pannello Opzioni e
/// «Gioca» restituisce la partita già configurata.
Future<BotGalleryResult?> openBotGallery(
  BuildContext context, {
  required BotCollection collection,
  required GameSetup setup,
  required int adaptiveLevel,
  required bool kidMode,
  GameOptions? options,
}) => Navigator.push<BotGalleryResult>(
  context,
  MaterialPageRoute(
    builder: (_) => BotGalleryPage(
      collection: collection,
      loadStory: () async => (await StoryController.open()).state,
      initialBotId: setup.botId,
      initialSide: setup.sideChoice,
      adaptiveLevel: adaptiveLevel,
      kidMode: kidMode,
      showOptions: options != null,
      initialOptions: options ?? const GameOptions(),
    ),
  ),
);

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
    this.onGalleryPlay,
    this.galleryOptions = const GameOptions(),
  });

  final GameSetup setup;

  /// Profilo bambino (RP-06): niente computer, solo bot amichevoli e nessun numero.
  final bool kidMode;
  final bool computerAvailable;
  final int adaptiveLevel;
  final BotCollection collection;
  final ValueChanged<GameSetup> onChanged;

  /// Se c'è, «Gioca» nella galleria avvia la partita con le opzioni scelte
  /// lì (cadenza, variante, handicap, allenatore); senza, la galleria mostra
  /// solo la scelta del bot e il colore, e restituisce la configurazione.
  final ValueChanged<BotGalleryResult>? onGalleryPlay;
  final GameOptions galleryOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = _l10n(context);
    final shown = kidMode ? setup.forKids() : setup;
    final level = engineLevel(adaptiveLevel);
    // «Adattivo» è un avversario senza volto che gioca col motore: lo si sceglie
    // tra i bot, dove stanno anche i livelli fissi.
    final vsAdaptive = shown.opponent == Opponent.computer && shown.adaptive;
    final vsBot = shown.opponent == Opponent.bot;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<Opponent>(
          segments: [
            ButtonSegment(
              value: Opponent.human,
              icon: const Icon(Icons.people_outline),
              label: Text(l10n.opponentHuman),
            ),
            ButtonSegment(
              value: Opponent.bot,
              icon: const Icon(Icons.emoji_people_outlined),
              label: Text(l10n.opponentBot),
              enabled: computerAvailable,
            ),
          ],
          selected: {
            shown.opponent == Opponent.computer ? Opponent.bot : shown.opponent,
          },
          // Contro un bot si riparte dall'adattivo, del livello del giocatore.
          onSelectionChanged: (s) => onChanged(
            s.first != Opponent.bot
                ? shown.copyWith(opponent: s.first)
                : vsAdaptive || vsBot
                ? shown
                : kidMode
                ? shown.copyWith(opponent: Opponent.bot)
                : shown.copyWith(opponent: Opponent.computer, adaptive: true),
          ),
        ),
        const SizedBox(height: 8),
        Text(switch (shown.opponent) {
          Opponent.human => l10n.opponentHintHuman,
          Opponent.computer || Opponent.bot => l10n.opponentHintBot,
        }, style: theme.textTheme.bodySmall),
        if (!computerAvailable) ...[
          const SizedBox(height: 8),
          Text(
            kidMode ? l10n.kidBotUnavailable : l10n.opponentNoEngine,
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (vsAdaptive || vsBot) ...[
          const SizedBox(height: 16),
          Text(l10n.opponentPlayAs, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          SegmentedButton<SideChoice>(
            segments: [
              ButtonSegment(
                value: SideChoice.white,
                label: Text(l10n.opponentSideWhite),
              ),
              ButtonSegment(
                value: SideChoice.random,
                label: Text(l10n.opponentSideRandom),
              ),
              ButtonSegment(
                value: SideChoice.black,
                label: Text(l10n.opponentSideBlack),
              ),
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
              title: Text(l10n.opponentAdaptive),
              subtitle: Text(
                l10n.opponentAdaptiveInfo(level.id, level.approxElo),
              ),
              onTap: () => onChanged(
                shown.copyWith(opponent: Opponent.computer, adaptive: true),
              ),
            ),
          OutlinedButton.icon(
            key: const Key('open-bot-gallery'), // l10n-ok
            icon: const Icon(Icons.grid_view_rounded),
            label: Text(l10n.botGalleryOpen),
            onPressed: () async {
              final result = await openBotGallery(
                context,
                collection: collection,
                setup: shown,
                adaptiveLevel: adaptiveLevel,
                kidMode: kidMode,
                options: onGalleryPlay == null ? null : galleryOptions,
              );
              if (result == null) return;
              if (onGalleryPlay != null) {
                onGalleryPlay!(result);
              } else {
                onChanged(result.applyTo(shown));
              }
            },
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
    final l10n = _l10n(context);
    final unlocked = collection.isUnlocked(bot);
    final beatenOn = collection.beatenOn(bot);
    final details = kidMode
        ? friendlyBotDescriptions[bot.id]?.call(l10n) ?? ''
        : [
            '${bot.elo} Elo',
            styleLabel(bot.style),
            bot.openingName,
            if (beatenOn != null) l10n.opponentBeatenOn(_date(beatenOn)),
            if (!unlocked)
              l10n.botUnlockHint(
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
          ? Icon(Icons.lock_outline, semanticLabel: l10n.opponentLocked)
          : beatenOn != null
          ? Icon(Icons.check_circle_outline, semanticLabel: l10n.opponentBeaten)
          : null,
      onTap: unlocked ? onTap : null,
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
