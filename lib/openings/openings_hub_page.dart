import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../l10n/app_localizations.dart';
import 'explorer_page.dart';
import 'opening_game.dart';
import 'openings_l10n.dart';
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

  @override
  Widget build(BuildContext context) {
    final l = openingsL10n(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.openingsTitle)),
      body: FutureBuilder<RepertoireTrainer>(
        future: widget.repertoire,
        builder: (context, snapshot) {
          final trainer = snapshot.data;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: Text(l.openingsExplorer),
                subtitle: Text(l.openingsExplorerSubtitle),
                onTap: () => _open(
                  ExplorerPage(
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
                    side == Side.white
                        ? l.openingsRepertoireWhite
                        : l.openingsRepertoireBlack,
                  ),
                  subtitle: Text(
                    snapshot.hasError
                        ? l.openingsRepertoireUnavailable
                        : trainer == null
                        ? l.openingsLoading
                        : l.openingsRepertoireSummary(
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
