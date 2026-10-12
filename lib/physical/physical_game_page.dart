import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../archive/game_archive.dart';
import '../archive/saved_game.dart';
import '../game/chess_game.dart';
import '../game/clock.dart';
import 'board_align_page.dart';
import 'board_photo.dart';
import 'photo_source.dart';
import 'physical_game.dart';

/// Registra e cronometra una partita giocata su una scacchiera reale: le mosse
/// si scrivono o si scelgono tra quelle legali, l'orologio passa da solo.
class PhysicalGamePage extends StatefulWidget {
  const PhysicalGamePage({
    super.key,
    required this.archive,
    this.now,
    this.photos = const CameraPhotoSource(),
  });

  final Future<GameArchive> Function() archive;
  final DateTime Function()? now;

  /// Fotocamera per leggere la mossa dalla foto della scacchiera.
  final PhotoSource photos;

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
  String? _note;

  // Foto di riferimento: vale solo finché la posizione è quella in cui è
  // stata scattata.
  BoardFrame? _baseline;
  String? _baselineFen;
  BoardQuad? _quad;
  Side _view = Side.white;
  BoardFrame? _pendingFrame;
  List<MoveSuggestion> _guesses = const [];
  bool _reading = false;

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
      _note = null;
      _baseline = null;
      _baselineFen = null;
      _quad = null;
      _guesses = const [];
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    final game = _game;
    if (game == null || !mounted) return;
    if (!(game.clock?.isRunning ?? false) || game.isOver) return;
    game.checkFlag();
    setState(() {});
    if (game.isOver) unawaited(_save());
  }

  void _afterChange() {
    final game = _game!;
    setState(() {
      _guesses = const [];
      _note = null;
    });
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

  /// Fotografa la scacchiera: la prima foto fa da riferimento, quelle dopo
  /// vengono confrontate con la precedente per dedurre la mossa.
  Future<void> _photo() async {
    if (_reading) return;
    _reading = true;
    try {
      final Uint8List? bytes;
      try {
        bytes = await widget.photos.take();
      } on Object catch (e) {
        if (kDebugMode) debugPrint('Fotocamera non disponibile: $e');
        if (mounted) _show(error: 'Fotocamera non disponibile');
        return;
      }
      if (bytes == null || !mounted) return;
      final frame = await decodeFrame(bytes);
      if (!mounted) return;
      if (frame == null) {
        _show(error: 'Immagine non leggibile');
        return;
      }
      if (_quad == null && !await _align(bytes, frame)) return;
      if (!mounted) return;
      final game = _game!;
      final fen = game.position.fen;
      final before = _baseline;
      if (before == null || _baselineFen != fen) {
        setState(() {
          _baseline = frame;
          _baselineFen = fen;
          _guesses = const [];
          _message = null;
          _note =
              'Foto di riferimento salvata. Dopo la prossima mossa scatta '
              'un\'altra foto.';
        });
        return;
      }
      final found = guessMoves(
        game.position,
        before: before,
        after: frame,
        quad: _quad!,
        view: _view,
      );
      if (found.isEmpty) {
        _show(error: 'Nessuna mossa riconosciuta: la scacchiera è uguale.');
        return;
      }
      final pos = game.position;
      setState(() {
        _pendingFrame = frame;
        _guesses = [
          for (final g in topGuesses(found, 4))
            (san: pos.makeSan(g.move).$2, move: g.move),
        ];
        _message = null;
        _note = 'Mosse più probabili dalla foto: conferma quella giusta.';
      });
    } finally {
      _reading = false;
    }
  }

  /// Chiede dove sta la scacchiera nella foto; false se si annulla.
  Future<bool> _align(Uint8List bytes, BoardFrame frame) async {
    final result = await Navigator.push<AlignResult>(
      context,
      MaterialPageRoute(
        builder: (_) => BoardAlignPage(
          image: bytes,
          aspect: frame.width / frame.height,
          initial: _quad ?? BoardQuad.inset(.08),
          view: _view,
        ),
      ),
    );
    if (result == null || !mounted) return false;
    setState(() {
      _quad = result.quad;
      _view = result.view;
      _baseline = null;
    });
    return true;
  }

  void _playGuess(MoveSuggestion g) {
    final game = _game!;
    final frame = _pendingFrame;
    if (game.play(g.move) != PhysicalInput.played) return;
    _input.clear();
    _message = null;
    _afterChange();
    // La foto che ha prodotto la mossa è il riferimento per la prossima.
    if (frame != null) {
      setState(() {
        _baseline = frame;
        _baselineFen = game.position.fen;
      });
    }
  }

  void _show({String? error}) => setState(() {
    _message = error;
    _note = null;
  });

  Future<void> _save() async {
    final game = _game;
    if (game == null || game.moves.isEmpty) return;
    final started = _startedAt ?? _now;
    final white = _white.text.trim();
    final black = _black.text.trim();
    final saved = SavedGame(
      id: 'fisica-${started.microsecondsSinceEpoch}',
      createdAt: started,
      updatedAt: _now,
      white: white,
      black: black,
      mode: SavedGame.physical,
      result: game.result,
      pgn: game.pgnText(white: white, black: black, date: started),
      timeControl: game.control?.label,
    );
    try {
      await (await widget.archive()).save(saved);
      if (mounted) setState(() => _saved = true);
    } on Object catch (e) {
      debugPrint('Salvataggio non riuscito: $e');
      if (mounted) setState(() => _message = 'Salvataggio non riuscito');
    }
  }

  Future<void> _draw() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Patta concordata?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sì'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _game!.agreeDraw();
    _afterChange();
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
                if (_note != null && _message == null && !game.isOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_note!),
                  ),
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
            if (_guesses.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    const Icon(Icons.photo_camera_outlined),
                    for (final (i, g) in _guesses.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: ActionChip(
                          key: const Key('photo-guess'),
                          avatar: i == 0 ? const Icon(Icons.check) : null,
                          label: Text(g.san),
                          onPressed: () => _playGuess(g),
                        ),
                      ),
                  ],
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
        if (!game.isOver)
          TextButton.icon(
            key: const Key('physical-photo'),
            onPressed: _photo,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Mossa dalla foto'),
          ),
        if (!game.isOver && _quad != null)
          TextButton(
            key: const Key('physical-realign'),
            onPressed: () => setState(() => _quad = null),
            child: const Text('Riallinea'),
          ),
        TextButton.icon(
          onPressed: game.canUndo
              ? () {
                  game.undo();
                  _saved = false;
                  _afterChange();
                }
              : null,
          icon: const Icon(Icons.undo),
          label: const Text('Annulla'),
        ),
        if (!game.isOver) ...[
          TextButton(onPressed: _draw, child: const Text('Patta')),
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
