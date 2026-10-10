import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../training/training_board.dart';
import 'opening_assets.dart';
import 'opening_book.dart';

/// Explorer ridotto: continuazioni del libro dalla posizione corrente (RF-92).
class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key, this.book, this.initialMoves = const []});

  /// Sostituibile nei test; di default il libro incluso nell'app.
  final Future<OpeningBook>? book;
  final List<Move> initialMoves;

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  late final Future<OpeningBook> _book = widget.book ?? openingBook();
  late final List<Move> _moves = [...widget.initialMoves];
  Side _orientation = Side.white;

  List<Position> get _positions => OpeningBook.replay(_moves);

  void _play(Move move) {
    if (!_positions.last.isLegal(move)) return;
    setState(() => _moves.add(move));
  }

  void _back() => setState(() => _moves.removeLast());

  @override
  Widget build(BuildContext context) {
    final positions = _positions;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        actions: [
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
            final book = snapshot.data;
            if (book == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final opening = book.classify(_moves);
            final next = book.continuations(_moves);
            return LayoutBuilder(
              builder: (context, c) {
                final size = math.min(c.maxWidth, c.maxHeight * 0.55);
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        opening == null
                            ? 'Posizione iniziale'
                            : '${opening.eco} ${opening.name}',
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
                                        m.san,
                                        style: text.titleMedium,
                                      ),
                                    ),
                                    title: Text(m.opening?.name ?? ''),
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
                            onPressed: _moves.isEmpty
                                ? null
                                : () => setState(_moves.clear),
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

  String _moveText(List<Position> positions) {
    final parts = <String>[];
    for (var i = 0; i < _moves.length; i++) {
      final san = positions[i].makeSan(_moves[i]).$2;
      parts.add(i.isEven ? '${i ~/ 2 + 1}. $san' : san);
    }
    return parts.join(' ');
  }
}
