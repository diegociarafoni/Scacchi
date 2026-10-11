import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../archive/saved_game.dart';
import '../game/chess_game.dart';
import '../game/clock.dart';
import 'physical_game.dart';

/// Registra e cronometra una partita giocata su una scacchiera reale: le mosse
/// si scrivono o si scelgono tra quelle legali, l'orologio passa da solo.
class PhysicalGamePage extends StatefulWidget {
  const PhysicalGamePage({super.key, required this.archive, this.now});

  final Future<GameArchive> Function() archive;
  final DateTime Function()? now;

  @override
  State<PhysicalGamePage> createState() => _PhysicalGamePageState();
}

class _PhysicalGamePageState extends State<PhysicalGamePage> {
  PhysicalGame? _game;
  TimeControl? _control = const TimeControl(minutes: 10);
  final _white = TextEditingController(text: 'Bianco');
  final _black = TextEditingController(text: 'Nero');
  final _input = TextEditingController();
  final _focus = FocusNode();
  Timer? _ticker;
  DateTime? _startedAt;
  bool _saved = false;
  String? _message;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void dispose() {
    _ticker?.cancel();
    _white.dispose();
    _black.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _begin() {
    final game = PhysicalGame(control: _control, now: widget.now)..start();
    setState(() {
      _game = game;
      _startedAt = _now;
      _saved = false;
      _message = null;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    final game = _game;
    if (game == null || !mounted) return;
    final before = game.isOver;
    game.checkFlag();
    setState(() {});
    if (!before && game.isOver) unawaited(_save());
  }

  void _afterChange() {
    final game = _game!;
    setState(() {});
    if (game.isOver) unawaited(_save());
    _focus.requestFocus();
  }

  void _submit(String text) {
    final game = _game!;
    if (game.playText(text) == PhysicalInput.invalid) {
      setState(() => _message = 'Mossa non valida: «$text»');
      return;
    }
    _input.clear();
    _message = null;
    _afterChange();
  }

  void _playSuggestion(MoveSuggestion s) {
    _game!.play(s.move);
    _input.clear();
    _message = null;
    _afterChange();
  }

  Future<void> _save() async {
    final game = _game;
    if (game == null || game.moves.isEmpty) return;
    final started = _startedAt ?? _now;
    try {
      final archive = await widget.archive();
      await archive.save(
        SavedGame(
          id: 'fisica-${started.microsecondsSinceEpoch}',
          createdAt: started,
          updatedAt: _now,
          white: _white.text.trim(),
          black: _black.text.trim(),
          mode: SavedGame.physical,
          result: game.result,
          pgn: game.pgnText(
            white: _white.text.trim(),
            black: _black.text.trim(),
            date: started,
          ),
          timeControl: game.control?.label,
        ),
      );
      if (mounted) setState(() => _saved = true);
    } on Object catch (e) {
      debugPrint('Salvataggio non riuscito: $e');
      if (mounted) setState(() => _message = 'Salvataggio non riuscito');
    }
  }

  Future<void> _resign() async {
    final side = await showDialog<Side>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Chi abbandona?'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, Side.white),
            child: Text(_white.text),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, Side.black),
            child: Text(_black.text),
          ),
        ],
      ),
    );
    if (side == null) return;
    _game!.resign(side);
    _afterChange();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return Scaffold(
      appBar: AppBar(title: const Text('Scacchiera fisica')),
      body: game == null ? _setup() : _playing(game),
    );
  }

  Widget _setup() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Gioca su una scacchiera vera: l\'app fa da orologio e registra la '
          'partita. Dopo ogni mossa scrivila o toccala tra quelle legali.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _white,
          decoration: const InputDecoration(labelText: 'Bianco'),
        ),
        TextField(
          controller: _black,
          decoration: const InputDecoration(labelText: 'Nero'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Senza tempo'),
              selected: _control == null,
              onSelected: (_) => setState(() => _control = null),
            ),
            for (final c in TimeControl.presets)
              ChoiceChip(
                label: Text(c.label),
                selected: _control == c,
                onSelected: (_) => setState(() => _control = c),
              ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _begin, child: const Text('Inizia la partita')),
      ],
    );
  }

  Widget _playing(PhysicalGame game) {
    final typed = _input.text;
    final suggestions = game.suggestions(typed);
    return SafeArea(
      child: Column(
        children: [
          RotatedBox(
            quarterTurns: 2,
            child: _ClockPanel(game: game, side: Side.black, name: _black.text),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  _movesText(game),
                  key: const Key('physical-moves'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (game.isOver) ..._over(game),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!game.isOver) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                key: const Key('physical-input'),
                controller: _input,
                focusNode: _focus,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: game.turn == Side.white
                      ? 'Mossa del Bianco (es. e4, Cf3)'
                      : 'Mossa del Nero (es. e5, Cc6)',
                ),
                onChanged: (_) => setState(() => _message = null),
                onSubmitted: _submit,
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final s in suggestions.take(20))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: ActionChip(
                        label: Text(s.san),
                        onPressed: () => _playSuggestion(s),
                      ),
                    ),
                ],
              ),
            ),
          ],
          _controls(game),
          _ClockPanel(game: game, side: Side.white, name: _white.text),
        ],
      ),
    );
  }

  Widget _controls(PhysicalGame game) {
    final running = game.clock?.isRunning ?? false;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        if (game.clock != null && !game.isOver)
          TextButton.icon(
            onPressed: () => setState(running ? game.pause : game.resume),
            icon: Icon(running ? Icons.pause : Icons.play_arrow),
            label: Text(running ? 'Pausa' : 'Riprendi'),
          ),
        TextButton.icon(
          onPressed: game.canUndo
              ? () {
                  game.undo();
                  _afterChange();
                }
              : null,
          icon: const Icon(Icons.undo),
          label: const Text('Annulla'),
        ),
        if (!game.isOver) ...[
          TextButton(
            onPressed: () {
              game.agreeDraw();
              _afterChange();
            },
            child: const Text('Patta'),
          ),
          TextButton(onPressed: _resign, child: const Text('Abbandona')),
        ],
      ],
    );
  }

  List<Widget> _over(PhysicalGame game) => [
    const SizedBox(height: 12),
    Text(
      _resultText(game),
      key: const Key('physical-result'),
      style: Theme.of(context).textTheme.titleMedium,
    ),
    if (_saved)
      const Text('Partita salvata nell\'archivio')
    else if (game.moves.isEmpty)
      const Text('Nessuna mossa da salvare'),
    const SizedBox(height: 8),
    Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton(
        onPressed: () {
          _ticker?.cancel();
          setState(() => _game = null);
        },
        child: const Text('Nuova partita'),
      ),
    ),
  ];

  String _resultText(PhysicalGame game) {
    final reason = switch (game.endReason) {
      GameEndReason.checkmate => 'Scacco matto',
      GameEndReason.resignation => 'Abbandono',
      GameEndReason.timeout => 'Tempo scaduto',
      GameEndReason.agreement => 'Patta concordata',
      GameEndReason.stalemate => 'Stallo',
      GameEndReason.insufficientMaterial => 'Materiale insufficiente',
      GameEndReason.threefoldRepetition => 'Tripla ripetizione',
      GameEndReason.fiftyMoveRule => 'Regola delle 50 mosse',
      _ => 'Partita finita',
    };
    return '$reason · ${game.result}';
  }

  String _movesText(PhysicalGame game) {
    if (game.moves.isEmpty) return 'Nessuna mossa';
    final buffer = StringBuffer();
    for (final (i, m) in game.moves.indexed) {
      if (i.isEven) buffer.write('${i ~/ 2 + 1}. ');
      buffer.write('${m.san} ');
    }
    return buffer.toString().trim();
  }
}

class _ClockPanel extends StatelessWidget {
  const _ClockPanel({
    required this.game,
    required this.side,
    required this.name,
  });

  final PhysicalGame game;
  final Side side;
  final String name;

  @override
  Widget build(BuildContext context) {
    final clock = game.clock;
    final active = clock?.active == side;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: active ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleMedium),
          Text(
            clock == null ? '—' : formatClock(clock.remaining(side)),
            key: Key('physical-clock-${side.name}'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}
