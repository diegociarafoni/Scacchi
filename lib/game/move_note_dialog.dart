import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'move_note.dart';

/// Chiede simbolo e commento della mossa [san]; restituisce la nota (anche
/// vuota, per toglierla) o `null` se si annulla.
Future<MoveNote?> showMoveNoteDialog(
  BuildContext context, {
  required String san,
  required MoveNote? note,
}) => showDialog<MoveNote>(
  context: context,
  builder: (_) => MoveNoteDialog(san: san, note: note),
);

/// Scelta di simbolo e commento personali per una mossa (RF-55). Restituisce
/// la nota (anche vuota, per toglierla) o niente se si annulla.
class MoveNoteDialog extends StatefulWidget {
  const MoveNoteDialog({super.key, required this.san, required this.note});

  final String san;
  final MoveNote? note;

  @override
  State<MoveNoteDialog> createState() => _MoveNoteDialogState();
}

class _MoveNoteDialogState extends State<MoveNoteDialog> {
  late MoveSymbol? _symbol = widget.note?.symbol;
  late final TextEditingController _comment = TextEditingController(
    text: widget.note?.comment,
  );

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.reviewNoteTitle(widget.san)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final symbol in MoveSymbol.values)
                  ChoiceChip(
                    label: Text(symbol.text),
                    selected: _symbol == symbol,
                    onSelected: (on) =>
                        setState(() => _symbol = on ? symbol : null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              decoration: InputDecoration(labelText: l.reviewNoteComment),
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.reviewNoteCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            MoveNote.of(symbol: _symbol, comment: _comment.text),
          ),
          child: Text(l.reviewNoteSave),
        ),
      ],
    );
  }
}
