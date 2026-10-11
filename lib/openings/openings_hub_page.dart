import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'explorer_page.dart';
import 'repertoire.dart';
import 'repertoire_page.dart';

/// Punto di ingresso delle aperture: explorer e repertori.
class OpeningsHubPage extends StatefulWidget {
  const OpeningsHubPage({super.key, required this.repertoire});

  final Future<RepertoireTrainer> repertoire;

  @override
  State<OpeningsHubPage> createState() => _OpeningsHubPageState();
}

class _OpeningsHubPageState extends State<OpeningsHubPage> {
  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aperture')),
      body: FutureBuilder<RepertoireTrainer>(
        future: widget.repertoire,
        builder: (context, snapshot) {
          final trainer = snapshot.data;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: const Text('Explorer'),
                subtitle: const Text(
                  'Nomi e continuazioni di oltre 3.000 aperture',
                ),
                onTap: () => _open(ExplorerPage(repertoire: trainer)),
              ),
              const Divider(),
              for (final side in Side.values)
                ListTile(
                  leading: Icon(
                    side == Side.white ? Icons.circle_outlined : Icons.circle,
                  ),
                  title: Text(
                    'Repertorio con il ${side == Side.white ? 'Bianco' : 'Nero'}',
                  ),
                  subtitle: Text(
                    snapshot.hasError
                        ? 'Repertorio non disponibile'
                        : trainer == null
                        ? 'Caricamento...'
                        : '${trainer.lines(side).length} linee · '
                              '${trainer.dueCount(side)} mosse da ripassare',
                  ),
                  enabled: trainer != null,
                  onTap: () =>
                      _open(RepertoirePage(trainer: trainer!, side: side)),
                ),
            ],
          );
        },
      ),
    );
  }
}
