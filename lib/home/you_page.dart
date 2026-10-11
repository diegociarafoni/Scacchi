import 'package:flutter/material.dart';

import '../archive/archive_page.dart';
import '../archive/game_archive.dart';
import '../minigames/minigames_page.dart';
import '../path/path_controller.dart';
import '../path/path_page.dart';
import '../progress/activity.dart';
import '../progress/profile_page.dart';
import '../progress/progress_controller.dart';
import '../progress/xp.dart';
import '../reminders/reminder_controller.dart';
import '../stats/stats_page.dart';

/// Scheda "Tu": profilo e tutto ciò che riguarda i propri progressi.
class YouPage extends StatelessWidget {
  const YouPage({
    super.key,
    required this.progress,
    required this.archive,
    required this.recordActivity,
    this.reminders,
  });

  final Future<ProgressController> progress;
  final Future<GameArchive> Function() archive;
  final RecordActivity recordActivity;

  /// Promemoria giornaliero, se il dispositivo ha le notifiche programmate.
  final ReminderController? reminders;

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  /// Apre [page] quando [source] è pronto, con un messaggio se non lo è.
  Future<void> _open<T>(
    BuildContext context,
    Future<T> source,
    Widget Function(T value) page,
  ) async {
    try {
      final value = await source;
      if (context.mounted) _push(context, page(value));
    } on Object catch (e) {
      debugPrint('Sezione non disponibile: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('I dati salvati non si possono leggere: riprova.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu')),
      body: FutureBuilder(
        future: progress,
        builder: (context, snapshot) {
          final controller = snapshot.data;
          return ListView(
            children: [
              if (controller != null)
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => controller.settings.enabled
                      ? ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: ProfileAvatar(
                            avatar: controller.settings.avatar,
                            frame: controller.settings.frame,
                            size: 48,
                          ),
                          title: Text(
                            'Livello ${levelForXp(controller.state.xp)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subtitle: Text(
                            controller.streak == 1
                                ? '1 giorno di fila'
                                : '${controller.streak} giorni di fila',
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              _Entry(
                icon: Icons.person_outline,
                title: 'Profilo',
                subtitle: 'Livello, serie, sfide, traguardi e preferenze',
                onTap: () => _open(
                  context,
                  progress,
                  (p) => ProfilePage(controller: p, reminders: reminders),
                ),
              ),
              _Entry(
                icon: Icons.route_outlined,
                title: 'Percorso',
                subtitle: 'Tappe con stelle, dalle basi al finale',
                onTap: () => _open(
                  context,
                  PathController.open(recordActivity: recordActivity),
                  (c) => PathPage(controller: c),
                ),
              ),
              _Entry(
                icon: Icons.videogame_asset_outlined,
                title: 'Minigiochi',
                subtitle: 'Coordinate, cattura tutto, cieca, materiale',
                onTap: () =>
                    _open(context, progress, (p) => MinigamesPage(progress: p)),
              ),
              _Entry(
                icon: Icons.insights_outlined,
                title: 'Statistiche',
                subtitle: 'Risultati, aperture, cadenze e rating locale',
                onTap: () =>
                    _open(context, archive(), (a) => StatsPage(archive: a)),
              ),
              _Entry(
                icon: Icons.inventory_2_outlined,
                title: 'Archivio',
                subtitle: 'Partite salvate, import ed export PGN',
                onTap: () =>
                    _open(context, archive(), (a) => ArchivePage(archive: a)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
