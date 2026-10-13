import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../l10n/app_localizations.dart';
import 'explorer_page.dart';
import 'opening_assets.dart';
import 'opening_game.dart';
import 'opening_game_dialog.dart';
import 'personal_explorer_page.dart';
import 'repertoire.dart';
import 'repertoire_page.dart';

/// Punto di ingresso delle aperture: explorer e repertori.
class OpeningsHubPage extends StatefulWidget {
  const OpeningsHubPage({
    super.key,
    required this.repertoire,
    this.onPlay,
    this.archive,
  });

  final Future<RepertoireTrainer> repertoire;

  /// Avvia una partita da un'apertura; assente senza motore.
  final PlayOpening? onPlay;

  /// Archivio delle partite, per l'albero delle proprie aperture.
  final Future<GameArchive> Function()? archive;

  @override
  State<OpeningsHubPage> createState() => _OpeningsHubPageState();
}

class _OpeningsHubPageState extends State<OpeningsHubPage> {
  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  Future<void> _playWithInstructor() async {
    final play = widget.onPlay;
    final l = AppLocalizations.of(context);
    final choice = await askOpeningGame(context, Side.white);
    if (choice == null || !mounted || play == null) return;
    await play(
      context,
      OpeningGameRequest.explorer(
        l.instructorTitle,
        const [],
        choice.side,
        levelId: choice.levelId,
        instructor: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).openingsHubTitle),
      ),
      body: FutureBuilder<RepertoireTrainer>(
        future: widget.repertoire,
        builder: (context, snapshot) {
          final trainer = snapshot.data;
          return ListView(
            children: [
              if (widget.onPlay != null)
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text(AppLocalizations.of(context).instructorTitle),
                  subtitle: Text(
                    AppLocalizations.of(context).instructorHubSubtitle,
                  ),
                  onTap: _playWithInstructor,
                ),
              ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: Text(AppLocalizations.of(context).explorerTitle),
                subtitle: Text(
                  AppLocalizations.of(context).openingsHubExplorerSubtitle,
                ),
                onTap: () => _open(
                  ExplorerPage(
                    stats: openingStatsOrNull(),
                    repertoire: trainer,
                    onPlay: widget.onPlay,
                    archive: widget.archive,
                  ),
                ),
              ),
              if (widget.archive != null)
                ListTile(
                  leading: const Icon(Icons.history_edu_outlined),
                  title: Text(AppLocalizations.of(context).personalTitle),
                  subtitle: Text(
                    AppLocalizations.of(context).personalHubSubtitle,
                  ),
                  onTap: () => _open(
                    PersonalExplorerPage(
                      archive: widget.archive!(),
                      stats: openingStatsOrNull(),
                      repertoire: trainer,
                      onPlay: widget.onPlay,
                    ),
                  ),
                ),
              const Divider(),
              for (final side in Side.values)
                ListTile(
                  leading: Icon(
                    side == Side.white ? Icons.circle_outlined : Icons.circle,
                  ),
                  title: Text(
                    AppLocalizations.of(context)
                        .openingsRepertoireTitle(side.name),
                  ),
                  subtitle: Text(
                    snapshot.hasError
                        ? AppLocalizations.of(context)
                              .openingsRepertoireUnavailable
                        : trainer == null
                        ? AppLocalizations.of(context).openingsRepertoireLoading
                        : AppLocalizations.of(context)
                              .openingsRepertoireSummary(
                                trainer.lines(side).length,
                                trainer.dueCount(side),
                              ),
                  ),
                  enabled: trainer != null,
                  onTap: () => _open(
                    RepertoirePage(
                      trainer: trainer!,
                      side: side,
                      onPlay: widget.onPlay,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
