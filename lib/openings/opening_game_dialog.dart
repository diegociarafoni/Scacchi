import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/levels.dart';
import 'openings_l10n.dart';

/// Colore e livello scelti per giocare un'apertura.
class OpeningGameChoice {
  const OpeningGameChoice(this.side, this.levelId);

  final Side side;
  final int levelId;
}

/// Chiede colore e livello; `null` se si annulla. Con [lockSide] il colore è
/// quello della linea del repertorio e non si cambia.
Future<OpeningGameChoice?> askOpeningGame(
  BuildContext context,
  Side suggested, {
  bool lockSide = false,
}) {
  var side = suggested;
  var level = defaultEngineLevel;
  return showDialog<OpeningGameChoice>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialog) {
        final t = openingsL10n(context);
        return AlertDialog(
          title: Text(t.openingsPlayDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<Side>(
                segments: [
                  ButtonSegment(
                    value: Side.white,
                    label: Text(t.openingsWhite),
                  ),
                  ButtonSegment(
                    value: Side.black,
                    label: Text(t.openingsBlack),
                  ),
                ],
                selected: {side},
                onSelectionChanged: lockSide
                    ? null
                    : (s) => setDialog(() => side = s.first),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: level,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.openingsPlayLevel),
                items: [
                  for (final l in engineLevels)
                    DropdownMenuItem(
                      value: l.id,
                      child: Text('${l.name} · ${l.approxElo}'),
                    ),
                ],
                onChanged: (v) => setDialog(() => level = v ?? level),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.openingsCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, OpeningGameChoice(side, level)),
              child: Text(t.openingsPlay),
            ),
          ],
        );
      },
    ),
  );
}
