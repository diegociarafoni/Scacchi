import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../training/training_board.dart';
import 'guess_page.dart';
import 'master_game.dart';
import 'masters_controller.dart';

/// Una partita della raccolta (RF-87): si sfoglia mossa per mossa con il
/// commento e da qui si passa a «Indovina la mossa».
class MasterGamePage extends StatefulWidget {
  const MasterGamePage({
    super.key,
    required this.game,
    required this.controller,
    this.simple = false,
  });

  final MasterGame game;
  final MastersController controller;
  final bool simple;

  @override
  State<MasterGamePage> createState() => _MasterGamePageState();
}

class _MasterGamePageState extends State<MasterGamePage> {
  late final (List<Position>, List<Move>) _replayed = widget.game.replay();
  List<Position> get _positions => _replayed.$1;
  List<Move> get _moves => _replayed.$2;
  int _ply = 0;
  bool _flipped = false;

  void _go(int ply) =>
      setState(() => _ply = ply.clamp(0, widget.game.moves.length));

  void _guess(Side side) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GuessPage(
        game: widget.game,
        side: side,
        controller: widget.controller,
        simple: widget.simple,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final note = game.noteAt(_ply);
    // Chi ha vinto per primo: è la parte più istruttiva da indovinare.
    final sides = game.winner == Side.black
        ? [Side.black, Side.white]
        : [Side.white, Side.black];
    return Scaffold(
      appBar: AppBar(
        title: Text('${game.white} – ${game.black}'),
        actions: [
          IconButton(
            tooltip: l10n.mastersFlipBoard,
            icon: const Icon(Icons.swap_vert),
            onPressed: () => setState(() => _flipped = !_flipped),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final size = math.max(
              0.0,
              landscape
                  ? constraints.maxHeight
                  : math.min(
                      constraints.maxWidth,
                      constraints.maxHeight - _portraitReserve,
                    ),
            );
            final board = TrainingBoard(
              size: size,
              position: _positions[_ply],
              player: Side.white,
              enabled: false,
              orientation: _flipped ? Side.black : Side.white,
              lastMove: _ply == 0 ? null : _moves[_ply - 1],
              onMove: (_) {},
            );
            final panel = SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _ply == 0 ? l10n.mastersStartPosition : game.label(_ply),
                    key: const Key('master-ply'),
                    style: text.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  if (_ply == 0) ...[
                    Text(
                      [
                        if (game.nickname != null) game.nickname!,
                        '${game.event}, ${game.year}',
                        _resultText(l10n, game),
                      ].join(' · '),
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(game.intro),
                  ] else if (note != null)
                    Text(note),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        key: const Key('master-first'),
                        tooltip: l10n.mastersFirstMove,
                        icon: const Icon(Icons.first_page),
                        onPressed: _ply > 0 ? () => _go(0) : null,
                      ),
                      IconButton(
                        key: const Key('master-prev'),
                        tooltip: l10n.mastersPreviousMove,
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _ply > 0 ? () => _go(_ply - 1) : null,
                      ),
                      IconButton(
                        key: const Key('master-next'),
                        tooltip: l10n.mastersNextMove,
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _ply < game.moves.length
                            ? () => _go(_ply + 1)
                            : null,
                      ),
                      IconButton(
                        key: const Key('master-last'),
                        tooltip: l10n.mastersLastMove,
                        icon: const Icon(Icons.last_page),
                        onPressed: _ply < game.moves.length
                            ? () => _go(game.moves.length)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final side in sides)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton.tonal(
                        onPressed: () => _guess(side),
                        child: Text(
                          side == Side.white
                              ? l10n.mastersGuessWhite
                              : l10n.mastersGuessBlack,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var i = 1; i <= game.moves.length; i++)
                        ChoiceChip(
                          label: Text(game.label(i)),
                          selected: i == _ply,
                          onSelected: (_) => _go(i),
                        ),
                    ],
                  ),
                ],
              ),
            );
            if (landscape) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  board,
                  Expanded(child: panel),
                ],
              );
            }
            return Column(
              children: [
                Center(child: board),
                Expanded(child: panel),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _resultText(AppLocalizations l10n, MasterGame game) =>
      switch (game.winner) {
        Side.white => l10n.mastersWhiteWins,
        Side.black => l10n.mastersBlackWins,
        null => l10n.mastersDraw,
      };
}

/// Spazio minimo sotto la scacchiera in verticale per testo e comandi.
const double _portraitReserve = 240;
