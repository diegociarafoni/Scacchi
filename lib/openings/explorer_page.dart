import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
import 'opening_stats.dart';
import 'personal_explorer_page.dart';
import 'repertoire.dart';

/// Esplora aperture: continuazioni del libro dalla posizione corrente (RF-92).
class ExplorerPage extends StatefulWidget {
  const ExplorerPage({
    super.key,
    this.book,
    this.stats,
    this.initialMoves = const [],
    this.repertoire,
    this.onPlay,
    this.archive,
  });

  /// Sostituibile nei test; di default il libro incluso nell'app.
  final Future<OpeningBook>? book;

  /// Statistiche per mossa (`openingStats()` nell'app); se mancano o non si
  /// leggono si mostra il libro.
  final Future<OpeningStats?>? stats;
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
  late final Future<OpeningStats?> _stats =
      widget.stats
          ?.then<OpeningStats?>((s) => s)
          .onError<Object>((_, _) => null) ??
      Future<OpeningStats?>.value();
  // Il libro è indispensabile, le statistiche no: senza si vede solo il libro.
  late final Future<(OpeningBook, OpeningStats?)> _loaded =
      Future.wait<Object?>([_book, _stats])
          .then((r) => (r[0]! as OpeningBook, r[1] as OpeningStats?));
  final List<Move> _moves = [];
  // Mosse tolte con Indietro o Ricomincia, l'ultima è la prossima da rifare.
  final List<Move> _redo = [];
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
      // Rifare la prossima mossa tolta conserva le altre; una diversa le azzera.
      if (_redo.isNotEmpty && _redo.last == move) {
        _redo.removeLast();
      } else {
        _redo.clear();
      }
      _moves.add(move);
      _positions = [..._positions, pos.play(move)];
    });
  }

  void _back() => setState(() {
    _redo.add(_moves.removeLast());
    _positions = _positions.sublist(0, _positions.length - 1);
  });

  void _forward() => _play(_redo.last);

  void _reset() => setState(() {
    _redo.addAll(_moves.reversed);
    _moves.clear();
    _positions = [_positions.first];
  });

  @override
  Widget build(BuildContext context) {
    final positions = _positions;
    final text = Theme.of(context).textTheme;
    final notation = AppSettings.of(context).notation;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).explorerTitle),
        actions: [
          if (widget.archive != null)
            IconButton(
              tooltip: AppLocalizations.of(context).personalFromHere,
              icon: const Icon(Icons.history_edu_outlined),
              onPressed: _openPersonal,
            ),
          if (widget.repertoire != null)
            IconButton(
              tooltip: 'Aggiungi al repertorio',
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: _moves.isEmpty ? null : _addToRepertoire,
            ),
          if (widget.onPlay != null)
            IconButton(
              tooltip: 'Gioca questa apertura',
              icon: const Icon(Icons.play_arrow),
              onPressed: _moves.isEmpty || positions.last.isGameOver
                  ? null
                  : _playOpening,
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<(OpeningBook, OpeningStats?)>(
          future: _loaded,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(l10n.explorerLoadFailed));
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final (book, stats) = data;
            final opening = book.classifyPositions(positions);
            // Solo le mosse legali: una riga che non si legge non conta.
            final measured = [
              for (final m in stats?.at(positions.last) ?? const <MoveStat>[])
                if (positions.last.parseSan(m.san) case final move?)
                  (stat: m, move: move),
            ];
            final next = book.continuationsAt(positions.last);
            return LayoutBuilder(
              builder: (context, c) {
                final size = math.min(c.maxWidth, c.maxHeight * 0.5);
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        opening != null
                            ? '${opening.eco} ${opening.localName}'
                            : _moves.isEmpty
                            ? l10n.explorerStartPosition
                            : l10n.explorerNoName,
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
                      child: measured.isNotEmpty
                          ? ListView(
                              children: [
                                for (final (:stat, :move) in measured)
                                  _StatRow(
                                    stat: stat,
                                    label: formatSan(stat.san, notation),
                                    opening: book.nameOf(
                                      positions.last.play(move),
                                    ),
                                    onTap: () => _play(move),
                                  ),
                              ],
                            )
                          : next.isEmpty
                          ? Center(
                              child: Text(
                                l10n.explorerOutOfBook,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Control(
                          icon: Icons.swap_vert,
                          label: l10n.explorerFlip,
                          onPressed: () => setState(
                            () => _orientation = _orientation.opposite,
                          ),
                        ),
                        _Control(
                          icon: Icons.restart_alt,
                          label: l10n.explorerRestart,
                          onPressed: _moves.isEmpty ? null : _reset,
                        ),
                        _Control(
                          icon: Icons.chevron_left,
                          label: l10n.explorerBack,
                          onPressed: _moves.isEmpty ? null : _back,
                        ),
                        _Control(
                          icon: Icons.chevron_right,
                          label: l10n.explorerForward,
                          onPressed: _redo.isEmpty ? null : _forward,
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
          stats: widget.stats,
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
    final title =
        book?.classifyPositions(_positions)?.localName ?? 'Apertura libera';
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
    final error = await widget.repertoire!.addLine(side, label, [
      ..._moves,
    ], notation: AppSettings.of(context).notation);
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

/// Pulsante della barra dei comandi: icona sopra, etichetta sotto.
class _Control extends StatelessWidget {
  const _Control({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

// Colori fissi, come i pezzi: bianco, patta e nero si leggono allo stesso modo
// nei due temi, con testo a contrasto sufficiente su ogni segmento.
const _whiteSegment = Color(0xFFF2F2F2);
const _drawSegment = Color(0xFF6B6B6B);
const _blackSegment = Color(0xFF2E2E2E);

/// Mossa con partite giocate e barra bianco/patta/nero.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.stat,
    required this.label,
    required this.opening,
    required this.onTap,
  });

  final MoveStat stat;
  final String label;
  final Opening? opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = stat.percents;
    final games = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(stat.games);
    return Semantics(
      button: true,
      label: l10n.explorerMoveSemantics(
        label,
        stat.games,
        p.white,
        p.draws,
        p.black,
      ),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(label, style: text.titleMedium),
                  ),
                  SizedBox(
                    width: 84,
                    child: Text(
                      games,
                      textAlign: TextAlign.end,
                      style: text.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _ResultBar(p)),
                ],
              ),
              if (opening != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(opening!.localName, style: text.bodySmall),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar(this.p);

  final ({int white, int draws, int black}) p;

  @override
  Widget build(BuildContext context) {
    Widget segment(int percent, Color color, Color textColor) => Expanded(
      flex: percent,
      child: ColoredBox(
        color: color,
        child: Center(
          // Sotto il 10% il numero non entra nel segmento.
          child: percent < 10
              ? null
              : Text(
                  '$percent%',
                  maxLines: 1,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            if (p.white > 0) segment(p.white, _whiteSegment, Colors.black),
            if (p.draws > 0) segment(p.draws, _drawSegment, Colors.white),
            if (p.black > 0) segment(p.black, _blackSegment, Colors.white),
          ],
        ),
      ),
    );
  }
}
