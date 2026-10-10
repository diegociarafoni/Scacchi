import 'package:flutter/material.dart';

import 'achievements.dart';
import 'daily_goal.dart';
import 'progress_controller.dart';
import 'xp.dart';

String goalLabel(DailyGoal goal) => switch (goal.kind) {
  GoalKind.games => goal.target == 1 ? '1 partita' : '${goal.target} partite',
  GoalKind.puzzles => '${goal.target} puzzle',
  GoalKind.minutes => '${goal.target} minuti',
};

String _unit(GoalKind kind) => switch (kind) {
  GoalKind.games => 'partite',
  GoalKind.puzzles => 'puzzle',
  GoalKind.minutes => 'minuti',
};

const _weekdays = [
  'Lunedì',
  'Martedì',
  'Mercoledì',
  'Giovedì',
  'Venerdì',
  'Sabato',
  'Domenica',
];

/// Profilo del giocatore: livello, serie, obiettivo, traguardi e preferenze.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final enabled = controller.settings.enabled;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (enabled) ...[
                _LevelCard(xp: controller.state.xp),
                const SizedBox(height: 12),
                _StreakCard(controller: controller),
                const SizedBox(height: 24),
                Text(
                  'Traguardi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _Achievements(unlocked: controller.state.unlocked),
                const SizedBox(height: 24),
              ],
              _Settings(controller: controller),
            ],
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    final level = levelForXp(xp);
    final next = xpForLevel(level + 1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Livello $level',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: levelProgress(xp),
              minHeight: 8,
              semanticsLabel: 'Avanzamento del livello: $xp su $next XP',
            ),
            const SizedBox(height: 4),
            Text('$xp / $next XP'),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final streak = controller.streak;
    final goal = controller.settings.goal;
    final progress = controller.todayProgress;
    final reached = progress >= goal.target;
    final freezes = controller.freezes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, semanticLabel: 'Serie'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    streak == 1 ? '1 giorno di fila' : '$streak giorni di fila',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Record: ${controller.state.bestStreak}'),
            Text(
              freezes == 1
                  ? '1 protezione della serie'
                  : '$freezes protezioni della serie',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (progress / goal.target).clamp(0, 1).toDouble(),
              minHeight: 8,
              semanticsLabel: 'Obiettivo di oggi: $progress su ${goal.target}',
            ),
            const SizedBox(height: 4),
            Text(
              '${reached ? 'Obiettivo raggiunto' : 'Obiettivo di oggi'}: '
              '${progress.clamp(0, goal.target)} / ${goal.target} '
              '${_unit(goal.kind)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.unlocked});

  final List<String> unlocked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final a in achievements)
          Builder(
            builder: (context) {
              final done = unlocked.contains(a.id);
              return MergeSemantics(
                child: Semantics(
                  label:
                      '${a.title}, ${done ? 'ottenuto' : 'da ottenere'}. '
                      '${a.description}',
                  excludeSemantics: true,
                  child: ListTile(
                    leading: Icon(
                      done ? Icons.emoji_events : Icons.lock_outline,
                      color: done ? scheme.primary : scheme.outline,
                    ),
                    title: Text(a.title),
                    subtitle: Text(a.description),
                    enabled: done,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Settings extends StatelessWidget {
  const _Settings({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Impostazioni', style: Theme.of(context).textTheme.titleLarge),
        SwitchListTile(
          key: const Key('enabled'),
          title: const Text('XP, serie e traguardi'),
          subtitle: const Text('Spento, non si registra nulla.'),
          value: s.enabled,
          onChanged: (v) => controller.updateSettings(s.copyWith(enabled: v)),
        ),
        if (s.enabled) ...[
          ListTile(
            title: const Text('Obiettivo giornaliero'),
            trailing: DropdownButton<DailyGoal>(
              key: const Key('goal'),
              value: s.goal,
              items: [
                for (final g in {s.goal, ...DailyGoal.presets})
                  DropdownMenuItem(value: g, child: Text(goalLabel(g))),
              ],
              onChanged: (g) {
                if (g != null) controller.updateSettings(s.copyWith(goal: g));
              },
            ),
          ),
          ListTile(
            title: const Text('Giorno di riposo'),
            subtitle: const Text('Non interrompe la serie.'),
            trailing: DropdownButton<int?>(
              key: const Key('restDay'),
              value: s.restDay,
              items: [
                const DropdownMenuItem(child: Text('Nessuno')),
                for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                  DropdownMenuItem(value: d, child: Text(_weekdays[d - 1])),
              ],
              onChanged: (d) =>
                  controller.updateSettings(s.copyWith(restDay: () => d)),
            ),
          ),
        ],
      ],
    );
  }
}
