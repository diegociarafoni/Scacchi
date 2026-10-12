import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../archive/archive_page.dart';
import '../archive/game_archive.dart';
import '../archive/saved_game.dart';
import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../minigames/minigames_page.dart';
import '../path/curriculum.dart';
import '../path/path_controller.dart';
import '../path/path_page.dart';
import '../path/stage_page.dart';
import '../physical/physical_game_page.dart';
import '../physical/physical_l10n.dart';
import '../progress/profile_page.dart';
import '../progress/progress_controller.dart';
import '../progress/xp.dart';
import '../reminders/reminder_controller.dart';
import '../stats/portrait_page.dart';
import '../stats/stats_page.dart';
import '../story/story_l10n.dart';
import '../summary/weekly_summary_page.dart';

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
    this.storyPage,
    this.tournamentPage,
    this.endgamesPage,
    this.mastersPage,
    this.puzzlesPage,
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

  /// Percorso a storia (RG-13); senza, la voce non compare.
  final Future<Widget> Function()? storyPage;

  /// Schermata dei tornei; senza, la voce non compare (servono le partite
  /// contro il computer).
  final Future<Widget> Function()? tournamentPage;

  /// Allenatore dei finali contro il motore (RF-86); senza, la voce non
  /// compare.
  final Future<Widget> Function()? endgamesPage;

  /// Partite dei grandi maestri (RF-87); funziona senza motore.
  final Future<Widget> Function()? mastersPage;

  /// Puzzle di un tema, per il consiglio del riepilogo settimanale; senza, il
  /// pulsante dei puzzle non compare.
  final Future<Widget> Function(String theme, String title)? puzzlesPage;

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

  /// Svolge una lezione consigliata e ne salva le stelle come nel Percorso.
  Future<void> _playLesson(BuildContext context, Stage stage) async {
    try {
      final controller = await path();
      if (!context.mounted) return;
      final started = DateTime.now();
      final stars = await Navigator.of(
        context,
      ).push<int>(MaterialPageRoute(builder: (_) => StagePage(stage: stage)));
      if (stars != null && stars > 0) {
        await controller.complete(
          stage,
          stars,
          DateTime.now().difference(started),
        );
      }
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Lezione non disponibile: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('I dati salvati non si possono leggere: riprova.'),
        ),
      );
    }
  }

  Future<void> _openPuzzles(
    BuildContext context,
    String theme,
    String title,
  ) async {
    final source = puzzlesPage?.call(theme, title);
    if (source != null) await _open(context, source, (w) => w);
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
                                  '${controller.streak == 1 ? '1 giorno di fila' : '${controller.streak} giorni di fila'}'
                                  ' · ${controller.streakInfo.summary}',
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
              if (storyPage != null)
                _Entry(
                  icon: Icons.auto_stories_outlined,
                  title: storyL10n(context).storyTitle,
                  subtitle: storyL10n(context).storyEntrySubtitle,
                  onTap: () => _open(context, storyPage!(), (w) => w),
                ),
              if (endgamesPage != null)
                _Entry(
                  icon: Icons.flag_outlined,
                  title: 'Finali',
                  subtitle:
                      'Lucena, Philidor e i matti elementari contro il motore',
                  onTap: () => _open(context, endgamesPage!(), (w) => w),
                ),
              if (mastersPage != null)
                _Entry(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Grandi maestri',
                  subtitle: 'Partite celebri da sfogliare e da indovinare',
                  onTap: () => _open(context, mastersPage!(), (w) => w),
                ),
              // Classifica ed Elo dei bot: nel profilo bambino niente numeri.
              if (tournamentPage != null && !simple)
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
              _Entry(
                icon: Icons.event_note_outlined,
                title: 'Riepilogo settimanale',
                subtitle: 'Progressi, errore ricorrente e un consiglio',
                onTap: () => _open(
                  context,
                  progress(),
                  (p) => WeeklySummaryPage(
                    log: p.weekLog,
                    openLesson: _playLesson,
                    openPuzzles: puzzlesPage == null ? null : _openPuzzles,
                  ),
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
                  title: physicalL10n(context).physicalTitle,
                  subtitle: physicalL10n(context).physicalEntrySubtitle,
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
