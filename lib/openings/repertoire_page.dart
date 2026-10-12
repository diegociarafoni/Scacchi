import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../settings/notation.dart';
import '../settings/settings.dart';
import 'opening_game.dart';
import 'opening_game_dialog.dart';
import 'repertoire.dart';
import 'repertoire_drill_page.dart';

/// Linee del repertorio di un colore, con importazione PGN e ripasso.
class RepertoirePage extends StatefulWidget {
  const RepertoirePage({
    super.key,
    required this.trainer,
    required this.side,
    this.onPlay,
  });

  final RepertoireTrainer trainer;
  final Side side;

  /// Avvia una partita lungo la linea; assente senza motore.
  final PlayOpening? onPlay;

  @override
  State<RepertoirePage> createState() => _RepertoirePageState();
}

class _RepertoirePageState extends State<RepertoirePage> {
  RepertoireTrainer get _t => widget.trainer;
  String get _color => widget.side == Side.white ? 'Bianco' : 'Nero';

  Future<void> _importPgn() async {
    // Niente dispose: il dialogo lo usa ancora durante l'animazione di uscita.
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importa PGN'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '1. e4 e5 2. Nf3 Nc6 (2... d6 3. d4) 3. Bc4',
            helperText: 'Ogni variante diventa una linea.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Importa'),
          ),
        ],
      ),
    );
    if (text == null || !mounted) return;
    final lines = linesFromPgn(text);
    final notation = AppSettings.of(context).notation;
    var added = 0;
    final errors = <String>[];
    for (final (i, moves) in lines.indexed) {
      final error = await _t.addLine(
        widget.side,
        'PGN ${i + 1}',
        moves,
        notation: notation,
      );
      error == null ? added++ : errors.add(error);
    }
    if (!mounted) return;
    setState(() {});
    final message = lines.isEmpty
        ? 'Nessuna linea valida nel PGN.'
        : 'Linee aggiunte: $added'
              '${errors.isEmpty ? '' : '. Scartate: ${errors.length} (${errors.first})'}';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _play(RepertoireLine line) async {
    final choice = await askOpeningGame(context, widget.side, lockSide: true);
    if (choice == null || !mounted) return;
    await widget.onPlay!(
      context,
      OpeningGameRequest.repertoire(
        line.name,
        line.moves,
        widget.side,
        levelId: choice.levelId,
      ),
    );
  }

  Future<void> _drill() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RepertoireDrillPage(trainer: _t, side: widget.side),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lines = _t.lines(widget.side);
    final due = _t.dueCount(widget.side);
    return Scaffold(
      appBar: AppBar(
        title: Text('Repertorio con il $_color'),
        actions: [
          IconButton(
            tooltip: 'Importa PGN',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _importPgn,
          ),
        ],
      ),
      body: lines.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nessuna linea. Aggiungile da Esplora aperture con il pulsante '
                  '"Aggiungi al repertorio" o importa un PGN.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: lines.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(lines[i].name),
                subtitle: Text(
                  formatMoveText(
                    lines[i].san,
                    AppSettings.of(context).notation,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onPlay != null)
                      IconButton(
                        tooltip: 'Gioca la linea',
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _play(lines[i]),
                      ),
                    IconButton(
                      tooltip: 'Elimina la linea',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await _t.removeLine(widget.side, i);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: due == 0 ? null : _drill,
            icon: const Icon(Icons.school_outlined),
            label: Text(
              due == 0 ? 'Nessuna mossa da ripassare' : 'Ripassa $due mosse',
            ),
          ),
        ),
      ),
    );
  }
}
