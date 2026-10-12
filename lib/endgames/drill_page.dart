import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../engine/computer_player.dart';
import '../settings/board_marks.dart';
import '../settings/settings.dart';
import '../tablebase/perfect_endgame_card.dart';
import '../tablebase/tablebase_service.dart';
import 'drill.dart';
import 'endgame_controller.dart';

/// Una posizione dell'allenatore dei finali contro il motore a forza piena.
class DrillPage extends StatefulWidget {
  const DrillPage({
    super.key,
    required this.drill,
    required this.controller,
    required this.createComputer,
    this.simple = false,
    this.tablebase,
  });

  final EndgameDrill drill;
  final EndgameController controller;
  final ComputerPlayer Function() createComputer;

  /// Profilo bambino: niente conteggio delle mosse.
  final bool simple;

  /// Finali perfetti (RF-97): nelle posizioni con al massimo quattro pezzi
  /// mostra il risultato esatto e, a richiesta, la mossa perfetta.
  final TablebaseService? tablebase;

  @override
  State<DrillPage> createState() => _DrillPageState();
}

class _DrillPageState extends State<DrillPage> {
  late final ComputerPlayer _player = widget.createComputer();
  late DrillRun _run = DrillRun(widget.drill);
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );
  final Stopwatch _clock = Stopwatch();
  bool _started = false;
  bool _thinking = false;
  bool _engineFailed = false;

  /// Mossa perfetta mostrata sulla scacchiera, finché non si muove.
  Move? _hint;

  /// Cambia a ogni «Riprova»: una risposta della prova precedente si scarta.
  int _attempt = 0;

  @override
  void dispose() {
    // Lasciare una prova a metà conta come fallita, così torna da ripetere;
    // non se il motore si è fermato.
    if (_run.state == DrillState.playing && _run.moves > 0 && !_engineFailed) {
      _save(0).ignore();
    }
    _board.dispose();
    _player.dispose().ignore();
    super.dispose();
  }

  GameData _gameData({Move? lastMove}) {
    final pos = _run.position;
    final active = _started && !_thinking && _run.userToMove;
    return GameData(
      fen: pos.fen,
      lastMove: lastMove,
      playerSide: active
          ? (_run.side == Side.white ? PlayerSide.white : PlayerSide.black)
          : PlayerSide.none,
      sideToMove: pos.turn,
      kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
      validMoves: active ? makeLegalMoves(pos) : const {},
    );
  }

  void _start() {
    setState(() => _started = true);
    _clock.start();
    _board.updatePosition(_gameData(), animate: false);
  }

  Future<void> _onMove(Move move, {bool? viaDragAndDrop}) async {
    if (!_run.play(move)) return;
    setState(() {
      _hint = null;
      _thinking = _run.state == DrillState.playing;
    });
    _board.updatePosition(
      _gameData(lastMove: move),
      animate: viaDragAndDrop != true,
    );
    if (_run.state != DrillState.playing) return _finish();
    await _reply();
  }

  Future<void> _reply() async {
    final attempt = _attempt;
    EngineMove? reply;
    try {
      reply = await _player.bestMove(
        widget.drill.fen,
        _run.history,
        analysisLevel,
      );
    } on Object catch (e) {
      debugPrint('Motore non disponibile: $e');
    }
    if (!mounted || attempt != _attempt) return;
    if (reply == null || !_run.reply(reply.move)) {
      setState(() {
        _thinking = false;
        _engineFailed = true;
      });
      return;
    }
    setState(() => _thinking = false);
    _board.updatePosition(_gameData(lastMove: reply.move));
    if (_run.state != DrillState.playing) await _finish();
  }

  Future<void> _finish() async {
    _clock.stop();
    setState(() {});
    await _save(_run.stars);
  }

  Future<void> _save(int stars) async {
    try {
      await widget.controller.finish(widget.drill, stars, _clock.elapsed);
    } on Object catch (e) {
      debugPrint('Esito del finale non salvato: $e');
    }
  }

  void _retry() {
    _player.stop();
    setState(() {
      _attempt++;
      _run = DrillRun(widget.drill);
      _thinking = false;
      _engineFailed = false;
      _hint = null;
    });
    _clock
      ..reset()
      ..start();
    _board.updatePosition(_gameData(), animate: false);
  }

  Set<Shape> _hintShapes(BoardMarks marks) => switch (_hint) {
    NormalMove(:final from, :final to) => marks.arrow(marks.hint, from, to),
    _ => const {},
  };

  String get _counter => switch (widget.drill.goal) {
    DrillGoal.hold => 'Mosse: ${_run.moves} di ${widget.drill.par}',
    _ => 'Mosse: ${_run.moves} · tre stelle entro ${widget.drill.par}',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.drill.title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final size = math.max(
              0.0,
              landscape
                  ? constraints.maxHeight
                  : math.min(
                      constraints.maxWidth,
                      constraints.maxHeight - _portraitReserve,
                    ),
            );
            final board = Chessboard(
              size: size,
              controller: _board,
              orientation: _run.side,
              onMove: _onMove,
              shapes: _hintShapes(AppSettings.of(context).exerciseMarks),
              settings: ChessboardSettings(
                colorScheme: AppSettings.of(context).exerciseScheme,
                autoQueenPromotion: true,
              ),
            );
            final panel = SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.drill.intro, style: text.titleMedium),
                  const SizedBox(height: 16),
                  if (!_started)
                    FilledButton(onPressed: _start, child: const Text('Inizia'))
                  else ...[
                    if (!widget.simple)
                      Text(_counter, textAlign: TextAlign.center),
                    if (widget.tablebase != null &&
                        _run.userToMove &&
                        !_thinking)
                      PerfectEndgameCard(
                        service: widget.tablebase!,
                        position: _run.position,
                        notation: AppSettings.of(context).notation,
                        kid: widget.simple,
                        hideMove: true,
                        onBestMove: (move) => setState(() => _hint = move),
                      ),
                    if (_thinking)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Il motore pensa…',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_engineFailed)
                      const Text(
                        'Il motore non risponde: riprova.',
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 12),
                    if (_run.state != DrillState.playing || _engineFailed)
                      _Outcome(
                        state: _engineFailed ? DrillState.playing : _run.state,
                        stars: _run.stars,
                        onRetry: _retry,
                      ),
                  ],
                ],
              ),
            );
            if (landscape) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  board,
                  Expanded(child: panel),
                ],
              );
            }
            return Column(
              children: [
                Center(child: board),
                Expanded(child: panel),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Spazio minimo sotto la scacchiera in verticale per testo e comandi.
const double _portraitReserve = 240;

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.state,
    required this.stars,
    required this.onRetry,
  });

  final DrillState state;
  final int stars;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state == DrillState.success) ...[
          Text('Obiettivo raggiunto', style: text.titleLarge),
          Text(
            '${'★' * stars}${'☆' * (3 - stars)}',
            semanticsLabel: '$stars stelle su 3',
            style: TextStyle(
              fontSize: 32,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ] else if (state == DrillState.failure) ...[
          Text('Non ci sei riuscito', style: text.titleLarge),
          const Text(
            'La posizione resta tra quelle da ripetere.',
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(onPressed: onRetry, child: const Text('Riprova')),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fine'),
            ),
          ],
        ),
      ],
    );
  }
}
