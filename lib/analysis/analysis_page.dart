import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/uci.dart';
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
  });

  final Position initial;
  final LiveAnalysis analyse;

  /// Finali perfetti (RF-97): se c'è, con al massimo quattro pezzi compare
  /// il risultato esatto.
  final TablebaseService? tablebase;

  /// Lato del giocatore, in basso sulla scacchiera.
  final Side orientation;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with WidgetsBindingObserver {
  late final VariationTree _tree = VariationTree(widget.initial);
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
    // La scacchiera dell'analisi è sempre verde.
    final marks = BoardMarks.of(
      BoardTheme.green,
      colorBlind: AppSettings.of(context).colorBlind,
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisi'),
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
            tooltip: 'Freccia della mossa migliore',
            isSelected: _arrow,
            onPressed: () => setState(() => _arrow = !_arrow),
            icon: const Icon(Icons.north_east),
          ),
          IconButton(
            tooltip: 'Minaccia dell\'avversario',
            isSelected: _threat,
            // Sotto scacco o a partita finita la mossa nulla non esiste.
            onPressed: threatFen(_pos) == null ? null : _toggleThreat,
            icon: const Icon(Icons.warning_amber),
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
                                settings: ChessboardSettings(
                                  colorScheme: BoardTheme.green.colorScheme,
                                ),
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
                                segments: const [
                                  ButtonSegment(
                                    value: 1,
                                    label: Text('1 linea'),
                                  ),
                                  ButtonSegment(
                                    value: 2,
                                    label: Text('2 linee'),
                                  ),
                                  ButtonSegment(
                                    value: 3,
                                    label: Text('3 linee'),
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
    if (_failed) return 'Motore non disponibile';
    if (_paused) return 'Analisi in pausa';
    if (_pos.isGameOver) return 'Partita finita';
    // Profilo bambino (RP-06): niente profondità del motore.
    if (AppSettings.of(context).kidMode) {
      return AppLocalizations.of(context).kidAnalysisThinking;
    }
    final depth = _lines.firstOrNull?.depth;
    return depth == null ? 'Analisi…' : 'Profondità $depth';
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
    final node = _tree.current;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: 'Promuovi a linea principale',
          onPressed: node.isRoot || _tree.isMainLine(node) ? null : _promote,
          icon: const Icon(Icons.upgrade),
        ),
        IconButton(
          tooltip: 'Elimina la mossa e il seguito',
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
    final label = before.turn == Side.white || withNumber
        ? '${moveNumber(before)} $san'
        : san;
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

  Widget _navigation() => SizedBox(
    height: 56,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          tooltip: 'Indietro',
          onPressed: _tree.canBack ? _back : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: _paused ? 'Riprendi l\'analisi' : 'Ferma l\'analisi',
          onPressed: _togglePause,
          icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
        ),
        IconButton(
          tooltip: 'Avanti',
          onPressed: _tree.canForward ? _forward : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );
}
