import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/bot_collection.dart';
import '../engine/bots.dart';
import '../engine/levels.dart';
import '../engine/style.dart';
import '../game/clock.dart';
import '../game/clock_l10n.dart';
import '../game/handicap.dart';
import '../game/opponent_picker.dart';
import '../game/variant.dart';
import '../l10n/app_localizations.dart';
import '../progress/avatar.dart';
import '../progress/guardian_avatar.dart';
import '../story/story.dart';
import '../theme/rokko_theme.dart';
import '../theme/sheets.dart';
import 'bot_greetings.dart';
import 'bot_tiers.dart';
import 'game_options.dart';

/// Scelta fatta nella galleria: il bot (o il computer adattivo) e il colore.
class BotGalleryResult {
  const BotGalleryResult({
    required this.botId,
    required this.sideChoice,
    this.adaptive = false,
    this.options = const GameOptions(),
  });

  final String botId;
  final SideChoice sideChoice;

  /// Cadenza, variante, handicap e allenatore scelti con «Opzioni».
  final GameOptions options;

  /// Il computer che si adatta al giocatore, al posto di un bot.
  final bool adaptive;

  /// [setup] con l'avversario e il colore scelti nella galleria.
  GameSetup applyTo(GameSetup setup) => setup.copyWith(
    opponent: adaptive ? Opponent.computer : Opponent.bot,
    adaptive: adaptive ? true : setup.adaptive,
    botId: adaptive ? setup.botId : botId,
    sideChoice: sideChoice,
  );
}

/// Testi localizzati; senza localizzazione nel contesto si usa l'italiano.
AppLocalizations _l10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));

const _adaptiveId = '@adaptive';
const _gap = 8.0;

/// Galleria dei bot (RG-18): il bot scelto con saluto, nome ed Elo, la griglia
/// per fascia con lucchetti e corone, i custodi della Storia e il colore. Si
/// apre con `Navigator.push<BotGalleryResult>` e restituisce la scelta con
/// «Gioca». Vedi docs/bot.md.
class BotGalleryPage extends StatefulWidget {
  const BotGalleryPage({
    super.key,
    required this.collection,
    this.story = const StoryState(),
    this.loadStory,
    this.initialBotId,
    this.initialSide = SideChoice.random,
    this.adaptiveLevel = defaultEngineLevel,
    this.kidMode = false,
    this.confirmLabel,
    this.showOptions = true,
    this.initialOptions = const GameOptions(),
  });

  final BotCollection collection;

  /// Avanzamento della Storia; [loadStory], se c'è, lo rilegge all'apertura.
  final StoryState story;
  final Future<StoryState> Function()? loadStory;

  /// Bot già scelto; senza, il primo sbloccato che non si è ancora battuto.
  final String? initialBotId;
  final SideChoice initialSide;

  /// Livello del computer adattivo, per mostrarne l'Elo.
  final int adaptiveLevel;

  /// Profilo bambino (RP-06): solo i bot amici, nessun numero.
  final bool kidMode;

  /// Testo del bottone di conferma; di norma «Gioca».
  final String? confirmLabel;

  /// Mostra il pannello «Opzioni» (cadenza, variante, handicap, allenatore).
  final bool showOptions;
  final GameOptions initialOptions;

  @override
  State<BotGalleryPage> createState() => _BotGalleryPageState();
}

class _BotGalleryPageState extends State<BotGalleryPage> {
  late String _selected = _firstChoice();
  late SideChoice _side = widget.initialSide;
  late StoryState _story = widget.story;

  /// Il profilo bambino conosce solo «senza tempo» e la cadenza lenta.
  late TimeControl? _control =
      widget.kidMode && widget.initialOptions.control != _kidClock
      ? null
      : widget.initialOptions.control;
  late Variant _variant = widget.initialOptions.variant;
  late HandicapPiece? _handicapPiece = widget.initialOptions.handicap?.piece;
  late int? _handicapMinutes = widget.initialOptions.handicap?.giverMinutes;
  late HandicapGiver _handicapGiver =
      widget.initialOptions.handicap?.giver ?? HandicapGiver.player;
  late bool _coach = widget.initialOptions.coach;
  late bool _training = widget.initialOptions.training;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStory());
  }

  Future<void> _loadStory() async {
    try {
      final story = await widget.loadStory?.call();
      if (story != null && mounted) setState(() => _story = story);
    } on Object catch (_) {
      // Senza la Storia i custodi restano da incontrare.
    }
  }

  void _select(String id) => setState(() => _selected = id);

  void _chooseSide(SideChoice side) => setState(() => _side = side);

  List<Bot> get _ladder => widget.kidMode ? friendlyBots : bots;

  String _firstChoice() {
    final initial = widget.initialBotId;
    final visible =
        _ladder.any((b) => b.id == initial) ||
        (!widget.kidMode &&
            (initial == _adaptiveId ||
                storyOnlyBots.any((b) => b.id == initial)));
    if (initial != null && visible) return initial;
    final next = _ladder.where(
      (b) => widget.collection.isUnlocked(b) && !widget.collection.isBeaten(b),
    );
    return (next.firstOrNull ?? _ladder.first).id;
  }

  /// Un custode solo della Storia si apre finendo il suo capitolo.
  StoryChapter? _chapterOf(Bot bot) =>
      storyChapters.where((c) => c.botId == bot.id).firstOrNull;

  bool _storyOnly(Bot bot) => !bots.contains(bot);

  bool _unlocked(Bot bot) => _storyOnly(bot)
      ? _story.isBossBeaten(_chapterOf(bot)?.id ?? '')
      : widget.collection.isUnlocked(bot);

  bool _met(Bot bot) => _story.isBossBeaten(_chapterOf(bot)?.id ?? '');

  /// Battuto in scala o, per un custode solo della Storia, nel suo capitolo.
  bool _beaten(Bot bot) =>
      widget.collection.isBeaten(bot) || (_storyOnly(bot) && _met(bot));

  bool get _adaptive => _selected == _adaptiveId;

  Bot get _bot => botById(_selected) ?? _ladder.first;

  Handicap? get _handicap => _handicapPiece == null && _handicapMinutes == null
      ? null
      : Handicap(
          piece: _handicapPiece,
          giverMinutes: _handicapMinutes,
          giver: _handicapGiver,
        );

  /// Il profilo bambino sceglie solo tra senza orologio e una cadenza lenta.
  GameOptions get _options => widget.kidMode
      ? GameOptions(control: _control)
      : GameOptions(
          control: _control,
          variant: _variant,
          handicap: _handicap,
          coach: _coach && _training,
          training: _training,
        );

  void _play() => Navigator.pop(
    context,
    BotGalleryResult(
      botId: _adaptive ? _ladder.first.id : _bot.id,
      sideChoice: _side,
      adaptive: _adaptive,
      options: _options,
    ),
  );

  void _openOptions() => showRokkoSheet<void>(
    context: context,
    builder: (_) => _OptionsSheet(page: this),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    final compact = MediaQuery.sizeOf(context).height < 520;
    final grid = _Grid(page: this, l10n: l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.botGalleryTitle)),
      body: Column(
        children: [
          if (compact)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(page: this, l10n: l10n),
                    grid,
                  ],
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Hero(page: this, l10n: l10n),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: grid,
              ),
            ),
          ],
          _Footer(page: this, l10n: l10n),
        ],
      ),
    );
  }
}

/// Bot scelto in alto: avatar grande, fumetto di saluto, nome ed Elo.
class _Hero extends StatelessWidget {
  const _Hero({required this.page, required this.l10n});

  final _BotGalleryPageState page;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adaptive = page._adaptive;
    final bot = page._bot;
    final unlocked = adaptive || page._unlocked(bot);
    final beaten = !adaptive && page._beaten(bot);
    final kid = page.widget.kidMode;
    final avatarSize = MediaQuery.sizeOf(context).height < 700 ? 72.0 : 88.0;
    final String line;
    if (adaptive) {
      line = l10n.botAdaptiveGreeting;
    } else if (!unlocked) {
      line = l10n.botGalleryLockedTease;
    } else if (beaten) {
      line = botRematchLine(l10n, bot.id);
    } else {
      line = botGreeting(l10n, bot.id);
    }
    final name = adaptive ? l10n.botAdaptiveName : bot.name;
    final level = adaptive
        ? engineLevel(page.widget.adaptiveLevel).approxElo
        : bot.elo;
    String? hint;
    if (!adaptive && !unlocked) {
      hint = page._storyOnly(bot)
          ? l10n.botUnlockStory
          : l10n.botUnlockHint(BotCollection.unlockedBy(bot).first.name);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            adaptive
                ? _AdaptiveAvatar(size: avatarSize)
                : GuardianAvatar(
                    bot: bot,
                    size: avatarSize,
                    expression: !unlocked
                        ? AvatarExpression.neutral
                        : beaten
                        ? AvatarExpression.happy
                        : AvatarExpression.greeting,
                  ),
            CustomPaint(
              size: const Size(10, 16),
              painter: _TailPainter(theme.colorScheme.surfaceContainerHigh),
            ),
            Expanded(
              child: Container(
                key: const Key('gallery-greeting'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(
                    RokkoTokens.of(context).radiusLarge,
                  ),
                ),
                child: Text(line, style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            Text(
              name,
              key: const Key('gallery-name'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!kid)
              Text(
                l10n.botGalleryElo(level),
                key: const Key('gallery-elo'),
                style: theme.textTheme.titleMedium,
              ),
          ],
        ),
        if (kid && !adaptive)
          Text(
            friendlyBotDescriptions[bot.id]?.call(l10n) ?? '',
            style: theme.textTheme.bodySmall,
          )
        else if (!adaptive)
          Text(
            l10n.botGalleryStyle(_styleName(l10n, bot.style)),
            style: theme.textTheme.bodySmall,
          )
        else
          Text(l10n.botAdaptiveHint(level), style: theme.textTheme.bodySmall),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hint,
                    key: const Key('gallery-unlock-hint'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  static String _styleName(AppLocalizations l10n, BotStyle style) =>
      switch (style) {
        BotStyle.aggressive => l10n.botStyleAggressive,
        BotStyle.positional => l10n.botStylePositional,
        BotStyle.gambitist => l10n.botStyleGambitist,
      };
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(size.width, size.height * 0.2)
      ..lineTo(0, size.height * 0.85)
      ..lineTo(size.width, size.height)
      ..close(),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

/// Fasce con i bot, carta Adattivo e custodi della Storia.
class _Grid extends StatelessWidget {
  const _Grid({required this.page, required this.l10n});

  final _BotGalleryPageState page;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final kid = page.widget.kidMode;
    final tierNames = {
      BotTier.novice: l10n.botTierNovice,
      BotTier.beginner: l10n.botTierBeginner,
      BotTier.intermediate: l10n.botTierIntermediate,
      BotTier.advanced: l10n.botTierAdvanced,
      BotTier.master: l10n.botTierMaster,
    };
    return LayoutBuilder(
      builder: (context, box) {
        final columns = math.max(
          5,
          ((box.maxWidth + _gap) / (88 + _gap)).floor(),
        );
        final cell = (box.maxWidth - _gap * (columns - 1)) / columns;
        Widget cells(List<Widget> children) =>
            Wrap(spacing: _gap, runSpacing: _gap, children: children);
        Widget botCell(Bot bot, {String prefix = 'bot'}) => _BotCell(
          key: Key('$prefix-${bot.id}'),
          bot: bot,
          size: cell,
          locked: !page._unlocked(bot),
          beaten: page._beaten(bot),
          selected: !page._adaptive && page._selected == bot.id,
          dim: prefix == 'guardian' && !page._met(bot),
          kid: kid,
          l10n: l10n,
          onTap: () => page._select(bot.id),
        );
        final chapters = [
          for (final c in storyChapters)
            if (botById(c.botId) != null) c,
        ];
        final met = chapters
            .where((c) => page._story.isBossBeaten(c.id))
            .length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kid) ...[
              _Heading(
                l10n.botTierHeading(l10n.botTierFriends, friendlyBots.length),
              ),
              cells([for (final b in friendlyBots) botCell(b)]),
            ] else ...[
              for (final tier in BotTier.values) ...[
                _Heading(
                  l10n.botTierHeading(
                    tierNames[tier]!,
                    botsInTier(tier).length,
                  ),
                ),
                cells([for (final b in botsInTier(tier)) botCell(b)]),
              ],
              _Heading(l10n.botTierHeading(l10n.botTierAdaptive, 1)),
              cells([
                _AdaptiveCell(
                  key: const Key('bot-adaptive'), // l10n-ok
                  size: cell,
                  selected: page._adaptive,
                  label: l10n.botAdaptiveName,
                  onTap: () => page._select(_adaptiveId),
                ),
              ]),
              _Heading(l10n.botGuardiansTitle),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  key: const Key('guardians-progress'),
                  value: chapters.isEmpty ? 0 : met / chapters.length,
                  minHeight: 10,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l10n.botGuardiansProgress(met, chapters.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              cells([
                for (final c in chapters)
                  botCell(botById(c.botId)!, prefix: 'guardian'),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.botGuardiansHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// Un bot nella griglia: avatar, lucchetto se bloccato, corona se battuto.
class _BotCell extends StatelessWidget {
  const _BotCell({
    super.key,
    required this.bot,
    required this.size,
    required this.locked,
    required this.beaten,
    required this.selected,
    required this.dim,
    required this.kid,
    required this.l10n,
    required this.onTap,
  });

  final Bot bot;
  final double size;
  final bool locked;
  final bool beaten;
  final bool selected;

  /// Custode della Storia non ancora incontrato.
  final bool dim;
  final bool kid;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = RokkoTokens.of(context);
    final state = locked
        ? l10n.botGalleryStateLocked
        : beaten
        ? l10n.botGalleryStateBeaten
        : l10n.botGalleryStateOpen;
    var label = kid
        ? l10n.botGalleryCellLabelKid(bot.name, state)
        : l10n.botGalleryCellLabel(bot.name, bot.elo, state);
    if (dim) label = '$label, ${l10n.botGuardianUnmet}';
    final radius = BorderRadius.circular(tokens.radiusSmall);
    return SizedBox.square(
      dimension: size,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(3),
                child: Opacity(
                  opacity: locked || dim ? 0.45 : 1,
                  child: ClipRRect(
                    borderRadius: radius,
                    child: GuardianAvatar(bot: bot, size: size),
                  ),
                ),
              ),
              if (selected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: tokens.action, width: 3),
                  ),
                ),
              if (locked)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _Badge(
                    icon: Icons.lock,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              if (beaten)
                const Align(
                  alignment: Alignment.topRight,
                  child: _Badge(
                    icon: Icons.workspace_premium,
                    color: Color(0xffffc107),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(1),
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 14, color: color),
  );
}

/// Carta del computer che si adatta, al posto di un personaggio.
class _AdaptiveCell extends StatelessWidget {
  const _AdaptiveCell({
    super.key,
    required this.size,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final double size;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = RokkoTokens.of(context);
    final radius = BorderRadius.circular(tokens.radiusSmall);
    return SizedBox.square(
      dimension: size,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: selected
                  ? Border.all(color: tokens.action, width: 3)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: _AdaptiveAvatar(size: size),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveAvatar extends StatelessWidget {
  const _AdaptiveAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff3949ab), Color(0xff7e57c2)],
        ),
      ),
      child: Icon(Icons.auto_graph, size: size * 0.55, color: Colors.white),
    ),
  );
}

/// Colore e bottone di conferma, sempre in vista in fondo.
class _Footer extends StatelessWidget {
  const _Footer({required this.page, required this.l10n});

  final _BotGalleryPageState page;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locked = !page._adaptive && !page._unlocked(page._bot);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (page.widget.showOptions)
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('gallery-options'),
                        icon: const Icon(Icons.tune),
                        label: Text(l10n.botOptions),
                        onPressed: page._openOptions,
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 8),
                  for (final (key, side, mark, label) in [
                    (
                      'side-white',
                      SideChoice.white,
                      const _SideMark.disc(Colors.white),
                      l10n.botSideWhite,
                    ),
                    (
                      'side-random',
                      SideChoice.random,
                      const _SideMark.text('?'),
                      l10n.botSideRandom,
                    ),
                    (
                      'side-black',
                      SideChoice.black,
                      const _SideMark.disc(Color(0xff1b1b1f)),
                      l10n.botSideBlack,
                    ),
                  ])
                    _SideButton(
                      key: Key(key),
                      mark: mark,
                      label: label,
                      selected: page._side == side,
                      onTap: () => page._chooseSide(side),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('gallery-play'),
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(
                    RokkoTokens.of(context).kidTouch,
                  ),
                ),
                onPressed: locked ? null : page._play,
                child: Text(
                  locked
                      ? l10n.botGalleryLockedPlay
                      : page.widget.confirmLabel ?? l10n.botGalleryPlay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    super.key,
    required this.mark,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _SideMark mark;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = RokkoTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(tokens.radiusSmall),
              border: Border.all(
                color: selected ? tokens.action : scheme.outlineVariant,
                width: selected ? 3 : 1,
              ),
            ),
            child: mark,
          ),
        ),
      ),
    );
  }
}

/// Segno del colore: un disco bianco o nero, o il punto interrogativo del
/// caso. Disegnato, non scritto, così non dipende dai caratteri disponibili.
class _SideMark extends StatelessWidget {
  const _SideMark.disc(Color this.color) : text = null;

  const _SideMark.text(String this.text) : color = null;

  final Color? color;
  final String? text;

  @override
  Widget build(BuildContext context) => text != null
      ? Text(text!, style: const TextStyle(fontSize: 26))
      : Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey, width: 1.5),
          ),
        );
}

/// Pannello a comparsa con le opzioni della partita: cadenza, variante,
/// handicap e allenatore. Nel profilo bambino solo la cadenza.
class _OptionsSheet extends StatefulWidget {
  const _OptionsSheet({required this.page});

  final _BotGalleryPageState page;

  @override
  State<_OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends State<_OptionsSheet> {
  _BotGalleryPageState get _page => widget.page;

  /// Cambia lo stato della galleria e ridisegna anche il pannello.
  void _change(VoidCallback change) {
    _page.setState(change);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    final theme = Theme.of(context);
    final kid = _page.widget.kidMode;
    final groups = TimeControl.presetsByCategory;
    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleSmall),
      ),
    );
    Widget chips(List<Widget> children) =>
        Wrap(spacing: 8, runSpacing: 8, children: children);
    Widget timeChip(String label, TimeControl? control, Key key) => ChoiceChip(
      key: key,
      label: Text(label),
      selected: _page._control == control,
      onSelected: (_) => _change(() {
        _page._control = control;
        // Il tempo di handicap vale solo con un orologio.
        if (control == null) _page._handicapMinutes = null;
      }),
    );
    final standard = _page._variant == Variant.standard;
    final pieces = {
      HandicapPiece.fPawn: l10n.handicapPieceFPawn,
      HandicapPiece.knight: l10n.handicapPieceKnight,
      HandicapPiece.rook: l10n.handicapPieceRook,
      HandicapPiece.queen: l10n.handicapPieceQueen,
    };
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.botOptions, style: theme.textTheme.titleLarge),
                    title(l10n.botOptionsTime),
                    chips([
                      timeChip(
                        l10n.botOptionsNoClock,
                        null,
                        const Key('option-time-none'),
                      ),
                      if (kid)
                        timeChip(
                          l10n.botOptionsKidSlow,
                          _kidClock,
                          const Key('option-time-slow'),
                        ),
                    ]),
                    if (!kid)
                      for (final entry in groups.entries) ...[
                        title(timeCategoryName(l10n, entry.key)),
                        chips([
                          for (final t in entry.value)
                            timeChip(t.label, t, Key('option-time-${t.label}')),
                        ]),
                      ],
                    if (!kid) ...[
                      title(l10n.botOptionsVariant),
                      chips([
                        for (final v in Variant.values)
                          ChoiceChip(
                            key: Key('option-variant-${v.name}'),
                            label: Text(_variantName(l10n, v)),
                            selected: _page._variant == v,
                            onSelected: (_) => _change(() {
                              _page._variant = v;
                              // Il pezzo in meno vale solo negli scacchi classici.
                              if (v != Variant.standard) {
                                _page._handicapPiece = null;
                              }
                            }),
                          ),
                      ]),
                      title(l10n.handicapTitle),
                      Text(l10n.handicapHint, style: theme.textTheme.bodySmall),
                      title(l10n.handicapPieceTitle),
                      chips([
                        ChoiceChip(
                          key: const Key('option-handicap-piece-none'),
                          label: Text(l10n.handicapNone),
                          selected: _page._handicapPiece == null,
                          onSelected: (_) =>
                              _change(() => _page._handicapPiece = null),
                        ),
                        for (final MapEntry(:key, :value) in pieces.entries)
                          ChoiceChip(
                            key: Key('option-handicap-piece-${key.name}'),
                            label: Text(value),
                            selected: _page._handicapPiece == key,
                            onSelected: standard
                                ? (_) =>
                                      _change(() => _page._handicapPiece = key)
                                : null,
                          ),
                      ]),
                      title(l10n.handicapTimeTitle),
                      chips([
                        ChoiceChip(
                          key: const Key('option-handicap-time-none'),
                          label: Text(l10n.handicapTimeEqual),
                          selected: _page._handicapMinutes == null,
                          onSelected: (_) =>
                              _change(() => _page._handicapMinutes = null),
                        ),
                        for (final m in Handicap.timeOptions)
                          ChoiceChip(
                            key: Key('option-handicap-time-$m'),
                            label: Text(l10n.handicapTimeMinutes(m)),
                            selected: _page._handicapMinutes == m,
                            onSelected: _page._control == null
                                ? null
                                : (_) =>
                                      _change(() => _page._handicapMinutes = m),
                          ),
                      ]),
                      Text(
                        l10n.handicapTimeHint,
                        style: theme.textTheme.bodySmall,
                      ),
                      if (_page._handicap != null) ...[
                        title(l10n.handicapGiverTitle),
                        chips([
                          for (final g in HandicapGiver.values)
                            ChoiceChip(
                              key: Key('option-handicap-giver-${g.name}'),
                              label: Text(
                                g == HandicapGiver.player
                                    ? l10n.handicapGiverYou
                                    : l10n.handicapGiverOpponent,
                              ),
                              selected: _page._handicapGiver == g,
                              onSelected: (_) =>
                                  _change(() => _page._handicapGiver = g),
                            ),
                        ]),
                      ],
                      title(l10n.botOptionsHelp),
                      SwitchListTile(
                        key: const Key('option-training'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.botOptionsTraining),
                        subtitle: Text(l10n.botOptionsTrainingHint),
                        value: _page._training,
                        onChanged: (v) => _change(() => _page._training = v),
                      ),
                      SwitchListTile(
                        key: const Key('option-coach'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.botOptionsCoach),
                        subtitle: Text(l10n.botOptionsCoachHint),
                        value: _page._coach && _page._training,
                        onChanged: _page._training
                            ? (v) => _change(() => _page._coach = v)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                key: const Key('options-done'),
                onPressed: () => Navigator.pop(context),
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _variantName(AppLocalizations l10n, Variant v) => switch (v) {
    Variant.standard => l10n.botVariantStandard,
    Variant.chess960 => l10n.botVariantChess960,
    Variant.kingOfTheHill => l10n.botVariantKingOfTheHill,
    Variant.threeCheck => l10n.botVariantThreeCheck,
  };
}

/// Cadenza lenta del profilo bambino: 15+10.
final _kidClock = TimeControl.presets.firstWhere(
  (t) => t.minutes == 15 && t.increment == 10,
);
