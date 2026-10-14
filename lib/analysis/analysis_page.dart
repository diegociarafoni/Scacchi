import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../archive/game_archive.dart';
import '../archive/saved_game.dart';
import '../archive/tree_pgn.dart';
import '../engine/uci.dart';
import '../game/move_note_dialog.dart';
import '../l10n/app_localizations.dart';
import '../review/board_utils.dart';
import '../review/eval_bar.dart';
import '../review/score_format.dart';
import '../review/win_probability.dart';
import '../settings/board_marks.dart';
import '../settings/notation.dart';
import '../settings/settings.dart';
import '../share/position_image.dart';
import '../share/position_image_page.dart';
import '../tablebase/perfect_endgame_card.dart';
import '../tablebase/tablebase_service.dart';
import '../theme/motion.dart';
import 'variation_tree.dart';

/// Analisi continua di [fen] con [multiPv] varianti, interrotta annullando
/// l'iscrizione al flusso.
typedef LiveAnalysis = Stream<List<InfoLine>> Function(String fen, int multiPv);

/// Analisi libera di una posizione (RF-50…RF-52, RF-54): barra di
/// valutazione, linee del motore, esplorazione delle mosse.
class AnalysisPage extends StatefulWidget {
  const AnalysisPage({
    super.key,
    required this.initial,
    required this.analyse,
    this.orientation = Side.white,
    this.tablebase,
    this.tree,
    this.saved,
    this.onSave = saveToSharedArchive,
    this.share,
  });

  final Position initial;
  final LiveAnalysis analyse;

  /// Finali perfetti (RF-97): se c'è, con al massimo quattro pezzi compare
  /// il risultato esatto.
  final TablebaseService? tablebase;

  /// Lato del giocatore, in basso sulla scacchiera.
  final Side orientation;

  /// Albero da riprendere, per esempio da un'analisi salvata; senza, si
  /// parte da [initial].
  final VariationTree? tree;

  /// Analisi dell'archivio da cui si è partiti: salvando si aggiorna questa.
  final SavedGame? saved;

  /// Salvataggio nell'archivio (RF-52); di norma quello condiviso dell'app.
  final Future<void> Function(SavedGame game) onSave;

  /// Condivisione del PGN; senza, si usa il foglio di condivisione del
  /// sistema.
  final Future<void> Function(String pgn)? share;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

/// Salva [game] nell'archivio condiviso dell'app.
Future<void> saveToSharedArchive(SavedGame game) async =>
    (await GameArchive.open()).save(game);

enum _Menu { save, share }

class _AnalysisPageState extends State<AnalysisPage>
    with WidgetsBindingObserver {
  late final VariationTree _tree = widget.tree ?? VariationTree(widget.initial);
  late SavedGame? _saved = widget.saved;
  bool _failed = false;
  int _multiPv = 1;
  bool _paused = false;

  /// App in secondo piano: il motore si ferma per non consumare batteria.
  bool _background = false;
  bool _arrow = true;

  /// Freccia della minaccia dell'avversario (RF-56), da una seconda analisi
  /// a mossa nulla.
  bool _threat = false;
  InfoLine? _threatLine;
  Position? _threatPos;
  bool _mainStarted = false;

  List<InfoLine> _lines = const [];
  List<InfoLine>? _pending;
  Timer? _throttle;
  StreamSubscription<List<InfoLine>>? _analysis;
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );

  Position get _pos => _tree.current.position;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (state != AppLifecycleState.resumed && !background) return;
    if (background == _background) return;
    _background = background;
    if (background) {
      _stop();
    } else {
      setState(_start);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    _board.dispose();
    super.dispose();
  }

  /// Profondità a cui la ricerca della minaccia basta per la freccia.
  static const _threatDepth = 14;

  void _start() {
    _stop();
    _lines = const [];
    _failed = false;
    _threatLine = null;
    _threatPos = null;
    _mainStarted = false;
    if (_paused || _background || _pos.isGameOver) return;
    final fen = _threat ? threatFen(_pos) : null;
    if (fen == null) return _startMain();
    // Il motore ha una sola coda: prima la ricerca breve della minaccia, poi
    // quella principale.
    _threatPos = Chess.fromSetup(Setup.parseFen(fen));
    _analysis = widget
        .analyse(fen, 1)
        .listen(
          (lines) {
            final line = lines.firstOrNull;
            if (line == null || !mounted) return;
            setState(() => _threatLine = line);
            if ((line.depth ?? 0) >= _threatDepth) _startMain();
          },
          // Senza la minaccia resta l'analisi principale.
          onError: (Object _) => _startMain(),
          // Matto o fine della ricerca prima della profondità voluta.
          onDone: () {
            if (mounted && !_mainStarted) _startMain();
          },
        );
  }

  /// Analisi principale della posizione, dopo l'eventuale minaccia.
  void _startMain() {
    _mainStarted = true;
    unawaited(_analysis?.cancel());
    _analysis = widget
        .analyse(_pos.fen, _multiPv)
        .listen(
          _onLines,
          onError: (Object _) {
            if (mounted) setState(() => _failed = true);
          },
        );
  }

  void _stop() {
    _throttle?.cancel();
    _throttle = null;
    _pending = null;
    unawaited(_analysis?.cancel());
    _analysis = null;
  }

  // Il motore manda molte righe al secondo: si ridisegna al massimo ogni
  // 250 ms per non scaricare la batteria.
  void _onLines(List<InfoLine> lines) {
    _pending = lines;
    _throttle ??= Timer(const Duration(milliseconds: 250), () {
      _throttle = null;
      final latest = _pending;
      if (latest != null && mounted) setState(() => _lines = latest);
    });
  }

  GameData _gameData() =>
      gameDataFor(_pos, lastMove: _tree.current.move, interactive: true);

  /// Aggiorna scacchiera e analisi dopo che [_tree] ha cambiato posizione.
  void _moved() {
    setState(() {});
    _board.updatePosition(_gameData());
    _start();
  }

  void _play(Move move, {bool? viaDragAndDrop}) {
    if (_tree.play(move) != null) _moved();
  }

  void _select(VariationNode node) {
    _tree.select(node);
    _moved();
  }

  void _promote() {
    setState(() => _tree.promote(_tree.current));
  }

  void _delete() {
    final before = _tree.current;
    _tree.delete(before);
    // Il motore riparte solo se la posizione è cambiata.
    if (_tree.current == before) return setState(() {});
    _moved();
  }

  void _back() {
    _tree.back();
    _moved();
  }

  void _forward() {
    _tree.forward();
    _moved();
  }

  /// PGN dell'albero com'è ora, con le varianti e le note.
  String _pgn() =>
      _saved?.withTree(_tree).pgn ??
      exportTreePgn(_tree, headers: {'Site': 'Offline'});

  Future<void> _sharePgn() {
    final share = widget.share;
    if (share != null) return share(_pgn());
    return SharePlus.instance.share(ShareParams(text: _pgn()));
  }

  Future<String?> _askName() {
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';
    return showDialog<String>(
      context: context,
      animationStyle: motionStyle(context),
      builder: (context) => _NameDialog(
        initial: AppLocalizations.of(context).analysisDefaultName(date),
      ),
    );
  }

  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    try {
      await _saveNow();
    } finally {
      _saving = false;
    }
  }

  Future<void> _saveNow() async {
    final previous = _saved;
    final name = previous == null ? await _askName() : null;
    if (!mounted) return;
    if (previous == null && (name == null || name.isEmpty)) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final game = previous == null
        ? SavedGame.fromTree(
            _tree,
            id: 'analisi-${now.microsecondsSinceEpoch}',
            name: name!,
            createdAt: now,
            updatedAt: now,
          )
        : previous.withTree(_tree, updatedAt: now);
    try {
      await widget.onSave(game);
      _saved = game;
      messenger.showSnackBar(SnackBar(content: Text(l.analysisSaved)));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l.analysisSaveFailed)));
    }
  }

  Future<void> _editNote() async {
    final node = _tree.current;
    if (node.isRoot) return;
    final note = await showMoveNoteDialog(
      context,
      san: formatSan(node.san, AppSettings.of(context).notation),
      note: node.note,
    );
    if (note == null || !mounted) return;
    setState(() => node.note = note.isEmpty ? null : note);
  }

  void _toggleThreat() {
    setState(() => _threat = !_threat);
    _start();
  }

  void _setMultiPv(int value) {
    setState(() => _multiPv = value);
    _start();
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    _start();
  }

  EngineScore? get _whiteScore {
    final s = _lines.firstOrNull?.score;
    if (s == null) return null;
    return _pos.turn == Side.white ? s : s.negated;
  }

  Set<Shape> _shapes() {
    final marks = AppSettings.of(context).marks;
    return {
      ..._arrowFor(marks, _pos, _arrow ? _lines.firstOrNull : null, marks.hint),
      ..._arrowFor(marks, _threatPos, _threatLine, marks.threat),
    };
  }

  Set<Shape> _arrowFor(
    BoardMarks marks,
    Position? pos,
    InfoLine? line,
    Color color,
  ) {
    if (pos == null) return const {};
    final move = parseEngineMove(pos, line?.pv.firstOrNull);
    if (move is! NormalMove) return const {};
    final shown = kingDestination(pos, move);
    return marks.arrow(color, shown.from, shown.to);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final white = _whiteScore;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.analysisTitle),
        actions: [
          PositionImageButton(
            image: () => PositionImage(
              fen: _pos.fen,
              orientation: widget.orientation,
              lastMove: _tree.current.move,
              shapes: _shapes(),
            ),
          ),
          IconButton(
            tooltip: l.analysisBestMoveArrow,
            isSelected: _arrow,
            onPressed: () => setState(() => _arrow = !_arrow),
            icon: const Icon(Icons.north_east),
          ),
          IconButton(
            tooltip: l.analysisThreatArrow,
            isSelected: _threat,
            // Sotto scacco o a partita finita la mossa nulla non esiste.
            onPressed: threatFen(_pos) == null ? null : _toggleThreat,
            icon: const Icon(Icons.warning_amber),
          ),
          PopupMenuButton<_Menu>(
            tooltip: l.analysisMore,
            onSelected: (item) => switch (item) {
              _Menu.save => unawaited(_save()),
              _Menu.share => unawaited(_sharePgn()),
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: _Menu.save, child: Text(l.analysisSave)),
              PopupMenuItem(
                value: _Menu.share,
                child: Text(l.analysisSharePgn),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = math.min(
              constraints.maxWidth - evalBarWidth - 24,
              constraints.maxHeight * 0.6,
            );
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              EvalBar(
                                height: boardSize,
                                score: white,
                                whiteWin: white == null
                                    ? null
                                    : winPercent(white),
                              ),
                              const SizedBox(width: 8),
                              Chessboard(
                                size: boardSize,
                                controller: _board,
                                orientation: widget.orientation,
                                onMove: _play,
                                shapes: _shapes(),
                                settings: AppSettings.of(context).exerciseBoard,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Text(_status(), style: text.labelLarge),
                              SegmentedButton<int>(
                                showSelectedIcon: false,
                                segments: [
                                  ButtonSegment(
                                    value: 1,
                                    label: Text(l.analysisOneLine),
                                  ),
                                  ButtonSegment(
                                    value: 2,
                                    label: Text(l.analysisTwoLines),
                                  ),
                                  ButtonSegment(
                                    value: 3,
                                    label: Text(l.analysisThreeLines),
                                  ),
                                ],
                                selected: {_multiPv},
                                onSelectionChanged: (v) => _setMultiPv(v.first),
                              ),
                            ],
                          ),
                        ),
                        if (widget.tablebase != null)
                          PerfectEndgameCard(
                            service: widget.tablebase!,
                            position: _pos,
                            notation: AppSettings.of(context).notation,
                            kid: AppSettings.of(context).kidMode,
                            onBestMove: _play,
                          ),
                        for (final line in _lines) _lineTile(line),
                        if (_tree.root.children.isNotEmpty) ...[
                          _treeActions(),
                          if (_tree.current.note?.comment case final c?)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                c,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: _lineView(_tree.root),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _navigation(),
              ],
            );
          },
        ),
      ),
    );
  }

  String _status() {
    final l = AppLocalizations.of(context);
    if (_failed) return l.analysisEngineUnavailable;
    if (_paused) return l.analysisPaused;
    if (_pos.isGameOver) return l.analysisGameOver;
    // Profilo bambino (RP-06): niente profondità del motore.
    if (AppSettings.of(context).kidMode) return l.kidAnalysisThinking;
    final depth = _lines.firstOrNull?.depth;
    return depth == null ? l.analysisThinking : l.analysisDepth(depth);
  }

  Widget _lineTile(InfoLine line) {
    final score = line.score;
    final white = score == null
        ? null
        : (_pos.turn == Side.white ? score : score.negated);
    final san = _sanLine(line.pv);
    return ListTile(
      dense: true,
      leading: SizedBox(
        width: 56,
        child: Text(
          white == null || AppSettings.of(context).kidMode
              ? ''
              : formatScore(white),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(san),
      onTap: () {
        final first = parseEngineMove(_pos, line.pv.firstOrNull);
        if (first != null) _play(first);
      },
    );
  }

  /// Prime otto semimosse della variante in notazione SAN.
  String _sanLine(List<String> pv) {
    final notation = AppSettings.of(context).notation;
    final out = <String>[];
    Position pos = _pos;
    for (final uci in pv.take(8)) {
      final move = parseEngineMove(pos, uci);
      if (move == null) break;
      final (next, san) = pos.makeSan(move);
      out.add(formatSan(san, notation));
      pos = next;
    }
    return out.join(' ');
  }

  /// Comandi sulla mossa corrente: promuovere la variante o eliminarla.
  Widget _treeActions() {
    final l = AppLocalizations.of(context);
    final node = _tree.current;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: node.note == null ? l.reviewAddNote : l.reviewEditNote,
          onPressed: node.isRoot ? null : _editNote,
          icon: Icon(
            node.note == null ? Icons.edit_note : Icons.edit_note_outlined,
          ),
        ),
        IconButton(
          tooltip: l.analysisPromote,
          onPressed: node.isRoot || _tree.isMainLine(node) ? null : _promote,
          icon: const Icon(Icons.upgrade),
        ),
        IconButton(
          tooltip: l.analysisDelete,
          onPressed: node.isRoot ? null : _delete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  /// Le mosse che seguono [from] (o la linea che comincia da [first], se
  /// data): la continuazione principale in riga, le varianti rientrate sotto
  /// la mossa a cui si alternano.
  Widget _lineView(VariationNode from, {VariationNode? first}) {
    final blocks = <Widget>[];
    var chips = <Widget>[];
    void flush() {
      if (chips.isEmpty) return;
      blocks.add(Wrap(spacing: 4, runSpacing: 4, children: chips));
      chips = [];
    }

    var node = from;
    var restart = true;
    if (first != null) {
      chips.add(_moveChip(first, true));
      restart = false;
      node = first;
    }
    while (node.children.isNotEmpty) {
      final main = node.children.first;
      chips.add(_moveChip(main, restart));
      restart = false;
      if (node.children.length > 1) {
        flush();
        for (final variation in node.children.skip(1)) {
          blocks.add(
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
              child: _lineView(node, first: variation),
            ),
          );
        }
        restart = true;
      }
      node = main;
    }
    flush();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget _moveChip(VariationNode node, bool withNumber) {
    final notation = AppSettings.of(context).notation;
    final before = node.parent!.position;
    final san = formatSan(node.san, notation);
    final symbol = node.note?.symbol?.text ?? '';
    final label = before.turn == Side.white || withNumber
        ? '${moveNumber(before)} $san$symbol'
        : '$san$symbol';
    final selected = node == _tree.current;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _select(node),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: _tree.isMainLine(node) ? FontWeight.w600 : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigation() {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: l.analysisBack,
            onPressed: _tree.canBack ? _back : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: _paused ? l.analysisResume : l.analysisPause,
            onPressed: _togglePause,
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
          ),
          IconButton(
            tooltip: l.analysisForward,
            onPressed: _tree.canForward ? _forward : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// Richiesta del nome con cui salvare l'analisi.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.analysisSaveTitle),
      content: TextField(controller: _text, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.analysisCancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _text.text.trim();
            Navigator.pop(context, name.isEmpty ? widget.initial : name);
          },
          child: Text(l.analysisSaveConfirm),
        ),
      ],
    );
  }
}
