import 'dart:async';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../archive/saved_game.dart';
import '../game/chess_game.dart';
import '../l10n/app_localizations.dart';
import '../settings/notation.dart';
import '../settings/settings.dart';
import '../training/training_board.dart';
import 'explorer_page.dart';
import 'opening_assets.dart';
import 'opening_book.dart';
import 'opening_game.dart';
import 'openings_l10n.dart';
import 'personal_tree.dart';
import 'repertoire.dart';

/// Albero delle aperture dalle partite dell'utente: per ogni mossa quante
/// volte l'ha giocata e con quali risultati (RF-96).
class PersonalExplorerPage extends StatefulWidget {
  const PersonalExplorerPage({
    super.key,
    required this.archive,
    this.book,
    this.initialMoves = const [],
    this.repertoire,
    this.onPlay,
  });

  final Future<GameArchive> archive;

  /// Sostituibile nei test; di default il libro incluso nell'app.
  final Future<OpeningBook>? book;
  final List<Move> initialMoves;

  /// Passati all'explorer delle aperture quando lo si apre da qui.
  final RepertoireTrainer? repertoire;
  final PlayOpening? onPlay;

  @override
  State<PersonalExplorerPage> createState() => _PersonalExplorerPageState();
}

class _PersonalExplorerPageState extends State<PersonalExplorerPage> {
  late final Future<OpeningBook> _book = widget.book ?? openingBook();
  final List<Move> _moves = [];
  late List<Position> _positions;
  Side _orientation = Side.white;
  Side? _side;
  String? _opponent;
  PersonalOpeningTree? _tree;
  PersonalGames? _games;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _positions = OpeningBook.replay(widget.initialMoves);
    _moves.addAll(widget.initialMoves.take(_positions.length - 1));
    unawaited(_load());
  }

  Future<void> _load() async {
    final List<SavedGame> games;
    try {
      games = await (await widget.archive).list();
    } on Object {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    setState(() {
      _games = PersonalGames.from(games);
      _refilter();
    });
  }

  /// Ricalcola l'albero con i filtri correnti.
  void _refilter() {
    _tree = _games!.tree(side: _side, opponent: _opponent);
  }

  void _play(Move move) {
    final pos = _positions.last;
    if (!isPlayableMove(pos, move)) return;
    setState(() {
      _moves.add(move);
      _positions = [..._positions, pos.play(move)];
    });
  }

  void _back() => setState(() {
    _moves.removeLast();
    _positions = _positions.sublist(0, _positions.length - 1);
  });

  void _reset() => setState(() {
    _moves.clear();
    _positions = [_positions.first];
  });

  void _setSide(Side? side) {
    setState(() {
      _side = side;
      if (side != null) _orientation = side;
      _refilter();
    });
  }

  void _setOpponent(String? opponent) {
    setState(() {
      _opponent = opponent;
      _refilter();
    });
  }

  void _openBook() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ExplorerPage(
          book: _book,
          initialMoves: [..._moves],
          repertoire: widget.repertoire,
          onPlay: widget.onPlay,
          archive: () => widget.archive,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.personalTitle),
        actions: [
          IconButton(
            tooltip: l10n.personalOpenInBook,
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: _openBook,
          ),
          IconButton(
            tooltip: l10n.personalFlip,
            icon: const Icon(Icons.swap_vert),
            onPressed: () =>
                setState(() => _orientation = _orientation.opposite),
          ),
        ],
      ),
      body: SafeArea(
        child: _failed
            ? _Message(l10n.personalLoadFailed)
            : _tree == null
            ? const Center(child: CircularProgressIndicator())
            : _content(context, l10n),
      ),
    );
  }

  Widget _content(BuildContext context, AppLocalizations l10n) {
    final tree = _tree!;
    final text = Theme.of(context).textTheme;
    final notation = AppSettings.of(context).notation;
    if (_games!.isEmpty) return _Message(l10n.personalEmpty);
    final next = tree.continuationsAt(_positions.last);
    return LayoutBuilder(
      builder: (context, c) {
        final size = math.min(c.maxWidth, c.maxHeight * 0.45);
        return Column(
          children: [
            _Filters(
              side: _side,
              opponent: _opponent,
              opponents: _games!.opponents,
              onSide: _setSide,
              onOpponent: _setOpponent,
            ),
            FutureBuilder<OpeningBook>(
              future: _book,
              builder: (context, snapshot) {
                final opening = snapshot.data?.classifyPositions(_positions);
                return ListTile(
                  dense: true,
                  title: Text(
                    opening != null
                        ? '${opening.eco} ${openingDisplayName(l10n, opening)}'
                        : _moves.isEmpty
                        ? l10n.personalStartPosition
                        : l10n.personalNoName,
                    key: const Key('personal-opening'),
                    style: text.titleMedium,
                  ),
                  subtitle: Text(_moveText(notation)),
                  trailing: Text(l10n.personalGamesTotal(tree.games)),
                );
              },
            ),
            TrainingBoard(
              size: size,
              position: _positions.last,
              lastMove: _moves.isEmpty ? null : _moves.last,
              player: _positions.last.turn,
              orientation: _orientation,
              onMove: _play,
            ),
            Expanded(
              child: next.isEmpty
                  ? _Message(
                      tree.games == 0
                          ? l10n.personalNoGamesFiltered
                          : l10n.personalNoGamesHere,
                    )
                  : ListView(
                      children: [
                        for (final m in next)
                          _MoveTile(
                            move: m,
                            notation: notation,
                            onTap: () => _play(m.move),
                          ),
                      ],
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _moves.isEmpty ? null : _back,
                    icon: const Icon(Icons.undo),
                    label: Text(l10n.personalBack),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _moves.isEmpty ? null : _reset,
                    icon: const Icon(Icons.first_page),
                    label: Text(l10n.personalStart),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _moveText(MoveNotation notation) {
    final parts = <String>[];
    for (var i = 0; i < _moves.length; i++) {
      final san = _positions[i].makeSan(_moves[i]).$2;
      final shown = formatSan(san, notation);
      parts.add(i.isEven ? '${i ~/ 2 + 1}. $shown' : shown);
    }
    return parts.join(' ');
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.side,
    required this.opponent,
    required this.opponents,
    required this.onSide,
    required this.onOpponent,
  });

  final Side? side;
  final String? opponent;
  final List<String> opponents;
  final ValueChanged<Side?> onSide;
  final ValueChanged<String?> onOpponent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<Side?>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: null, label: Text(l10n.personalSideAll)),
                ButtonSegment(
                  value: Side.white,
                  label: Text(l10n.personalSideWhite),
                ),
                ButtonSegment(
                  value: Side.black,
                  label: Text(l10n.personalSideBlack),
                ),
              ],
              selected: {side},
              onSelectionChanged: (s) => onSide(s.first),
            ),
          ),
          DropdownButton<String?>(
            key: const Key('personal-opponent'),
            isExpanded: true,
            value: opponent,
            hint: Text(l10n.personalOpponent),
            items: [
              DropdownMenuItem(child: Text(l10n.personalAllOpponents)),
              for (final o in opponents)
                DropdownMenuItem(
                  value: o,
                  child: Text(o, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onOpponent,
          ),
        ],
      ),
    );
  }
}

class _MoveTile extends StatelessWidget {
  const _MoveTile({
    required this.move,
    required this.notation,
    required this.onTap,
  });

  final PersonalMove move;
  final MoveNotation notation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: SizedBox(
        width: 56,
        child: Text(formatSan(move.san, notation), style: text.titleMedium),
      ),
      title: Text(l10n.personalGames(move.games)),
      subtitle: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (move.wins > 0)
                    Expanded(
                      flex: move.wins,
                      child: ColoredBox(color: scheme.primary),
                    ),
                  if (move.draws > 0)
                    Expanded(
                      flex: move.draws,
                      child: ColoredBox(color: scheme.outline),
                    ),
                  if (move.losses > 0)
                    Expanded(
                      flex: move.losses,
                      child: ColoredBox(color: scheme.error),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      trailing: Semantics(
        label: l10n.personalScoreSemantics(move.wins, move.draws, move.losses),
        excludeSemantics: true,
        child: Text(
          l10n.personalScore(move.wins, move.draws, move.losses),
          style: text.bodyMedium,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );
}
