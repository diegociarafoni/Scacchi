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

/// Avversario basato su un motore UCI. Le richieste vengono eseguite in
/// coda, una ricerca alla volta.
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
  final _applied = <String, String>{};
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

  /// Calcola la mossa del computer nella posizione [fen] al livello [level].
  /// Restituisce `null` se non esistono mosse legali.
  Future<EngineMove?> bestMove(String fen, EngineLevel level) =>
      _enqueue(() => _search(fen, level));

  /// Chiede al motore di rispondere subito con la mossa trovata finora.
  void stop() {
    if (_transport != null && !_disposed) _send('stop');
  }

  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    await _transport?.dispose();
  }

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final run = _queue.then((_) async {
      await init();
      return task();
    });
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<EngineMove?> _search(String fen, EngineLevel level) async {
    final started = DateTime.now();
    await _applyLevel(level);
    _send('position fen ${fen.trim()}');

    final infos = <int, InfoLine>{};
    void onInfo(String line) {
      final info = parseInfo(line);
      if (info != null) infos[info.multipv] = info;
    }

    _listeners.add(onInfo);
    final String bestLine;
    try {
      final depth = level.depth != null ? ' depth ${level.depth}' : '';
      bestLine = await _command(
        'go$depth movetime ${level.movetime.inMilliseconds}',
        (l) => l.startsWith('bestmove'),
        level.movetime + timeoutMargin,
      );
    } finally {
      _listeners.remove(onInfo);
    }

    final engineMove = parseBestMove(bestLine);
    if (engineMove == null) return null;
    final candidates = [
      for (final i in infos.values)
        if (i.multipv <= level.multiPv) i,
    ];
    final chosen =
        (level.multiPv > 1
            ? chooseCandidate(candidates, level.temperatureCp, _random)
            : null) ??
        candidates.where((i) => i.pv.first == engineMove).firstOrNull ??
        InfoLine(multipv: 1, pv: [engineMove]);

    final wait = level.minReply - DateTime.now().difference(started);
    if (wait > Duration.zero) await Future<void>.delayed(wait);

    return EngineMove(
      move: Chess.fromSetup(Setup.parseFen(fen))
          .normalizeMove(NormalMove.fromUci(chosen.pv.first)),
      pv: chosen.pv,
      score: chosen.score,
      depth: chosen.depth,
    );
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
    _send(command);
    return completer.future
        .timeout(
          timeout,
          onTimeout: () => throw TimeoutException(
            'Il motore non ha risposto a "${command.split(' ').first}"',
            timeout,
          ),
        )
        .whenComplete(() => _listeners.remove(listener));
  }
}
