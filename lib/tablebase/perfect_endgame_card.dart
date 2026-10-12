import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../settings/notation.dart';
import 'tablebase.dart';
import 'tablebase_service.dart';

/// Scheda «Finale perfetto»: risultato esatto e mossa migliore quando la
/// posizione ha al massimo quattro pezzi (RF-97). Non compare per le altre
/// posizioni né se la tabella non si riesce a calcolare.
class PerfectEndgameCard extends StatefulWidget {
  const PerfectEndgameCard({
    super.key,
    required this.service,
    required this.position,
    required this.notation,
    this.kid = false,
    this.onBestMove,
    this.hideMove = false,
  });

  final TablebaseService service;
  final Position position;
  final MoveNotation notation;

  /// Profilo bambino (RP-06): niente numeri, solo chi vince.
  final bool kid;

  /// Quando c'è, il pulsante della mossa perfetta la fa vedere o giocare.
  final void Function(Move move)? onBestMove;

  /// Allenamento: la mossa non si scrive, la mostra il pulsante.
  final bool hideMove;

  @override
  State<PerfectEndgameCard> createState() => _PerfectEndgameCardState();
}

class _PerfectEndgameCardState extends State<PerfectEndgameCard> {
  /// Materiali già richiesti, per non ripetere il calcolo a ogni mossa.
  final Set<String> _requested = {};
  final Set<String> _failed = {};

  @override
  void didUpdateWidget(PerfectEndgameCard old) {
    super.didUpdateWidget(old);
    if (old.service != widget.service) {
      _requested.clear();
      _failed.clear();
    }
  }

  void _prepare(Position pos, String key) {
    if (!_requested.add(key)) return;
    unawaited(
      widget.service.prepare(pos).then((ok) {
        if (!mounted) return;
        setState(() {
          if (!ok || widget.service.tablebase.probe(pos) == null) {
            _failed.add(key);
          }
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = widget.position;
    final material = Tablebase.materialOf(pos);
    if (material == null ||
        pos.isGameOver ||
        _failed.contains(material.canonical.name)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final eval = widget.service.tablebase.probe(pos);
    if (eval == null) {
      _prepare(pos, material.canonical.name);
      return _frame(
        context,
        Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.tablebaseCalculating)),
          ],
        ),
      );
    }
    final best = widget.service.tablebase.bestMove(pos);
    final summary = _summary(l10n, pos, eval);
    return _frame(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary, style: Theme.of(context).textTheme.titleSmall),
          if (best != null) ...[
            const SizedBox(height: 8),
            _bestMove(context, l10n, pos, best),
          ],
        ],
      ),
    );
  }

  String _summary(AppLocalizations l10n, Position pos, TbEvaluation eval) {
    if (eval.outcome == TbOutcome.draw) return l10n.tablebaseDraw;
    final winner = eval.outcome == TbOutcome.win ? pos.turn : pos.turn.opposite;
    if (widget.kid) {
      return winner == Side.white
          ? l10n.tablebaseWhiteWins
          : l10n.tablebaseBlackWins;
    }
    final moves = eval.mateInMoves!;
    return winner == Side.white
        ? l10n.tablebaseWhiteMates(moves)
        : l10n.tablebaseBlackMates(moves);
  }

  Widget _bestMove(
    BuildContext context,
    AppLocalizations l10n,
    Position pos,
    Move best,
  ) {
    final san = formatSan(pos.makeSan(best).$2, widget.notation);
    final onTap = widget.onBestMove;
    final label = widget.hideMove && onTap != null
        ? l10n.tablebaseShowMove
        : l10n.tablebaseBestMove(san);
    return Semantics(
      button: onTap != null,
      label: onTap == null || widget.hideMove
          ? label
          : '$label. ${l10n.tablebaseBestMoveHint}',
      excludeSemantics: true,
      child: ActionChip(
        label: Text(label),
        onPressed: onTap == null ? null : () => onTap(best),
      ),
    );
  }

  Widget _frame(BuildContext context, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.tablebaseTitle,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tablebaseTitle,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
