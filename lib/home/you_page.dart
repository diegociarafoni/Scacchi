import 'package:flutter/material.dart';

import '../archive/archive_page.dart';
import '../archive/game_archive.dart';
import '../archive/saved_game.dart';
import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../minigames/minigames_page.dart';
import '../path/path_controller.dart';
import '../path/path_page.dart';
import '../physical/physical_game_page.dart';
import '../progress/profile_page.dart';
import '../progress/progress_controller.dart';
import '../progress/xp.dart';
import '../reminders/reminder_controller.dart';
import '../stats/portrait_page.dart';
import '../stats/stats_page.dart';

/// Scheda "Tu": profilo e tutto ciò che riguarda i propri progressi.
class YouPage extends StatelessWidget {
  const YouPage({
    super.key,
    required this.progress,
    required this.path,
    required this.archive,
    this.reminders,
    this.simple = false,
    this.playGuardian,
    this.tournamentPage,
    this.openGame,
  });

  /// Fonti dei dati: chiamate a ogni apertura, così un errore si riprova.
  final Future<ProgressController> Function() progress;
  final Future<PathController> Function() path;
  final Future<GameArchive> Function() archive;

  /// Promemoria giornaliero, se il dispositivo ha le notifiche programmate;
  /// letto all'apertura del Profilo perché nasce dopo i progressi.
  final ReminderController? Function()? reminders;

  /// Profilo bambino (RP-06): niente statistiche, archivio e strumenti per
  /// adulti, solo profilo, percorso e minigiochi.
  final bool simple;

  /// Partita contro il guardiano; senza, le tappe guardiano mostrano un avviso.
  final PlayGuardian? playGuardian;

  /// Schermata dei tornei; senza, la voce non compare (servono le partite
  /// contro il computer).
  final Future<Widget> Function()? tournamentPage;

  /// Apre una partita dell'archivio; senza, le righe non sono toccabili.
  final void Function(BuildContext context, SavedGame game)? openGame;

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
        future: progress(),
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
                          // Profilo bambino (RP-06): stelle e fiamma come nel
                          // Profilo, senza livello né giorni in cifre.
                          title: simple
                              ? KidStars(
                                  count: levelForXp(controller.state.xp),
                                  label: AppLocalizations.of(context)
                                      .kidLevelStarsLabel,
                                )
                              : Text(
                                  'Livello ${levelForXp(controller.state.xp)}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                          subtitle: simple
                              ? KidFlame(lit: controller.streak > 0)
                              : Text(
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
                  progress(),
                  (p) =>
                      ProfilePage(controller: p, reminders: reminders?.call()),
                ),
              ),
              _Entry(
                icon: Icons.route_outlined,
                title: 'Percorso',
                subtitle: 'Tappe con stelle, dalle basi al finale',
                onTap: () => _open(
                  context,
                  path(),
                  (c) => PathPage(controller: c, playGuardian: playGuardian),
                ),
              ),
              if (tournamentPage != null)
                _Entry(
                  icon: Icons.emoji_events_outlined,
                  title: 'Tornei',
                  subtitle: 'Gironi ed eliminazione diretta contro i bot',
                  onTap: () => _open(context, tournamentPage!(), (w) => w),
                ),
              _Entry(
                icon: Icons.videogame_asset_outlined,
                title: 'Minigiochi',
                subtitle: 'Coordinate, cattura tutto, cieca, materiale',
                onTap: () => _open(
                  context,
                  progress(),
                  (p) => MinigamesPage(progress: p),
                ),
              ),
              if (!simple) ...[
                _Entry(
                  icon: Icons.insights_outlined,
                  title: 'Statistiche',
                  subtitle: 'Risultati, aperture, cadenze e rating locale',
                  onTap: () =>
                      _open(context, archive(), (a) => StatsPage(archive: a)),
                ),
                _Entry(
                  icon: Icons.auto_awesome_outlined,
                  title: 'La tua settimana',
                  subtitle:
                      'Riepilogo degli ultimi sette giorni, da condividere',
                  onTap: () => _open(
                    context,
                    archive(),
                    (a) => PortraitPage(archive: a),
                  ),
                ),
                _Entry(
                  icon: Icons.timer_outlined,
                  title: 'Scacchiera fisica',
                  subtitle: 'Orologio e registro per una partita dal vivo',
                  onTap: () =>
                      _push(context, PhysicalGamePage(archive: archive)),
                ),
                _Entry(
                  icon: Icons.inventory_2_outlined,
                  title: 'Archivio',
                  subtitle: 'Partite salvate, import ed export PGN',
                  onTap: () => _open(
                    context,
                    archive(),
                    (a) => ArchivePage(
                      archive: a,
                      onOpen: openGame == null
                          ? null
                          : (g) => openGame!(context, g),
                    ),
                  ),
                ),
              ],
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
