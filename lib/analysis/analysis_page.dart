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
import '../settings/settings.dart';

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
  });

  final Position initial;
  final LiveAnalysis analyse;

  /// Lato del giocatore, in basso sulla scacchiera.
  final Side orientation;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with WidgetsBindingObserver {
  late final List<Position> _positions = [widget.initial];
  final _moves = <Move>[];
  final _sans = <String>[];
  int _index = 0;
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
  StreamSubscription<List<InfoLine>>? _threatAnalysis;

  List<InfoLine> _lines = const [];
  List<InfoLine>? _pending;
  Timer? _throttle;
  StreamSubscription<List<InfoLine>>? _analysis;
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );

  Position get _pos => _positions[_index];

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

  void _start() {
    _stop();
    _lines = const [];
    _failed = false;
    if (_paused || _background || _pos.isGameOver) return;
    _analysis = widget
        .analyse(_pos.fen, _multiPv)
        .listen(
          _onLines,
          onError: (Object _) {
            if (mounted) setState(() => _failed = true);
          },
        );
    _startThreat();
  }

  void _startThreat() {
    _threatLine = null;
    final fen = threatFen(_pos);
    if (!_threat || fen == null) return;
    _threatAnalysis = widget.analyse(fen, 1).listen(
      (lines) {
        if (mounted) setState(() => _threatLine = lines.firstOrNull);
      },
      // Senza la seconda analisi resta l'analisi principale.
      onError: (Object _) {},
    );
  }

  void _stop() {
    unawaited(_threatAnalysis?.cancel());
    _threatAnalysis = null;
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

  GameData _gameData() => gameDataFor(
    _pos,
    lastMove: _index == 0 ? null : _moves[_index - 1],
    interactive: true,
  );

  void _go(int index) {
    setState(() => _index = index);
    _board.updatePosition(_gameData());
    _start();
  }

  void _play(Move move, {bool? viaDragAndDrop}) {
    if (!_pos.isLegal(move)) return;
    final next = _pos.play(move);
    _positions
      ..removeRange(_index + 1, _positions.length)
      ..add(next);
    _moves
      ..removeRange(_index, _moves.length)
      ..add(move);
    _sans
      ..removeRange(_index, _sans.length)
      ..add(_pos.makeSan(move).$2);
    _go(_index + 1);
  }

  void _toggleThreat() {
    setState(() {
      _threat = !_threat;
      unawaited(_threatAnalysis?.cancel());
      _threatAnalysis = null;
      _startThreat();
    });
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

  Set<Shape> _shapes() => {
    ..._arrowFor(_pos, _arrow ? _lines.firstOrNull : null, _bestColor),
    ..._arrowFor(_threatPosition, _threatLine, _threatColor),
  };

  static const _bestColor = Color(0xCC3E8E2F);
  static const _threatColor = Color(0xCCC0392B);

  /// Posizione a mossa nulla, se la minaccia è attiva e possibile.
  Position? get _threatPosition {
    final fen = threatFen(_pos);
    return !_threat || fen == null
        ? null
        : Chess.fromSetup(Setup.parseFen(fen));
  }

  Set<Shape> _arrowFor(Position? pos, InfoLine? line, Color color) {
    if (pos == null) return const {};
    final move = parseEngineMove(pos, line?.pv.firstOrNull);
    if (move is! NormalMove) return const {};
    final shown = kingDestination(pos, move);
    return {Arrow(color: color, orig: shown.from, dest: shown.to)};
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final white = _whiteScore;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisi'),
        actions: [
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
                                settings: const ChessboardSettings(
                                  colorScheme: ChessboardColorScheme.green,
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
                        for (final line in _lines) _lineTile(line),
                        if (_moves.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_history(), style: text.bodyLarge),
                          ),
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
    final out = <String>[];
    Position pos = _pos;
    for (final uci in pv.take(8)) {
      final move = parseEngineMove(pos, uci);
      if (move == null) break;
      final (next, san) = pos.makeSan(move);
      out.add(san);
      pos = next;
    }
    return out.join(' ');
  }

  String _history() => [
    for (var i = 0; i < _sans.length; i++)
      if (_positions[i].turn == Side.white || i == 0)
        '${moveNumber(_positions[i])} ${_sans[i]}'
      else
        _sans[i],
  ].join(' ');

  Widget _navigation() => SizedBox(
    height: 56,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          tooltip: 'Indietro',
          onPressed: _index == 0 ? null : () => _go(_index - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: _paused ? 'Riprendi l\'analisi' : 'Ferma l\'analisi',
          onPressed: _togglePause,
          icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
        ),
        IconButton(
          tooltip: 'Avanti',
          onPressed: _index == _moves.length ? null : () => _go(_index + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );
}
