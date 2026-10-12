import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../progress/progress_controller.dart';
import 'badge_def.dart';
import 'badges_l10n.dart';

/// Raccolta dei badge (RG-17), per famiglia, con avanzamento e data.
class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key, required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final l = badgesL10n(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.badgesTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final facts = BadgeFacts(controller.state, controller.badgeSources);
          final earned = badges
              .where((b) => controller.badges.containsKey(b.id))
              .length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l.badgesSummary(earned, badges.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: earned / badges.length,
                minHeight: 8,
                semanticsLabel: l.badgesSummary(earned, badges.length),
              ),
              for (final family in BadgeFamily.values)
                _Family(family: family, facts: facts, controller: controller),
            ],
          );
        },
      ),
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
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) {
            const gap = 8.0;
            final columns = max(2, (box.maxWidth / 150).floor());
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final b in members)
                  SizedBox(
                    width: width,
                    child: BadgeTile(
                      badge: b,
                      facts: facts,
                      earnedDay: controller.badges[b.id],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Riquadro di un badge; toccato, ne apre la scheda.
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
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showDetail(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BadgeMedal(badge: badge, earned: _earned, size: 56),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (tier != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    tier,
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    progress,
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
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

/// Medaglia rotonda con l'icona del badge; spenta finché non si ottiene.
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ring = switch (badge.tier) {
      BadgeTier.none => scheme.outlineVariant,
      BadgeTier.bronze => scheme.tertiary,
      BadgeTier.silver => scheme.outline,
      BadgeTier.gold => scheme.primary,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        border: Border.all(color: earned ? ring : scheme.outlineVariant),
      ),
      child: Icon(
        earned ? badge.icon : Icons.lock_outline,
        size: size * 0.5,
        color: earned ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
      ),
    );
  }
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeMedal(badge: badge, earned: earnedDay != null, size: 96),
            const SizedBox(height: 16),
            Text(
              badgeName(l, badge),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (tier != null) Text(tier, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
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
