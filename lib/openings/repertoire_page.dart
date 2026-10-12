import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../settings/notation.dart';
import '../settings/settings.dart';
import 'opening_game.dart';
import 'opening_game_dialog.dart';
import 'openings_l10n.dart';
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

  Future<void> _importPgn() async {
    final l = openingsL10n(context);
    // Niente dispose: il dialogo lo usa ancora durante l'animazione di uscita.
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.openingsImportPgn),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: '1. e4 e5 2. Nf3 Nc6 (2... d6 3. d4) 3. Bc4',
            helperText: l.openingsImportHelper,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.openingsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l.openingsImport),
          ),
        ],
      ),
    );
    if (text == null || !mounted) return;
    final lines = linesFromPgn(text);
    final notation = AppSettings.of(context).notation;
    var added = 0;
    final errors = <RepertoireError>[];
    for (final (i, moves) in lines.indexed) {
      final error = await _t.addLine(
        widget.side,
        l.openingsPgnLineName(i + 1),
        moves,
        notation: notation,
      );
      error == null ? added++ : errors.add(error);
    }
    if (!mounted) return;
    setState(() {});
    final message = lines.isEmpty
        ? l.openingsNoValidLines
        : errors.isEmpty
        ? l.openingsLinesAdded(added)
        : l.openingsLinesAddedDiscarded(
            added,
            errors.length,
            repertoireErrorText(l, errors.first),
          );
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
    final l = openingsL10n(context);
    final lines = _t.lines(widget.side);
    final due = _t.dueCount(widget.side);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.side == Side.white
              ? l.openingsRepertoireWhite
              : l.openingsRepertoireBlack,
        ),
        actions: [
          IconButton(
            tooltip: l.openingsImportPgn,
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _importPgn,
          ),
        ],
      ),
      body: lines.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.openingsNoLines, textAlign: TextAlign.center),
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
                        tooltip: l.openingsPlayLine,
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _play(lines[i]),
                      ),
                    IconButton(
                      tooltip: l.openingsDeleteLine,
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
              due == 0 ? l.openingsNothingToReview : l.openingsReviewMoves(due),
            ),
          ),
        ),
      ),
    );
  }
}
