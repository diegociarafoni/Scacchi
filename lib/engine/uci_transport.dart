import 'dart:io' show Platform;

import 'package:multistockfish/multistockfish.dart';

/// Canale di testo verso un motore UCI.
abstract interface class UciTransport {
  Stream<String> get lines;
  void send(String command);
  Future<void> dispose();
}

/// Stockfish 19 nativo (rete NNUE leggera inclusa), tramite il plugin di
/// Lichess. Gira sul dispositivo, senza rete.
class StockfishTransport implements UciTransport {
  StockfishTransport._(this._engine);

  final Stockfish _engine;

  /// Il plugin supporta per ora solo Android e iOS.
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  static Future<UciTransport> start() async =>
      StockfishTransport._(await Stockfish.create());

  @override
  Stream<String> get lines => _engine.stdout;

  @override
  void send(String command) => _engine.stdin = command;

  @override
  Future<void> dispose() => _engine.dispose();
}
