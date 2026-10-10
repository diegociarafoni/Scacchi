import 'dart:async';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';

import 'choose.dart';
import 'levels.dart';
import 'uci.dart';
import 'uci_transport.dart';

/// Mossa scelta dal computer.
class EngineMove {
  const EngineMove({
    required this.move,
    required this.pv,
    this.score,
    this.depth,
  });

  /// Normalizzata per dartchess (arrocco come re su torre).
  final Move move;

  /// Variante prevista, in notazione UCI, a partire da [move].
  final List<String> pv;

  /// Valutazione dal punto di vista di chi muove.
  final EngineScore? score;
  final int? depth;
}

/// Livello usato per valutare una posizione a piena forza.
const analysisLevel = EngineLevel(
  id: 0,
  name: 'Analisi',
  approxElo: 3000,
  skill: 20,
  movetime: Duration(milliseconds: 300),
);

/// Avversario basato su un motore UCI. Le richieste vengono eseguite in
/// coda, una ricerca alla volta; dopo un errore il motore viene riavviato.
class ComputerPlayer {
  ComputerPlayer({
    Future<UciTransport> Function()? connect,
    math.Random? random,
    this.timeoutMargin = const Duration(seconds: 15),
  }) : _connect = connect ?? StockfishTransport.start,
       _random = random ?? math.Random();

  final Future<UciTransport> Function() _connect;
  final math.Random _random;
  final Duration timeoutMargin;

  UciTransport? _transport;
  StreamSubscription<String>? _subscription;
  Future<void>? _ready;
  Future<void> _queue = Future.value();
  final _listeners = <void Function(String line)>{};
  final _pending = <Completer<String>>{};
  final _applied = <String, String>{};

  /// Incrementato da [stop]: le ricerche richieste prima terminano subito.
  int _stopEpoch = 0;
  bool _searching = false;
  bool _disposed = false;

  /// Avvia il motore; altrimenti avviene alla prima richiesta.
  Future<void> init() => _ready ??= _start();

  Future<void> _start() async {
    final transport = await _connect();
    if (_disposed) {
      await transport.dispose();
      throw StateError('Motore chiuso');
    }
    _transport = transport;
    _subscription = transport.lines.listen((line) {
      for (final l in [..._listeners]) {
        l(line);
      }
    });
    await _command('uci', (l) => l == 'uciok', const Duration(seconds: 30));
    await _sync();
  }

  /// Da chiamare a inizio partita: azzera la tabella hash.
  Future<void> newGame() => _enqueue(() async {
    _send('ucinewgame');
    await _sync();
  });

  /// Calcola la mossa del computer dopo [moves] a partire da [initialFen].
  /// Restituisce `null` se non esistono mosse legali.
  Future<EngineMove?> bestMove(
    String initialFen,
    List<Move> moves,
    EngineLevel level,
  ) {
    final epoch = _stopEpoch;
    return _enqueue(() => _search(initialFen, moves, level, epoch));
  }

  /// Valutazione a piena forza dal punto di vista di chi muove.
  Future<EngineScore?> evaluate(String initialFen, List<Move> moves) {
    final epoch = _stopEpoch;
    return _enqueue(
      () async =>
          (await _search(initialFen, moves, analysisLevel, epoch))?.score,
    );
  }

  /// Fa terminare subito la ricerca in corso e quelle già in coda.
  void stop() {
    _stopEpoch++;
    if (_searching && !_disposed) _send('stop');
  }

  Future<void> dispose() async {
    _disposed = true;
    _failPending(StateError('Motore chiuso'));
    await _shutdown();
  }

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final run = _queue.then((_) async {
      try {
        await init();
        return await task();
      } catch (_) {
        await _shutdown();
        rethrow;
      }
    });
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  /// Chiude il motore attuale; la richiesta successiva ne avvia uno nuovo.
  Future<void> _shutdown() async {
    final transport = _transport;
    _ready = null;
    _transport = null;
    _applied.clear();
    _listeners.clear();
    await _subscription?.cancel();
    _subscription = null;
    await transport?.dispose();
  }

  Future<EngineMove?> _search(
    String initialFen,
    List<Move> moves,
    EngineLevel level,
    int epoch,
  ) async {
    final started = DateTime.now();
    bool cancelled() => epoch != _stopEpoch;
    await _applyLevel(level);
    Position position = Chess.fromSetup(Setup.parseFen(initialFen));
    final history = <String>[];
    for (final move in moves) {
      history.add(_standardUci(position, move));
      position = position.play(move);
    }
    _send(
      'position fen ${initialFen.trim()}'
      '${history.isEmpty ? '' : ' moves ${history.join(' ')}'}',
    );

    final infos = <int, InfoLine>{};
    void onInfo(String line) {
      final info = parseInfo(line);
      if (info != null) infos[info.multipv] = info;
    }

    _listeners.add(onInfo);
    final String bestLine;
    try {
      final depth = level.depth != null ? ' depth ${level.depth}' : '';
      _searching = true;
      bestLine = await _command(
        cancelled()
            ? 'go depth 1'
            : 'go$depth movetime ${level.movetime.inMilliseconds}',
        (l) => l.startsWith('bestmove'),
        level.movetime + timeoutMargin,
      );
    } finally {
      _searching = false;
      _listeners.remove(onInfo);
    }

    final engineMove = parseBestMove(bestLine);
    if (engineMove == null) return null;
    final chosen =
        (level.multiPv > 1
            ? chooseCandidate(
                [
                  for (final i in infos.values)
                    if (i.multipv <= level.multiPv) i,
                ],
                level.temperatureCp,
                _random,
              )
            : null) ??
        infos.values.where((i) => i.pv.first == engineMove).firstOrNull ??
        InfoLine(multipv: 1, pv: [engineMove]);

    final wait = level.minReply - DateTime.now().difference(started);
    if (!cancelled() && wait > Duration.zero) {
      await Future<void>.delayed(wait);
    }

    return EngineMove(
      move: position.normalizeMove(NormalMove.fromUci(chosen.pv.first)),
      pv: chosen.pv,
      score: chosen.score,
      depth: chosen.depth,
    );
  }

  /// UCI standard: l'arrocco di dartchess (re su torre) diventa e1g1/e1c1.
  static String _standardUci(Position position, Move move) {
    final uci = move.uci;
    if (move is! NormalMove ||
        position.board.roleAt(move.from) != Role.king ||
        position.board.pieceAt(move.to)?.color != position.turn) {
      return uci;
    }
    final file = uci.codeUnitAt(2) > uci.codeUnitAt(0) ? 'g' : 'c';
    return '${uci.substring(0, 2)}$file${uci[3]}';
  }

  Future<void> _applyLevel(EngineLevel level) async {
    final wanted = {
      'Skill Level': '${level.skill}',
      'MultiPV': '${level.multiPv}',
      'UCI_LimitStrength': '${level.uciElo != null}',
      if (level.uciElo != null) 'UCI_Elo': '${level.uciElo}',
    };
    var changed = false;
    wanted.forEach((name, value) {
      if (_applied[name] == value) return;
      _send('setoption name $name value $value');
      _applied[name] = value;
      changed = true;
    });
    if (changed) await _sync();
  }

  Future<String> _sync() =>
      _command('isready', (l) => l == 'readyok', const Duration(seconds: 10));

  void _send(String command) {
    if (_disposed) throw StateError('Motore chiuso');
    _transport!.send(command);
  }

  void _failPending(Object error) {
    for (final c in [..._pending]) {
      if (!c.isCompleted) c.completeError(error);
    }
    _pending.clear();
  }

  /// Invia [command] e attende la prima riga che soddisfa [done].
  Future<String> _command(
    String command,
    bool Function(String line) done,
    Duration timeout,
  ) {
    final completer = Completer<String>();
    void listener(String line) {
      if (done(line) && !completer.isCompleted) completer.complete(line);
    }

    _listeners.add(listener);
    _pending.add(completer);
    try {
      _send(command);
    } catch (e) {
      completer.completeError(e);
    }
    return completer.future
        .timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'Il motore non ha risposto a "${command.split(' ').first}"',
            timeout,
          ),
        )
        .whenComplete(() {
          _listeners.remove(listener);
          _pending.remove(completer);
        });
  }
}
