import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'chess_game.dart';

enum GameSound {
  move('move.wav'),
  capture('capture.wav'),
  castle('castle.wav'),
  check('check.wav'),
  promote('promote.wav'),
  gameEnd('game_end.wav'),
  lowTime('low_time.wav');

  const GameSound(this.file);

  final String file;
}

/// Suono dell'ultima mossa di [game], giocata a partire da [before].
GameSound? soundForLastMove(ChessGame game, Position before) {
  final last = game.moves.lastOrNull;
  if (last == null) return null;
  if (game.isOver) return GameSound.gameEnd;
  if (last.after.isCheck) return GameSound.check;
  final move = last.move;
  if (move is NormalMove) {
    if (move.promotion != null) return GameSound.promote;
    final moving = before.board.pieceAt(move.from);
    final target = before.board.pieceAt(move.to);
    if (moving?.role == Role.king &&
        (target?.color == moving?.color ||
            (move.from.file - move.to.file).abs() > 1)) {
      return GameSound.castle;
    }
    if (target != null ||
        (moving?.role == Role.pawn && move.from.file != move.to.file)) {
      return GameSound.capture;
    }
  }
  return GameSound.move;
}

/// Riproduce suoni e vibrazioni secondo le impostazioni.
class SoundPlayer {
  final Map<GameSound, AudioPlayer> _players = {};

  Future<void> play(
    GameSound sound, {
    required bool enabled,
    required double volume,
    required bool haptics,
  }) async {
    if (haptics) {
      unawaited(
        sound == GameSound.capture || sound == GameSound.gameEnd
            ? HapticFeedback.mediumImpact()
            : HapticFeedback.selectionClick(),
      );
    }
    if (!enabled || volume <= 0) return;
    try {
      final player = _players.putIfAbsent(sound, AudioPlayer.new);
      await player.stop();
      await player.play(
        AssetSource('sounds/${sound.file}'),
        volume: volume,
        mode: PlayerMode.lowLatency,
      );
    } on Object catch (e) {
      debugPrint('Suono non riprodotto: $e');
    }
  }

  void dispose() {
    for (final p in _players.values) {
      unawaited(p.dispose());
    }
    _players.clear();
  }
}
