import 'package:flutter/material.dart';

import '../progress/progress_controller.dart';
import 'badge_art.dart';
import 'badge_def.dart';
import 'badges_l10n.dart';

/// Gli ultimi badge ottenuti, dal più recente: fascia riutilizzabile (per
/// esempio dalla home). Vuota se non ce n'è nessuno.
class RecentBadges extends StatelessWidget {
  const RecentBadges({
    super.key,
    required this.controller,
    this.count = 4,
    this.size = 56,
    this.onTap,
  });

  final ProgressController controller;
  final int count;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l = badgesL10n(context);
        final recent = recentBadges(controller.badges, count);
        if (recent.isEmpty) return const SizedBox.shrink();
        return Semantics(
          button: onTap != null,
          label: l.badgesRecentSemantics(
            recent.map((b) => badgeName(l, b)).join(', '),
          ),
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                for (final b in recent)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: BadgeArt(badge: b, earned: true, size: size),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Badge ottenuti, i più recenti per primi; a parità di giorno vale l'ordine
/// inverso del catalogo.
List<BadgeDef> recentBadges(Map<String, int> earned, int count) {
  final all = [
    for (final b in badges)
      if (earned.containsKey(b.id)) b,
  ];
  final order = {for (var i = 0; i < all.length; i++) all[i].id: i};
  all.sort((a, b) {
    final byDay = earned[b.id]!.compareTo(earned[a.id]!);
    return byDay != 0 ? byDay : order[b.id]!.compareTo(order[a.id]!);
  });
  return all.take(count).toList();
}
