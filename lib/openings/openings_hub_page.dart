import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'explorer_page.dart';
import 'opening_game.dart';
import 'openings_l10n.dart';
import 'repertoire.dart';
import 'repertoire_page.dart';

/// Punto di ingresso delle aperture: explorer e repertori.
class OpeningsHubPage extends StatefulWidget {
  const OpeningsHubPage({super.key, required this.repertoire, this.onPlay});

  final Future<RepertoireTrainer> repertoire;

  /// Avvia una partita da un'apertura; assente senza motore.
  final PlayOpening? onPlay;

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
                  ExplorerPage(repertoire: trainer, onPlay: widget.onPlay),
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
