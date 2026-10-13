import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/levels.dart';
import '../l10n/app_localizations.dart';

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
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.openingsGameTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<Side>(
                segments: [
                  ButtonSegment(
                    value: Side.white,
                    label: Text(l10n.openingsSideWhite),
                  ),
                  ButtonSegment(
                    value: Side.black,
                    label: Text(l10n.openingsSideBlack),
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
                decoration: InputDecoration(labelText: l10n.openingsLevel),
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
              child: Text(l10n.openingsCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, OpeningGameChoice(side, level)),
              child: Text(l10n.openingsPlay),
            ),
          ],
        );
      },
    ),
  );
}
