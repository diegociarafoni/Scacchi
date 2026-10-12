import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../game/chess_game.dart';
import '../l10n/app_localizations.dart';
import '../settings/notation.dart';
import '../settings/settings.dart';
import '../training/training_board.dart';
import 'opening_assets.dart';
import 'opening_book.dart';
import 'opening_game.dart';
import 'opening_game_dialog.dart';
import 'openings_l10n.dart';
import 'personal_explorer_page.dart';
import 'repertoire.dart';

/// Esplora aperture: continuazioni del libro dalla posizione corrente (RF-92).
class ExplorerPage extends StatefulWidget {
  const ExplorerPage({
    super.key,
    this.book,
    this.initialMoves = const [],
    this.repertoire,
    this.onPlay,
    this.archive,
  });

  /// Sostituibile nei test; di default il libro incluso nell'app.
  final Future<OpeningBook>? book;
  final List<Move> initialMoves;

  /// Se presente, la linea corrente si può aggiungere al repertorio.
  final RepertoireTrainer? repertoire;

  /// Avvia la partita dall'apertura raggiunta; assente senza motore.
  final PlayOpening? onPlay;

  /// Se presente, si apre l'albero delle proprie partite dalla stessa posizione.
  final Future<GameArchive> Function()? archive;

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  late final Future<OpeningBook> _book = widget.book ?? openingBook();
  final List<Move> _moves = [];
  late List<Position> _positions;
  Side _orientation = Side.white;

  @override
  void initState() {
    super.initState();
    // Solo la parte legale delle mosse iniziali.
    _positions = OpeningBook.replay(widget.initialMoves);
    _moves.addAll(widget.initialMoves.take(_positions.length - 1));
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

  @override
  Widget build(BuildContext context) {
    final positions = _positions;
    final text = Theme.of(context).textTheme;
    final notation = AppSettings.of(context).notation;
    final l = openingsL10n(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.openingsExplorer),
        actions: [
          if (widget.archive != null)
            IconButton(
              tooltip: AppLocalizations.of(context).personalFromHere,
              icon: const Icon(Icons.history_edu_outlined),
              onPressed: _openPersonal,
            ),
          if (widget.repertoire != null)
            IconButton(
              tooltip: l.openingsAddToRepertoire,
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: _moves.isEmpty ? null : _addToRepertoire,
            ),
          if (widget.onPlay != null)
            IconButton(
              tooltip: l.openingsPlayOpening,
              icon: const Icon(Icons.play_arrow),
              onPressed: _moves.isEmpty || positions.last.isGameOver
                  ? null
                  : _playOpening,
            ),
          IconButton(
            tooltip: l.openingsFlipBoard,
            icon: const Icon(Icons.swap_vert),
            onPressed: () =>
                setState(() => _orientation = _orientation.opposite),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<OpeningBook>(
          future: _book,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(l.openingsLoadFailed));
            }
            final book = snapshot.data;
            if (book == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final opening = book.classifyPositions(positions);
            final next = book.continuationsAt(positions.last);
            return LayoutBuilder(
              builder: (context, c) {
                final size = math.min(c.maxWidth, c.maxHeight * 0.55);
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        opening != null
                            ? '${opening.eco} ${openingDisplayName(l, opening)}'
                            : _moves.isEmpty
                            ? l.openingsStartPosition
                            : l.openingsUnnamed,
                        key: const Key('explorer-opening'),
                        style: text.titleMedium,
                      ),
                      subtitle: Text(_moveText(positions)),
                    ),
                    TrainingBoard(
                      size: size,
                      position: positions.last,
                      lastMove: _moves.isEmpty ? null : _moves.last,
                      player: positions.last.turn,
                      orientation: _orientation,
                      onMove: _play,
                    ),
                    Expanded(
                      child: next.isEmpty
                          ? Center(
                              child: Text(
                                l.openingsOutOfBook,
                                style: text.bodyLarge,
                              ),
                            )
                          : ListView(
                              children: [
                                for (final m in next)
                                  ListTile(
                                    dense: true,
                                    leading: SizedBox(
                                      width: 56,
                                      child: Text(
                                        formatSan(m.san, notation),
                                        style: text.titleMedium,
                                      ),
                                    ),
                                    title: Text(
                                      m.opening == null
                                          ? ''
                                          : openingDisplayName(l, m.opening!),
                                    ),
                                    trailing: Text(
                                      '${(m.share * 100).round()}%',
                                    ),
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
                            label: Text(l.openingsBack),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: _moves.isEmpty ? null : _reset,
                            icon: const Icon(Icons.first_page),
                            label: Text(l.openingsReset),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openPersonal() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PersonalExplorerPage(
          archive: widget.archive!(),
          book: _book,
          initialMoves: [..._moves],
          repertoire: widget.repertoire,
          onPlay: widget.onPlay,
        ),
      ),
    );
  }

  Future<void> _playOpening() async {
    final choice = await askOpeningGame(
      context,
      // Di norma si gioca il colore che deve muovere dopo l'apertura.
      _positions.last.turn,
    );
    if (choice == null || !mounted) return;
    OpeningBook? book;
    try {
      book = await _book;
    } on Object {
      // Senza libro il titolo resta generico.
    }
    if (!mounted) return;
    final l = openingsL10n(context);
    final opening = book?.classifyPositions(_positions);
    final title = opening == null
        ? l.openingsFreeTitle
        : openingDisplayName(l, opening);
    await widget.onPlay!(
      context,
      OpeningGameRequest.explorer(
        title,
        [..._moves],
        choice.side,
        levelId: choice.levelId,
      ),
    );
  }

  Future<void> _addToRepertoire() async {
    OpeningBook? book;
    try {
      book = await _book;
    } on Object {
      // Senza libro si propone un nome generico.
    }
    if (!mounted) return;
    final l = openingsL10n(context);
    // Niente dispose: il dialogo lo usa ancora durante l'animazione di uscita.
    final opening = book?.classifyPositions(_positions);
    final name = TextEditingController(
      text: opening == null
          ? l.openingsDefaultLineName
          : openingDisplayName(l, opening),
    );
    // Di norma la linea finisce con la mossa del proprio colore.
    var side = _moves.length.isOdd ? Side.white : Side.black;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(l.openingsAddToRepertoire),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l.openingsLineName),
              ),
              const SizedBox(height: 16),
              SegmentedButton<Side>(
                segments: [
                  ButtonSegment(
                    value: Side.white,
                    label: Text(l.openingsWhite),
                  ),
                  ButtonSegment(
                    value: Side.black,
                    label: Text(l.openingsBlack),
                  ),
                ],
                selected: {side},
                onSelectionChanged: (s) => setDialog(() => side = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.openingsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.openingsAdd),
            ),
          ],
        ),
      ),
    );
    final label = name.text.trim().isEmpty
        ? l.openingsDefaultLineName
        : name.text.trim();
    if (confirmed != true || !mounted) return;
    final error = await widget.repertoire!.addLine(side, label, [
      ..._moves,
    ], notation: AppSettings.of(context).notation);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error != null
              ? repertoireErrorText(l, error)
              : side == Side.white
              ? l.openingsLineAddedWhite
              : l.openingsLineAddedBlack,
        ),
      ),
    );
  }

  String _moveText(List<Position> positions) {
    final parts = <String>[];
    for (var i = 0; i < _moves.length; i++) {
      final san = positions[i].makeSan(_moves[i]).$2;
      final shown = formatSan(san, AppSettings.of(context).notation);
      parts.add(i.isEven ? '${i ~/ 2 + 1}. $shown' : shown);
    }
    return parts.join(' ');
  }
}
