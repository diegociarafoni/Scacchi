import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../minigames/minigame.dart';
import '../reminders/reminder_controller.dart';
import '../settings/settings.dart';
import 'achievements.dart';
import 'avatar.dart';
import 'avatar_art.dart';
import 'avatar_photo.dart';
import 'challenges.dart';
import 'daily_goal.dart';
import 'progress_controller.dart';
import 'progress_state.dart';
import 'records.dart';
import 'rewards.dart';
import 'xp.dart';

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
  const ProfilePage({
    super.key,
    required this.controller,
    this.reminders,
    this.photoPicker = const SystemPhotoPicker(),
  });

  final ProgressController controller;

  /// Origine della foto del profilo (RP-09); nei test se ne passa uno finto.
  final PhotoPicker photoPicker;

  /// Promemoria giornaliero; senza, l'opzione non compare (per esempio su
  /// desktop, dove le notifiche programmate non sono disponibili).
  final ReminderController? reminders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final enabled = controller.settings.enabled;
          // Profilo bambino (RP-06): stelle e fiamme al posto di XP e giorni,
          // niente record personali, che sono tutti numeri.
          final kid = AppSettings.of(context).kidMode;
          return ListView(
            // In fondo spazio per la barra di sistema: l'ultima voce non resta
            // tagliata né sotto i gesti.
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              if (enabled) ...[
                _LevelCard(
                  controller: controller,
                  kid: kid,
                  photoPicker: photoPicker,
                ),
                const SizedBox(height: 12),
                _StreakCard(controller: controller, kid: kid),
                const SizedBox(height: 24),
                _Challenges(controller: controller, kid: kid),
                const SizedBox(height: 24),
                if (!kid) ...[
                  _Records(controller: controller),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Traguardi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _Achievements(unlocked: controller.state.unlocked),
                const SizedBox(height: 24),
              ],
              // Interruttore degli XP, obiettivo e promemoria sono scelte
              // per gli adulti, piene di numeri: nel profilo bambino no.
              if (!kid) _Settings(controller: controller, reminders: reminders),
            ],
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.controller,
    required this.kid,
    required this.photoPicker,
  });

  final ProgressController controller;
  final bool kid;
  final PhotoPicker photoPicker;

  @override
  Widget build(BuildContext context) {
    final xp = controller.state.xp;
    final level = levelForXp(xp);
    final next = xpForLevel(level + 1);
    final settings = controller.settings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Tooltip(
                  message: 'Cambia avatar e cornice',
                  child: InkWell(
                    key: const Key('avatar'),
                    customBorder: const CircleBorder(),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (_) => _AvatarPicker(
                        controller: controller,
                        photoPicker: photoPicker,
                      ),
                    ),
                    child: ProfileAvatar(
                      avatar: settings.avatar,
                      frame: settings.frame,
                      // Profilo bambino: niente foto (RP-09).
                      photo: kid ? null : controller.activePhoto,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: kid
                      ? _KidStars(level: level)
                      : Text(
                          'Livello $level',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: levelProgress(xp),
              minHeight: 8,
              semanticsLabel: kid
                  ? AppLocalizations.of(context).kidLevelProgressLabel
                  : 'Avanzamento del livello: $xp su $next XP',
            ),
            const SizedBox(height: 4),
            Text(
              kid
                  ? AppLocalizations.of(context).kidLevelProgress
                  : '$xp / $next XP',
            ),
          ],
        ),
      ),
    );
  }
}

/// Livello del profilo bambino: una stella per livello (fino a
/// [kidMaxStars]), senza il numero.
class _KidStars extends StatelessWidget {
  const _KidStars({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.kidLevelTitle, style: Theme.of(context).textTheme.titleLarge),
        KidStars(
          key: const Key('kid-level-stars'),
          count: level,
          label: l.kidLevelStarsLabel,
        ),
      ],
    );
  }
}

/// Avatar del profilo con la sua cornice.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.avatar,
    required this.frame,
    this.size = 56,
    this.photo,
  });

  final Avatar avatar;
  final AvatarFrame frame;
  final double size;

  /// Foto propria: prende il posto dell'avatar, dentro la stessa cornice.
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = this.photo;
    final name = photo != null
        ? AppLocalizations.of(context).avatarPhotoLabel
        : avatar.label;
    return Semantics(
      label: frame.color == null
          ? 'Avatar: $name'
          : 'Avatar: $name, cornice ${frame.label}',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.secondaryContainer,
          border: Border.all(
            color: frame.color ?? scheme.outlineVariant,
            width: frame.color == null ? 1 : size / 12,
          ),
        ),
        child: photo != null
            ? Image.memory(
                photo,
                key: const Key('avatar-photo'),
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const Icon(Icons.person),
              )
            : avatar.character != null
            ? CharacterAvatar(character: avatar.character!, size: size)
            : Text(
                avatar.glyph!,
                style: TextStyle(
                  fontSize: size * 0.5,
                  height: 1,
                  color: scheme.onSecondaryContainer,
                ),
              ),
      ),
    );
  }
}

/// Scelta di avatar e cornice; quelli ancora bloccati dicono come sbloccarli.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.controller, required this.photoPicker});

  final ProgressController controller;
  final PhotoPicker photoPicker;

  Future<void> _pick(BuildContext context, PhotoSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).avatarPhotoError;
    try {
      final bytes = await photoPicker.pick(source);
      if (bytes != null) await controller.setPhoto(bytes);
    } on PhotoUnavailable {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Foto propria (RP-09): galleria o fotocamera, solo sul telefono.
  List<Widget> _photoSection(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [
      const SizedBox(height: 16),
      Text(l.avatarPhotoTitle, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(l.avatarPhotoHint, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: const Key('photo-gallery'),
            onPressed: () => _pick(context, PhotoSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l.avatarPhotoGallery),
          ),
          OutlinedButton.icon(
            key: const Key('photo-camera'),
            onPressed: () => _pick(context, PhotoSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l.avatarPhotoCamera),
          ),
          if (controller.photo != null)
            TextButton.icon(
              key: const Key('photo-remove'),
              onPressed: controller.removePhoto,
              icon: const Icon(Icons.delete_outline),
              label: Text(l.avatarPhotoRemove),
            ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.settings;
        final kid = AppSettings.of(context).kidMode;
        Widget option<T extends Enum>(
          T item,
          String label,
          bool selected,
          Widget preview,
          ProgressSettings Function() change,
        ) {
          final unlocked = isUnlocked(item, controller.state, s);
          final requirement = unlocked
              ? null
              : kid
              ? kidRequirement(AppLocalizations.of(context))
              : requirementOf(item)!.label;
          return Semantics(
            button: true,
            selected: selected,
            label: requirement == null
                ? label
                : kid
                ? '$label, ${requirement.toLowerCase()}'
                : '$label, si sblocca con: $requirement',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: unlocked
                  ? () => controller.updateSettings(change())
                  : null,
              child: Container(
                width: 88,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Opacity(
                  opacity: unlocked ? 1 : 0.45,
                  child: Column(
                    children: [
                      preview,
                      const SizedBox(height: 4),
                      Text(label, textAlign: TextAlign.center),
                      if (requirement != null)
                        Text(
                          requirement,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Avatar', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in Avatar.values)
                      option(
                        a,
                        a.label,
                        a == s.avatar && !s.usePhoto,
                        ProfileAvatar(avatar: a, frame: s.frame, size: 48),
                        () => s.copyWith(avatar: a, usePhoto: false),
                      ),
                  ],
                ),
                if (!kid) ..._photoSection(context),
                const SizedBox(height: 16),
                Text('Cornice', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in AvatarFrame.values)
                      option(
                        f,
                        f.label,
                        f == s.frame,
                        ProfileAvatar(avatar: s.avatar, frame: f, size: 48),
                        () => s.copyWith(frame: f),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.controller, required this.kid});

  final ProgressController controller;
  final bool kid;

  @override
  Widget build(BuildContext context) {
    if (kid) return _kid(context);
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
            const SizedBox(height: 12),
            for (final line in controller.streakInfo.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line),
              ),
          ],
        ),
      ),
    );
  }

  /// Serie e obiettivo senza cifre: fiamma accesa o spenta, barra senza conteggi.
  Widget _kid(BuildContext context) {
    final l = AppLocalizations.of(context);
    final goal = controller.settings.goal;
    final progress = controller.todayProgress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KidFlame(
              key: const Key('kid-streak'),
              lit: controller.streak > 0,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (progress / goal.target).clamp(0, 1).toDouble(),
              minHeight: 8,
              semanticsLabel: l.kidGoalToday,
            ),
            const SizedBox(height: 4),
            Text(progress >= goal.target ? l.kidProgressGoal : l.kidGoalToday),
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
  const _Settings({required this.controller, this.reminders});

  final ProgressController controller;
  final ReminderController? reminders;

  Future<void> _pickReminder(BuildContext context, int? current) async {
    final reminders = this.reminders!;
    final minutes = current ?? 19 * 60;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: 'Orario del promemoria',
      cancelText: 'Annulla',
      confirmText: 'Conferma',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    if (await reminders.enable(time.hour * 60 + time.minute)) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Senza il permesso per le notifiche il promemoria resta spento.',
          ),
        ),
      );
    }
    // Permesso revocato dopo l'attivazione: il promemoria si spegne davvero.
    await reminders.disable();
  }

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
          SwitchListTile(
            title: const Text(unlockAllTitle),
            subtitle: const Text(unlockAllSubtitle),
            value: s.unlockAll,
            onChanged: (v) =>
                controller.updateSettings(s.copyWith(unlockAll: v)),
          ),
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
                if (g != null) {
                  unawaited(controller.updateSettings(s.copyWith(goal: g)));
                }
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
          if (reminders case final reminders?) ...[
            SwitchListTile(
              key: const Key('reminder'),
              title: const Text('Promemoria giornaliero'),
              subtitle: const Text(
                "Una notifica al giorno, solo se l'obiettivo manca.",
              ),
              value: s.reminder != null,
              onChanged: (on) =>
                  on ? _pickReminder(context, s.reminder) : reminders.disable(),
            ),
            if (s.reminder case final minutes?)
              ListTile(
                key: const Key('reminderTime'),
                title: const Text('Orario del promemoria'),
                trailing: Text(_clock(minutes)),
                onTap: () => _pickReminder(context, minutes),
              ),
          ],
        ],
      ],
    );
  }
}

class _Challenges extends StatelessWidget {
  const _Challenges({required this.controller, required this.kid});

  final ProgressController controller;
  final bool kid;

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleLarge;
    final (weekly, weeklyProgress) = controller.weeklyChallenge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sfide di oggi', style: title),
        for (final (c, p) in controller.challenges) _ChallengeTile(c, p, kid),
        const SizedBox(height: 12),
        Text('Sfida della settimana', style: title),
        _ChallengeTile(weekly, weeklyProgress, kid),
      ],
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile(this.challenge, this.progress, this.kid);

  final Challenge challenge;
  final int progress;

  /// Nel profilo bambino il titolo resta (è il compito), il conteggio no.
  final bool kid;

  @override
  Widget build(BuildContext context) {
    final done = progress >= challenge.target;
    final shown = progress.clamp(0, challenge.target);
    final scheme = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? scheme.primary : scheme.outline,
          semanticLabel: done ? 'Completata' : 'Da completare',
        ),
        title: Text(challenge.title),
        subtitle: LinearProgressIndicator(
          value: shown / challenge.target,
          semanticsLabel: kid
              ? AppLocalizations.of(context).kidChallengeProgress
              : '$shown su ${challenge.target}',
        ),
        trailing: kid ? null : Text('$shown/${challenge.target}'),
      ),
    );
  }
}

class _Records extends StatelessWidget {
  const _Records({required this.controller});

  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final r = controller.state.records;
    final rows = [
      ('Serie più lunga', '${controller.state.bestStreak} giorni'),
      if (r.strongestBot != null)
        (RecordKind.strongestBot.label, '${r.strongestBot} Elo'),
      if (r.fastestWin != null)
        (RecordKind.fastestWin.label, '${r.fastestWin} mosse'),
      if (r.bestAccuracy != null)
        (
          RecordKind.bestAccuracy.label,
          '${r.bestAccuracy!.toStringAsFixed(1)}%',
        ),
      if (r.puzzleRating != null)
        (RecordKind.puzzleRating.label, '${r.puzzleRating}'),
      for (final e in r.puzzleRuns.entries)
        ('${RecordKind.puzzleRun.label} (${e.key})', '${e.value}'),
      for (final e in r.minigames.entries)
        (Minigame.byId(e.key)?.title ?? e.key, '${e.value}'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Record personali', style: Theme.of(context).textTheme.titleLarge),
        for (final (label, value) in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            trailing: Text(value),
          ),
      ],
    );
  }
}

String _clock(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';
