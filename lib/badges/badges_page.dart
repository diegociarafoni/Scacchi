import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../progress/progress_controller.dart';
import 'badge_art.dart';
import 'badge_def.dart';
import 'badges_l10n.dart';
import 'opening_books_tab.dart';

/// Galleria dei badge (RG-17) e dei libri delle aperture: griglia a card con
/// il contatore dei raggiunti, bloccati in grigio con il lucchetto.
class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key, required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final l = badgesL10n(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.badgesTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.badgesTabBadges),
              Tab(text: l.badgesTabBooks),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => TabBarView(
            children: [
              _BadgesTab(controller: controller),
              OpeningBooksTab(state: controller.state),
            ],
          ),
        ),
      ),
    );
  }
}

/// Totale «X su Y raggiunti» con la barra di avanzamento.
class GalleryCounter extends StatelessWidget {
  const GalleryCounter({
    super.key,
    required this.earned,
    required this.total,
    this.hint,
  });

  final int earned;
  final int total;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l = badgesL10n(context);
    final theme = Theme.of(context);
    final label = l.badgesSummary(earned, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : earned / total,
            minHeight: 10,
            semanticsLabel: label,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(hint!, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}

/// Righe di riquadri alla stessa altezza, per qualsiasi corpo del testo.
/// [itemBuilder] riceve la larghezza di una cella.
class GalleryGrid extends StatelessWidget {
  const GalleryGrid({
    super.key,
    required this.count,
    required this.itemBuilder,
    this.gap = 10,
  });

  final int count;
  final Widget Function(BuildContext context, int index, double width)
  itemBuilder;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = (box.maxWidth / 120).floor().clamp(3, 8);
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Column(
          children: [
            for (var i = 0; i < count; i += columns) ...[
              if (i > 0) SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) SizedBox(width: gap),
                      SizedBox(
                        width: width,
                        child: i + c < count
                            ? itemBuilder(context, i + c, width)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BadgesTab extends StatelessWidget {
  const _BadgesTab({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final facts = BadgeFacts(controller.state, controller.badgeSources);
    final earned = badges
        .where((b) => controller.badges.containsKey(b.id))
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GalleryCounter(earned: earned, total: badges.length),
        for (final family in BadgeFamily.values)
          _Family(family: family, facts: facts, controller: controller),
      ],
    );
  }
}

class _Family extends StatelessWidget {
  const _Family({
    required this.family,
    required this.facts,
    required this.controller,
  });

  final BadgeFamily family;
  final BadgeFacts facts;
  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final l = badgesL10n(context);
    final members = badges.where((b) => b.family == family).toList();
    final earned = members
        .where((b) => controller.badges.containsKey(b.id))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            '${badgeFamilyTitle(l, family)} · $earned/${members.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 10),
        GalleryGrid(
          count: members.length,
          itemBuilder: (context, i, _) => BadgeTile(
            badge: members[i],
            facts: facts,
            earnedDay: controller.badges[members[i].id],
          ),
        ),
      ],
    );
  }
}

/// Card di un badge; toccata, ne apre la scheda.
class BadgeTile extends StatelessWidget {
  const BadgeTile({
    super.key,
    required this.badge,
    required this.facts,
    required this.earnedDay,
  });

  final BadgeDef badge;
  final BadgeFacts facts;

  /// Numero del giorno di calendario in cui è stato ottenuto, se lo è.
  final int? earnedDay;

  bool get _earned => earnedDay != null;

  @override
  Widget build(BuildContext context) {
    final l = badgesL10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = badgeName(l, badge);
    final value = badge.value(facts);
    final progress = !_earned && badge.hasProgress && value > 0
        ? l.badgesProgress(value, badge.target)
        : null;
    final label = _earned
        ? l.badgesSemanticsEarned(name)
        : progress == null
        ? l.badgesSemanticsLocked(name)
        : l.badgesSemanticsLockedProgress(name, value, badge.target);
    final tier = badgeTierLabel(l, badge.tier);
    final (tint, _) = badgePalette(badge.family);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: _earned
            ? Color.alphaBlend(tint.withAlpha(36), scheme.surfaceContainerLow)
            : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showDetail(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BadgeArt(badge: badge, earned: _earned, size: 64),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _earned ? null : scheme.onSurfaceVariant,
                  ),
                ),
                if (tier != null) Text(tier, style: theme.textTheme.labelSmall),
                if (progress != null)
                  Text(
                    progress,
                    style: theme.textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => BadgeDetail(badge: badge, facts: facts, day: earnedDay),
      ),
    );
  }
}

/// Medaglia del badge, per chi la mostra fuori dalla galleria.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({
    super.key,
    required this.badge,
    required this.earned,
    required this.size,
  });

  final BadgeDef badge;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) =>
      BadgeArt(badge: badge, earned: earned, size: size);
}

/// Scheda di un badge: come si ottiene, avanzamento o data.
class BadgeDetail extends StatelessWidget {
  const BadgeDetail({
    super.key,
    required this.badge,
    required this.facts,
    required this.day,
  });

  final BadgeDef badge;
  final BadgeFacts facts;
  final int? day;

  @override
  Widget build(BuildContext context) {
    final l = badgesL10n(context);
    final theme = Theme.of(context);
    final earnedDay = day;
    final value = badge.value(facts);
    final tier = badgeTierLabel(l, badge.tier);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeArt(badge: badge, earned: earnedDay != null, size: 120),
            const SizedBox(height: 16),
            Text(
              badgeName(l, badge),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Text(
              [badgeFamilyTitle(l, badge.family), ?tier].join(' · '),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Text(
              badgeDescription(l, badge),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (earnedDay != null)
              Text(
                l.badgesEarnedOn(_date(context, earnedDay)),
                style: theme.textTheme.titleSmall,
              )
            else ...[
              if (badge.hasProgress) ...[
                LinearProgressIndicator(
                  value: value / badge.target,
                  minHeight: 8,
                  semanticsLabel: l.badgesProgress(value, badge.target),
                ),
                const SizedBox(height: 4),
                Text(
                  l.badgesProgress(value, badge.target),
                  style: theme.textTheme.titleSmall,
                ),
              ] else
                Text(l.badgesNotYet, style: theme.textTheme.titleSmall),
            ],
          ],
        ),
      ),
    );
  }

  /// I giorni sono numeri di giorno di calendario locale (vedi `dayNumber`).
  String _date(BuildContext context, int day) {
    final utc = DateTime.fromMillisecondsSinceEpoch(
      day * Duration.millisecondsPerDay,
      isUtc: true,
    );
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(DateTime(utc.year, utc.month, utc.day));
  }
}
