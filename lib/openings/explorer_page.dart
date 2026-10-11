import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../game/chess_game.dart';
import '../settings/notation.dart';
import '../settings/settings.dart';
import '../training/training_board.dart';
import 'opening_assets.dart';
import 'opening_book.dart';
import 'repertoire.dart';

/// Esplora aperture: continuazioni del libro dalla posizione corrente (RF-92).
class ExplorerPage extends StatefulWidget {
  const ExplorerPage({
    super.key,
    this.book,
    this.initialMoves = const [],
    this.repertoire,
  });

  /// Sostituibile nei test; di default il libro incluso nell'app.
  final Future<OpeningBook>? book;
  final List<Move> initialMoves;

  /// Se presente, la linea corrente si può aggiungere al repertorio.
  final RepertoireTrainer? repertoire;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esplora aperture'),
        actions: [
          if (widget.repertoire != null)
            IconButton(
              tooltip: 'Aggiungi al repertorio',
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: _moves.isEmpty ? null : _addToRepertoire,
            ),
          IconButton(
            tooltip: 'Gira la scacchiera',
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
              return const Center(
                child: Text('Impossibile caricare le aperture.'),
              );
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
                            ? '${opening.eco} ${opening.localName}'
                            : _moves.isEmpty
                            ? 'Posizione iniziale'
                            : 'Apertura senza nome',
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
                                'Fuori dal libro delle aperture',
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
                                    title: Text(m.opening?.localName ?? ''),
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
                            label: const Text('Indietro'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: _moves.isEmpty ? null : _reset,
                            icon: const Icon(Icons.first_page),
                            label: const Text('Inizio'),
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

  Future<void> _addToRepertoire() async {
    OpeningBook? book;
    try {
      book = await _book;
    } on Object {
      // Senza libro si propone un nome generico.
    }
    if (!mounted) return;
    // Niente dispose: il dialogo lo usa ancora durante l'animazione di uscita.
    final name = TextEditingController(
      text: book?.classifyPositions(_positions)?.localName ?? 'Linea',
    );
    // Di norma la linea finisce con la mossa del proprio colore.
    var side = _moves.length.isOdd ? Side.white : Side.black;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Aggiungi al repertorio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<Side>(
                segments: const [
                  ButtonSegment(value: Side.white, label: Text('Bianco')),
                  ButtonSegment(value: Side.black, label: Text('Nero')),
                ],
                selected: {side},
                onSelectionChanged: (s) => setDialog(() => side = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
    final label = name.text.trim().isEmpty ? 'Linea' : name.text.trim();
    if (confirmed != true || !mounted) return;
    final error = await widget.repertoire!.addLine(side, label, [..._moves]);
    if (!mounted) return;
    final color = side == Side.white ? 'Bianco' : 'Nero';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Linea aggiunta al repertorio del $color.'),
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
